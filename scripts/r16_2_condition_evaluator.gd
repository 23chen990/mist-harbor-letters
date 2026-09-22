extends RefCounted
class_name R162ConditionEvaluator

## Whitelisted evaluator for the engine-neutral R16.2 ConditionDSL.
## It deliberately does not execute script text or call eval-like APIs.

var schema: Dictionary = {}
var errors: Array[String] = []


func configure(state_schema: Dictionary) -> void:
	schema = state_schema.duplicate(true)
	errors.clear()


func evaluate(expression: String, values: Dictionary, extra_values: Dictionary = {}) -> bool:
	var clean := expression.strip_edges()
	if clean.is_empty() or clean == "ELSE":
		return true
	# The R16.2 DOCX uses Chinese conjunctions in conditional dialogue
	# prefixes (for example "A=1 且 B=1"), while the workbook DSL documents
	# their English equivalents. Normalize both authoring spellings before the
	# recursive parser handles precedence.
	clean = clean.replace("且", " AND ").replace("或", " OR ")
	var context := values.duplicate(true)
	for key: Variant in extra_values.keys():
		context[key] = extra_values[key]
	return _evaluate_or(clean, context)


func _evaluate_or(expression: String, context: Dictionary) -> bool:
	var clean := _trim_outer_parentheses(expression.strip_edges())
	var alternatives := _split_top_level(clean, "OR")
	if alternatives.size() > 1:
		for alternative: String in alternatives:
			if _evaluate_or(alternative, context):
				return true
		return false
	var requirements := _split_top_level(clean, "AND")
	if requirements.size() > 1:
		for requirement: String in requirements:
			if not _evaluate_or(requirement, context):
				return false
		return true
	return _evaluate_clause(clean, context)


func _evaluate_clause(clause: String, context: Dictionary) -> bool:
	var clean := _trim_outer_parentheses(clause.strip_edges())
	if clean.is_empty() or clean == "ELSE":
		return true
	if clean.to_lower() == "false":
		return false
	var set_position := clean.find(" SET")
	if set_position > 0 and clean.substr(set_position).strip_edges() == "SET":
		var set_key := clean.substr(0, set_position).strip_edges()
		if not _known_key(set_key, context):
			return false
		return context.has(set_key) and context[set_key] != null and not (context[set_key] is String and str(context[set_key]).is_empty())
	var in_position := clean.find(" IN ")
	if in_position > 0:
		var in_key := clean.substr(0, in_position).strip_edges()
		var values_text := clean.substr(in_position + 4).strip_edges()
		if not _known_key(in_key, context):
			return false
		var open := values_text.find("{")
		var close := values_text.rfind("}")
		if open < 0 or close <= open:
			errors.append("malformed IN expression: " + clean)
			return false
		var actual := str(context.get(in_key, ""))
		for item: String in values_text.substr(open + 1, close - open - 1).split(",", false):
			if actual == item.strip_edges():
				return true
		return false
	for operator: String in ["!=", ">=", "<=", "=", ">", "<"]:
		var position := _find_operator(clean, operator)
		if position < 0:
			continue
		var key := clean.substr(0, position).strip_edges()
		var expected_text := clean.substr(position + operator.length()).strip_edges()
		if not _known_key(key, context):
			return false
		return _compare(context.get(key), operator, expected_text)
	errors.append("unknown condition syntax: " + clean)
	return false


func _known_key(key: String, context: Dictionary) -> bool:
	if schema.has(key) or context.has(key) or key == "EndingID":
		return true
	errors.append("unknown state key: " + key)
	return false


func _compare(actual: Variant, operator: String, expected_text: String) -> bool:
	var expected: Variant = _parse_value(expected_text)
	if actual is bool and (expected_text.strip_edges() == "0" or expected_text.strip_edges() == "1"):
		expected = expected_text.strip_edges() == "1"
	if actual is Array:
		if operator == "=" or operator == "!=":
			var contains := (actual as Array).has(expected)
			return contains if operator == "=" else not contains
		return false
	if actual is bool or expected is bool:
		var left_bool := _as_bool(actual)
		var right_bool := _as_bool(expected)
		return _compare_order(left_bool, operator, right_bool)
	if (actual is int or actual is float) and (expected is int or expected is float):
		return _compare_order(float(actual), operator, float(expected))
	return _compare_order(str(actual), operator, str(expected))


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	if value is int or value is float:
		return value != 0
	var clean := str(value).strip_edges().to_lower()
	return clean in ["1", "true", "yes"]


func _compare_order(actual: Variant, operator: String, expected: Variant) -> bool:
	match operator:
		"=": return actual == expected
		"!=": return actual != expected
		">": return actual > expected
		"<": return actual < expected
		">=": return actual >= expected
		"<=": return actual <= expected
	return false


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


func _find_operator(expression: String, operator: String) -> int:
	var depth := 0
	for index: int in expression.length():
		var character := expression.substr(index, 1)
		if character == "(" or character == "{":
			depth += 1
		elif character == ")" or character == "}":
			depth -= 1
		elif depth == 0 and expression.substr(index, operator.length()) == operator:
			return index
	return -1


func _split_top_level(expression: String, separator: String) -> Array[String]:
	var result: Array[String] = []
	var depth := 0
	var start := 0
	var index := 0
	var token := " " + separator + " "
	while index < expression.length():
		var character := expression.substr(index, 1)
		if character == "(" or character == "{":
			depth += 1
		elif character == ")" or character == "}":
			depth -= 1
		elif depth == 0 and expression.substr(index, token.length()).to_upper() == token:
			result.append(expression.substr(start, index - start).strip_edges())
			index += token.length()
			start = index
			continue
		index += 1
	result.append(expression.substr(start).strip_edges())
	return result


func _trim_outer_parentheses(expression: String) -> String:
	var result := expression.strip_edges()
	while result.begins_with("(") and result.ends_with(")"):
		var depth := 0
		var wraps_all := true
		for index: int in result.length():
			var character := result.substr(index, 1)
			if character == "(":
				depth += 1
			elif character == ")":
				depth -= 1
				if depth == 0 and index < result.length() - 1:
					wraps_all = false
					break
		if not wraps_all:
			break
		result = result.substr(1, result.length() - 2).strip_edges()
	return result
