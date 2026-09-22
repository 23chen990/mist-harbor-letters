extends RefCounted
class_name R162StateStore

const ConditionEvaluatorScript = preload("res://scripts/r16_2_condition_evaluator.gd")

var schema: Dictionary = {}
var story: Dictionary = {}
var global_state: Dictionary = {}
var mutation_errors: Array[String] = []
var applied_rulesets: Array[String] = []
var evaluator = ConditionEvaluatorScript.new()


func configure(state_schema: Dictionary) -> void:
	schema = state_schema.duplicate(true)
	story.clear()
	global_state.clear()
	mutation_errors.clear()
	applied_rulesets.clear()
	evaluator.configure(schema)
	for key: Variant in schema.keys():
		var definition: Dictionary = schema[key]
		var value: Variant = _default_value(definition)
		if str(definition.get("rollback_scope", "story")) == "global":
			global_state[key] = value
		else:
			story[key] = value


func get_value(key: String, fallback: Variant = null) -> Variant:
	if story.has(key):
		return story[key]
	if global_state.has(key):
		return global_state[key]
	return fallback


func has_key(key: String) -> bool:
	return schema.has(key)


func values_for_conditions(extra: Dictionary = {}) -> Dictionary:
	var result := global_state.duplicate(true)
	for key: Variant in story.keys():
		result[key] = story[key]
	for key: Variant in extra.keys():
		result[key] = extra[key]
	return result


func condition_met(expression: String, extra: Dictionary = {}) -> bool:
	evaluator.errors.clear()
	var result := evaluator.evaluate(expression, values_for_conditions(), extra)
	for error: String in evaluator.errors:
		if not mutation_errors.has(error):
			mutation_errors.append(error)
	return result


func set_value(key: String, value: Variant) -> bool:
	if not schema.has(key):
		mutation_errors.append("unknown state key: " + key)
		return false
	var definition: Dictionary = schema[key]
	var converted: Variant = _coerce_for_definition(definition, value)
	if converted == null and str(definition.get("type", "")) != "string":
		mutation_errors.append("invalid value for %s: %s" % [key, str(value)])
		return false
	if str(definition.get("rollback_scope", "story")) == "global":
		global_state[key] = converted
	else:
		story[key] = converted
	return true


func add_value(key: String, value: Variant) -> bool:
	if not schema.has(key):
		mutation_errors.append("unknown state key: " + key)
		return false
	var definition: Dictionary = schema[key]
	var type := str(definition.get("type", ""))
	var current: Variant = get_value(key)
	if type == "set":
		var values: Array = current as Array if current is Array else []
		var item := str(value)
		if not values.has(item):
			values.append(item)
		return set_value(key, values)
	if type == "int" or type == "float":
		return set_value(key, float(current) + float(value) if type == "float" else int(current) + int(value))
	mutation_errors.append("+= is not supported for state type %s (%s)" % [type, key])
	return false


func subtract_value(key: String, value: Variant) -> bool:
	if not schema.has(key):
		mutation_errors.append("unknown state key: " + key)
		return false
	var definition: Dictionary = schema[key]
	var type := str(definition.get("type", ""))
	var current: Variant = get_value(key)
	if type == "int" or type == "float":
		return set_value(key, float(current) - float(value) if type == "float" else int(current) - int(value))
	mutation_errors.append("-= is not supported for state type %s (%s)" % [type, key])
	return false


func apply_mutations(expression: String) -> bool:
	var before := create_snapshot()
	mutation_errors.clear()
	var conditional_chain_taken := false
	for operation: String in _split_operations(expression):
		if operation.is_empty():
			continue
		if operation.begins_with("apply "):
			var ruleset := operation.trim_prefix("apply ").strip_edges()
			if ruleset != "AutoArticleRules":
				mutation_errors.append("unknown ruleset: " + ruleset)
				break
			applied_rulesets.append(ruleset)
			continue
		var mutation := _conditional_mutation(operation, conditional_chain_taken)
		if mutation.is_empty():
			mutation_errors.append("unknown mutation syntax: " + operation)
			break
		conditional_chain_taken = bool(mutation.get("chain_taken", false)) if bool(mutation.get("is_conditional", false)) else false
		if not bool(mutation.get("enabled", true)):
			continue
		if not _apply_single_mutation(str(mutation.get("body", ""))):
			break
	if not mutation_errors.is_empty():
		restore_snapshot(before)
		return false
	return true


func create_snapshot(snapshot_id := "") -> Dictionary:
	return {
		"snapshot_id": snapshot_id,
		"story": story.duplicate(true),
		"global_state": global_state.duplicate(true),
		"applied_rulesets": applied_rulesets.duplicate(true),
	}


func restore_snapshot(snapshot: Dictionary, preserve_global := true) -> void:
	story = (snapshot.get("story", {}) as Dictionary).duplicate(true)
	if not preserve_global:
		global_state = (snapshot.get("global_state", {}) as Dictionary).duplicate(true)
	applied_rulesets = (snapshot.get("applied_rulesets", []) as Array).duplicate(true)


func global_add(key: String, value: String) -> bool:
	return add_value(key, value)


func _apply_single_mutation(operation: String) -> bool:
	var clean := operation.strip_edges()
	var add_position := clean.find("+=")
	if add_position >= 0:
		return add_value(clean.substr(0, add_position).strip_edges(), _parse_value(clean.substr(add_position + 2).strip_edges()))
	var subtract_position := clean.find("-=")
	if subtract_position >= 0:
		return subtract_value(clean.substr(0, subtract_position).strip_edges(), _parse_value(clean.substr(subtract_position + 2).strip_edges()))
	var equals_position := clean.find("=")
	if equals_position < 0:
		mutation_errors.append("mutation has no assignment: " + clean)
		return false
	var key := clean.substr(0, equals_position).strip_edges()
	return set_value(key, _parse_value(clean.substr(equals_position + 1).strip_edges()))


func _conditional_mutation(operation: String, chain_taken: bool) -> Dictionary:
	var clean := operation.strip_edges()
	var arrow := clean.find("=>")
	if arrow < 0:
		return {"enabled": true, "body": clean}
	var prefix := clean.substr(0, arrow).strip_edges()
	var body := clean.substr(arrow + 2).strip_edges()
	if prefix == "else":
		return {"enabled": not chain_taken, "body": body, "is_conditional": true, "chain_taken": not chain_taken}
	if prefix.begins_with("if "):
		var enabled := condition_met(prefix.trim_prefix("if ").strip_edges())
		return {"enabled": enabled and not chain_taken, "body": body, "is_conditional": true, "chain_taken": chain_taken or enabled}
	if prefix.begins_with("else if "):
		var enabled_else_if := condition_met(prefix.trim_prefix("else if ").strip_edges())
		return {"enabled": enabled_else_if and not chain_taken, "body": body, "is_conditional": true, "chain_taken": chain_taken or enabled_else_if}
	return {}


func _default_value(definition: Dictionary) -> Variant:
	var type := str(definition.get("type", "string"))
	var raw: Variant = definition.get("default", "")
	match type:
		"bool": return str(raw) in ["1", "true", "True"]
		"int": return int(raw) if str(raw).is_valid_int() else 0
		"float": return float(raw) if str(raw).is_valid_float() else 0.0
		"set": return []
		_: return str(raw) if raw != null else ""


func _coerce_for_definition(definition: Dictionary, value: Variant) -> Variant:
	var type := str(definition.get("type", "string"))
	match type:
		"bool":
			if value is bool:
				return value
			if str(value) in ["1", "true", "True"]:
				return true
			if str(value) in ["0", "false", "False"]:
				return false
			return null
		"int":
			return int(value) if str(value).is_valid_int() or value is int else null
		"float":
			return float(value) if str(value).is_valid_float() or value is float or value is int else null
		"set":
			if value is Array:
				return value.duplicate(true)
			return [str(value)]
		"enum":
			var allowed: Array[String] = []
			for item: String in str(definition.get("meaning", "")).split("|", false):
				allowed.append(item.strip_edges())
			var clean := str(value)
			return clean if allowed.is_empty() or allowed.has(clean) else null
		_: return str(value)


func _parse_value(text: String) -> Variant:
	var clean := text.strip_edges()
	if clean == "true":
		return true
	if clean == "false":
		return false
	if clean.is_valid_int():
		return int(clean)
	if clean.is_valid_float():
		return float(clean)
	return clean.trim_prefix("\"").trim_suffix("\"").trim_prefix("“").trim_suffix("”")


func _split_operations(text: String) -> Array[String]:
	var result: Array[String] = []
	var start := 0
	var depth := 0
	for index: int in text.length():
		var character := text.substr(index, 1)
		if character == "(" or character == "{":
			depth += 1
		elif character == ")" or character == "}":
			depth -= 1
		elif character == ";" and depth == 0:
			result.append(text.substr(start, index - start).strip_edges())
			start = index + 1
	result.append(text.substr(start).strip_edges())
	return result
