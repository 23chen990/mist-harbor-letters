extends RefCounted
class_name R162ArticleBuilder

const ConditionEvaluatorScript = preload("res://scripts/r16_2_condition_evaluator.gd")

var runtime_data: Dictionary = {}
var state_store = null
var evaluator = ConditionEvaluatorScript.new()


func configure(data: Dictionary, store: RefCounted) -> void:
	runtime_data = data
	state_store = store
	evaluator.configure(data.get("states", {}))


func build_preview() -> Dictionary:
	if state_store == null:
		return {"error": "state store not configured"}
	var values: Dictionary = state_store.values_for_conditions()
	var draft_main := str(values.get("draft_main", ""))
	var version := _version_for_draft(draft_main)
	var included: Array[String] = []
	var excluded: Array[String] = []
	var applied_rules: Array[String] = []
	for rule_id: Variant in runtime_data.get("article_rules", {}).keys():
		var rule: Dictionary = runtime_data["article_rules"][rule_id]
		var condition := str(rule.get("condition", ""))
		if condition.is_empty() or evaluator.evaluate(condition, values):
			applied_rules.append(str(rule_id))
			var include_text := str(rule.get("auto_include", ""))
			var exclude_text := str(rule.get("auto_exclude", ""))
			if not include_text.is_empty():
				included.append(include_text)
			if not exclude_text.is_empty():
				excluded.append(exclude_text)
	# Safety barrier: a promise/permission is never bypassed merely because a
	# player selected the FULL_NAMES preset.
	if bool(values.get("promise_yutang_offrecord", false)):
		excluded.append("玉棠 off-record 内容")
	if bool(values.get("promise_liang_anonymous", false)):
		excluded.append("老梁实名")
	if bool(values.get("offrecord_kept", false)):
		excluded.append("未授权私密动机")
	var render_fields := {}
	for row: Variant in runtime_data.get("newspaper_spec", []):
		var field_name := str(row.get("field", ""))
		if field_name.is_empty():
			continue
		render_fields[field_name] = {
			"source": str(row.get("source", "")),
			"required": str(row.get("required", "")),
			"player_edits": str(row.get("player_edits", "")),
			"example": str(row.get("example", "")),
			"fallback": str(row.get("fallback", "")),
		}
	return {
		"lifecycle": "preview",
		"draft_main": draft_main,
		"version_id": version.get("version_id", ""),
		"headline": version.get("headline_frame", render_fields.get("主标题", {}).get("example", "")),
		"included": _deduplicate(included),
		"excluded": _deduplicate(excluded),
		"rules_applied": applied_rules,
		"render_fields": render_fields,
	}


func _version_for_draft(draft_main: String) -> Dictionary:
	var wanted: String = str({
		"FULL_NAMES": "A_FINAL_FULL",
		"FACTS_PRIVACY": "A_FINAL_PRIV",
		"CORRECTION_ONLY": "A_FINAL_CORR",
	}.get(draft_main, ""))
	if wanted.is_empty():
		return {}
	var versions: Dictionary = runtime_data.get("article_versions", {})
	return versions.get(wanted, {})


func _deduplicate(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value: String in values:
		if not result.has(value):
			result.append(value)
	return result
