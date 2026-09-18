extends RefCounted
class_name FogHarborGameState

const KNOWLEDGE_CATALOG: Array[String] = [
	"沈砚舟是记者",
	"赵敬文是本埠知名记者",
	"赵敬文死在春和后巷石埠附近，警方认定为失足落水身亡",
	"赵敬文工作桌尚未清完。",
	"赵敬文死前重新翻过自己二十年前写的白素秋坠台报道",
	"为何重看、是否查到什么均未知。",
	"报馆采访函留底旁未见林怀安回函。",
	"赵敬文死前重新审视自己二十年前的报道，并准备再次询问林怀安",
	"没有证据证明他已查到新事实。",
	"林怀安声称寄出了回信，但不知道是否送达。",
	"赵敬文所说的‘不对’与二十年前旧事有关。",
	"林怀安主动确认‘那晚’指白素秋出事当晚。",
	"林怀安声称信件之后没有再见赵敬文。",
	"玉棠对父亲的药物与服用习惯非常熟悉。",
	"谢幕时林怀安仍活着",
	"这一刻方仲山在前场。",
	"陈九生明显开始怀疑现场存在其他原因",
]

const STATE_LABELS: Dictionary = {
	"letter_preparation": "信件准备",
	"entry_method": "入场方式",
	"chen_escort": "陈九生带路",
	"claims.to_chen.identity": "对陈九生透露的身份",
	"claims.to_chen.purpose": "对陈九生透露的来意",
	"claims.to_lin.materials_scope": "向林怀安透露的材料范围",
	"lin_questions_asked": "已向林怀安追问数量",
	"early_observation": "死亡现场第一眼",
	"chen_suspicion.external_actor": "陈九生对外部介入的怀疑",
	"chen_suspicion.shen": "陈九生对沈砚舟的怀疑",
	"claims.to_yutang": "对林玉棠的说法",
}

# 这是案件客观事实，只供剧情校验使用。它不会自动写入沈砚舟的知识。
const WORLD_TRUTHS: Dictionary = {
	"林怀安收到过赵敬文的信": true,
	"林怀安谢幕时仍然活着": true,
	"方仲山谢幕时位于前场": true,
	"林怀安散场后死亡": true,
}

var world_truths: Dictionary = WORLD_TRUTHS.duplicate(true)
var player_knowledge: Dictionary = {}
var deductions: Dictionary = {}
var choice_history: Array[Dictionary] = []
var visited_characters: Dictionary = {}
var narrative_values: Dictionary = {}
var narrative_records: Dictionary = {}
var narrative_counters: Dictionary = {}
var technical_values: Dictionary = {}
var technical_collections: Dictionary = {}
var last_spoken_line := ""

var current_scene := "《雾港日报》编辑部·上午"
var current_character := ""
var current_topic := "退稿、派活、同馆前辈之死"
var current_stage := "前序·退稿与派活"
var first_interview_target := ""
var current_theory := ""
var confrontation_style := ""
var disclosure_level := ""
var yutang_pressure_level := 0
var used_bluff_on_chen := false
var demo_finished := false
var completion_kind := ""
var completion_name := ""


func knows(fact: String) -> bool:
	return bool(player_knowledge.get(fact.strip_edges(), false))


func learn(fact: String) -> void:
	var clean := fact.strip_edges()
	if not clean.is_empty():
		player_knowledge[clean] = true


func learn_many(facts: String) -> void:
	for fact: String in facts.split("；", false):
		learn(fact)


func has_deduction(deduction: String) -> bool:
	return bool(deductions.get(deduction.strip_edges(), false))


func has_record(record_name: String) -> bool:
	return bool(narrative_records.get(record_name.strip_edges(), false))


func completion_label() -> String:
	return completion_name


func condition_met(condition: String) -> bool:
	var clean := condition.strip_edges()
	if clean.is_empty() or clean == "始终":
		return true
	return _expression_met(clean.replace(" 且 ", " and "))


func _expression_met(expression: String) -> bool:
	var clean := _trim_outer_parentheses(expression.strip_edges())
	var alternatives := _split_top_level(clean, " or ")
	if alternatives.size() > 1:
		for alternative: String in alternatives:
			if _expression_met(alternative):
				return true
		return false
	var requirements := _split_top_level(clean, " and ")
	if requirements.size() > 1:
		for requirement: String in requirements:
			if not _expression_met(requirement):
				return false
		return true
	return _clause_met(clean)


func _clause_met(clause: String) -> bool:
	clause = _trim_outer_parentheses(clause.strip_edges())
	if clause.is_empty() or clause == "始终":
		return true
	if clause == "false":
		return false
	if clause.begins_with("已知"):
		return knows(_quoted_text(clause))
	if clause.begins_with("未知"):
		return not knows(_quoted_text(clause))
	if clause.begins_with("已查看"):
		return has_record("已查看" + _quoted_text(clause))
	if clause.begins_with("尚未查看"):
		return not has_record("已查看" + _quoted_text(clause))
	if clause == "已经形成当前判断":
		return not current_theory.is_empty()
	if clause.begins_with("当前判断是"):
		return current_theory == _quoted_text(clause)
	if clause.begins_with("先谈对象是"):
		return first_interview_target == _quoted_text(clause)
	if clause.begins_with("已判断"):
		return has_deduction(_quoted_text(clause))
	if clause == "已经和林玉棠谈过":
		return visited_characters.has("林玉棠")
	if clause == "尚未和林玉棠谈过":
		return not visited_characters.has("林玉棠")
	if clause.begins_with("未记录") and clause.contains("为"):
		var missing_key := clause.substr(3, clause.find("为") - 3).strip_edges()
		return str(narrative_values.get(missing_key, "")) != _quoted_text(clause)
	if clause.ends_with(" is unset"):
		var unset_key := clause.trim_suffix(" is unset").strip_edges()
		return not technical_values.has(unset_key) or str(technical_values.get(unset_key, "")) == "unset"
	var includes_position := clause.find(" includes ")
	if includes_position > 0:
		var collection_key := clause.substr(0, includes_position).strip_edges()
		var expected_item := clause.substr(includes_position + " includes ".length()).strip_edges()
		return Array(technical_collections.get(collection_key, [])).has(expected_item)
	if clause.begins_with("记录") and clause.contains("为"):
		var key := clause.substr(2, clause.find("为") - 2).strip_edges()
		return str(narrative_values.get(key, "")) == _quoted_text(clause)
	for operator: String in ["!=", ">=", "<=", "=", ">", "<"]:
		var position := clause.find(operator)
		if position > 0:
			var key := clause.substr(0, position).strip_edges()
			var expected := clause.substr(position + operator.length()).strip_edges()
			return _compare_technical(key, operator, expected)
	push_warning("剧情表中有无法识别的出现条件：%s" % clause)
	return false


func _compare_technical(key: String, operator: String, expected_text: String) -> bool:
	var actual: Variant = technical_values.get(key, "")
	if expected_text.is_valid_float():
		var actual_number := float(actual) if str(actual).is_valid_float() else 0.0
		var expected_number := float(expected_text)
		match operator:
			"=": return actual_number == expected_number
			"!=": return actual_number != expected_number
			">=": return actual_number >= expected_number
			"<=": return actual_number <= expected_number
			">": return actual_number > expected_number
			"<": return actual_number < expected_number
	var expected: Variant = _technical_value(expected_text)
	if operator == "=":
		if expected is bool:
			return actual is bool and bool(actual) == bool(expected)
		return str(actual) == str(expected)
	if operator == "!=":
		if expected is bool:
			return not (actual is bool and bool(actual) == bool(expected))
		return str(actual) != str(expected)
	return false


func _split_top_level(expression: String, separator: String) -> Array[String]:
	var result: Array[String] = []
	var depth := 0
	var start := 0
	var index := 0
	while index < expression.length():
		var character := expression.substr(index, 1)
		if character == "(":
			depth += 1
		elif character == ")":
			depth -= 1
		elif depth == 0 and expression.substr(index, separator.length()) == separator:
			result.append(expression.substr(start, index - start).strip_edges())
			index += separator.length()
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
		for index in result.length():
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


func apply_result(result_text: String) -> void:
	for raw_action: String in result_text.replace("；", ";").split(";", false):
		var action := raw_action.strip_edges()
		if action.is_empty():
			continue
		if action.begins_with("记录“"):
			narrative_records[_quoted_text(action)] = true
		elif action.begins_with("记录") and action.contains("为"):
			var key := action.substr(2, action.find("为") - 2).strip_edges()
			var value := _quoted_text(action)
			narrative_values[key] = value
			_sync_legacy_value(key, value)
		elif action.begins_with("记住"):
			learn(_quoted_text(action))
		elif action.begins_with("形成判断"):
			deductions[_quoted_text(action)] = true
		elif action == "提高林玉棠压力":
			yutang_pressure_level += 1
		elif action.begins_with("提高"):
			narrative_counters[action] = int(narrative_counters.get(action, 0)) + 1
		elif action == "使用诈话":
			used_bluff_on_chen = true
		elif action == "完成演示":
			demo_finished = true
			completion_kind = "演示"
			completion_name = "演示完成"
		elif action.begins_with("完成结局"):
			demo_finished = true
			completion_kind = "结局"
			completion_name = _quoted_text(action)
		elif action.begins_with("完成Demo主线走向"):
			demo_finished = true
			completion_kind = "主线走向"
			completion_name = _quoted_text(action)
		elif action.contains("+="):
			_apply_technical_add(action)
		elif action.contains("-="):
			_apply_technical_subtract(action)
		elif action.contains("="):
			_apply_technical_assignment(action)
		else:
			push_warning("剧情表中有无法识别的选择结果：%s" % action)


func _sync_legacy_value(key: String, value: String) -> void:
	match key:
		"先谈对象": first_interview_target = value
		"当前判断": current_theory = value
		"拆穿方式": confrontation_style = value
		"透露程度": disclosure_level = value


func _apply_technical_assignment(action: String) -> void:
	var position := action.find("=")
	var key := action.substr(0, position).strip_edges()
	var value: Variant = _technical_value(action.substr(position + 1).strip_edges())
	technical_values[key] = value


func _apply_technical_add(action: String) -> void:
	var position := action.find("+=")
	var key := action.substr(0, position).strip_edges()
	var value_text := action.substr(position + 2).strip_edges()
	if value_text.is_valid_float():
		technical_values[key] = float(technical_values.get(key, 0.0)) + float(value_text)
		return
	var values: Array = technical_collections.get(key, [])
	if not values.has(value_text):
		values.append(value_text)
	technical_collections[key] = values


func _apply_technical_subtract(action: String) -> void:
	var position := action.find("-=")
	var key := action.substr(0, position).strip_edges()
	var value_text := action.substr(position + 2).strip_edges()
	if not value_text.is_valid_float():
		push_warning("剧情表中减值必须是数字：%s" % action)
		return
	technical_values[key] = float(technical_values.get(key, 0.0)) - float(value_text)


func _technical_value(value_text: String) -> Variant:
	if value_text == "true":
		return true
	if value_text == "false":
		return false
	if value_text.is_valid_int():
		return int(value_text)
	if value_text.is_valid_float():
		return float(value_text)
	return value_text


func record_choice(player_line: String, content_type: String, row_id: String, spoken := true) -> void:
	last_spoken_line = player_line if spoken else ""
	choice_history.append({
		"玩家台词": player_line,
		"内容类型": content_type,
		"自动ID": row_id,
		"剧情阶段": current_stage,
		"当前人物": current_character,
		"话题": current_topic,
	})


func set_current_context(scene: String, character: String, topic: String, stage: String) -> void:
	current_scene = scene
	current_character = character
	current_topic = topic
	current_stage = stage
	if character in ["林玉棠", "陈九生"]:
		visited_characters[character] = true


func knowledge_lines() -> Array[String]:
	var result: Array[String] = []
	for fact: String in KNOWLEDGE_CATALOG:
		result.append(("已知：" if knows(fact) else "未知：") + fact)
	for fact: Variant in player_knowledge.keys():
		if not KNOWLEDGE_CATALOG.has(str(fact)):
			result.append("已知：" + str(fact))
	return result


func story_state_lines() -> Array[String]:
	var result: Array[String] = []
	var keys: Array = narrative_values.keys()
	keys.sort()
	for key: Variant in keys:
		result.append("%s：%s" % [str(key), str(narrative_values[key])])
	var records: Array = narrative_records.keys()
	records.sort()
	for record: Variant in records:
		result.append("已记录：%s" % str(record))
	var counters: Array = narrative_counters.keys()
	counters.sort()
	for counter: Variant in counters:
		result.append("%s（%d）" % [str(counter), int(narrative_counters[counter])])
	var technical_keys: Array = technical_values.keys()
	technical_keys.sort()
	for key: Variant in technical_keys:
		if STATE_LABELS.has(str(key)):
			result.append("%s：%s" % [STATE_LABELS[str(key)], _humanize_value(str(technical_values[key]))])
	return result


func _humanize_value(value: String) -> String:
	var labels := {
		"copied": "已誊抄，原件留家",
		"original_carried": "采访函原件随身",
		"left_home": "原件留在报馆，无纸面材料",
		"force": "强闯",
		"leave": "改日再来",
		"name": "报姓名",
		"letter": "递信",
		"accepted": "接受",
		"refused": "拒绝",
		"activated": "已经产生",
		"active": "持续关注",
		"lin_medicine": "看林怀安与药片",
		"yutang": "看林玉棠",
		"chen": "留意陈九生",
	}
	return str(labels.get(value, value))


func history_lines(limit := 10) -> Array[String]:
	var result: Array[String] = []
	var start := maxi(0, choice_history.size() - limit)
	for index in range(start, choice_history.size()):
		var entry: Dictionary = choice_history[index]
		result.append("• %s" % entry.get("玩家台词", ""))
	return result


func create_snapshot() -> Dictionary:
	return {
		"world_truths": world_truths.duplicate(true),
		"player_knowledge": player_knowledge.duplicate(true),
		"deductions": deductions.duplicate(true),
		"choice_history": choice_history.duplicate(true),
		"visited_characters": visited_characters.duplicate(true),
		"narrative_values": narrative_values.duplicate(true),
		"narrative_records": narrative_records.duplicate(true),
		"narrative_counters": narrative_counters.duplicate(true),
		"technical_values": technical_values.duplicate(true),
		"technical_collections": technical_collections.duplicate(true),
		"last_spoken_line": last_spoken_line,
		"current_scene": current_scene,
		"current_character": current_character,
		"current_topic": current_topic,
		"current_stage": current_stage,
		"first_interview_target": first_interview_target,
		"current_theory": current_theory,
		"confrontation_style": confrontation_style,
		"disclosure_level": disclosure_level,
		"yutang_pressure_level": yutang_pressure_level,
		"used_bluff_on_chen": used_bluff_on_chen,
		"demo_finished": demo_finished,
		"completion_kind": completion_kind,
		"completion_name": completion_name,
	}


func restore_snapshot(snapshot: Dictionary) -> void:
	world_truths = (snapshot.get("world_truths", WORLD_TRUTHS) as Dictionary).duplicate(true)
	player_knowledge = (snapshot.get("player_knowledge", {}) as Dictionary).duplicate(true)
	deductions = (snapshot.get("deductions", {}) as Dictionary).duplicate(true)
	choice_history = (snapshot.get("choice_history", []) as Array).duplicate(true)
	visited_characters = (snapshot.get("visited_characters", {}) as Dictionary).duplicate(true)
	narrative_values = (snapshot.get("narrative_values", {}) as Dictionary).duplicate(true)
	narrative_records = (snapshot.get("narrative_records", {}) as Dictionary).duplicate(true)
	narrative_counters = (snapshot.get("narrative_counters", {}) as Dictionary).duplicate(true)
	technical_values = (snapshot.get("technical_values", {}) as Dictionary).duplicate(true)
	technical_collections = (snapshot.get("technical_collections", {}) as Dictionary).duplicate(true)
	last_spoken_line = str(snapshot.get("last_spoken_line", ""))
	current_scene = str(snapshot.get("current_scene", "《雾港日报》编辑部·上午"))
	current_character = str(snapshot.get("current_character", ""))
	current_topic = str(snapshot.get("current_topic", "退稿、派活、同馆前辈之死"))
	current_stage = str(snapshot.get("current_stage", "前序·退稿与派活"))
	first_interview_target = str(snapshot.get("first_interview_target", ""))
	current_theory = str(snapshot.get("current_theory", ""))
	confrontation_style = str(snapshot.get("confrontation_style", ""))
	disclosure_level = str(snapshot.get("disclosure_level", ""))
	yutang_pressure_level = int(snapshot.get("yutang_pressure_level", 0))
	used_bluff_on_chen = bool(snapshot.get("used_bluff_on_chen", false))
	demo_finished = bool(snapshot.get("demo_finished", false))
	completion_kind = str(snapshot.get("completion_kind", ""))
	completion_name = str(snapshot.get("completion_name", ""))


func reset() -> void:
	player_knowledge.clear()
	deductions.clear()
	choice_history.clear()
	visited_characters.clear()
	narrative_values.clear()
	narrative_records.clear()
	narrative_counters.clear()
	technical_values.clear()
	technical_collections.clear()
	last_spoken_line = ""
	current_scene = "《雾港日报》编辑部·上午"
	current_character = ""
	current_topic = "退稿、派活、同馆前辈之死"
	current_stage = "前序·退稿与派活"
	first_interview_target = ""
	current_theory = ""
	confrontation_style = ""
	disclosure_level = ""
	yutang_pressure_level = 0
	used_bluff_on_chen = false
	demo_finished = false
	completion_kind = ""
	completion_name = ""


func _quoted_text(text: String) -> String:
	var left := text.find("“")
	var right := text.rfind("”")
	if left >= 0 and right > left:
		return text.substr(left + 1, right - left - 1).strip_edges()
	left = text.find("\"")
	right = text.rfind("\"")
	if left >= 0 and right > left:
		return text.substr(left + 1, right - left - 1).strip_edges()
	return ""
