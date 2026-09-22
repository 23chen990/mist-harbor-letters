extends RefCounted
class_name R162Runtime

const StateStoreScript = preload("res://scripts/r16_2_state_store.gd")
const ArticleBuilderScript = preload("res://scripts/r16_2_article_builder.gd")

var data: Dictionary = {}
var state = StateStoreScript.new()
var article_builder = ArticleBuilderScript.new()
var current_node_id := ""
var pending_kind := ""
var pending_puzzle_id := ""
var pending_headline_choice_id := ""
var pending_choices: Array[Dictionary] = []
var dialogue_beats: Array[Dictionary] = []
var dialogue_index := -1
var dialogue_history: Array[String] = []
var current_text := ""
var feedback_next_node := ""
var feedback_choice_id := ""
var last_event: Dictionary = {}
var choice_snapshots: Dictionary = {}
var article_preview: Dictionary = {}
var ending_id := ""
var errors: Array[String] = []


func load_runtime(path: String = "res://content/程序生成_请勿手改/r16_2_runtime.json") -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("无法打开 R16.2 runtime 数据：" + path)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		errors.append("R16.2 runtime JSON 根节点不是对象")
		return false
	data = parsed
	state.configure(data.get("states", {}))
	article_builder.configure(data, state)
	current_node_id = ""
	pending_kind = ""
	pending_puzzle_id = ""
	pending_headline_choice_id = ""
	pending_choices.clear()
	dialogue_beats.clear()
	dialogue_index = -1
	dialogue_history.clear()
	current_text = ""
	feedback_next_node = ""
	feedback_choice_id = ""
	choice_snapshots.clear()
	article_preview.clear()
	ending_id = ""
	last_event.clear()
	errors.clear()
	return true


func start() -> Dictionary:
	return enter_node(str(data.get("meta", {}).get("start_node", "D00")))


func current_node() -> Dictionary:
	return data.get("nodes", {}).get(current_node_id, {})


func available_choices(node_id := current_node_id) -> Array[Dictionary]:
	if node_id == current_node_id and pending_kind not in ["choice", "draft_preview", "headline_confirm"]:
		return []
	return _eligible_choices(node_id)


func _eligible_choices(node_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for choice_id: Variant in data.get("choices", {}).keys():
		var choice: Dictionary = data["choices"][choice_id]
		if str(choice.get("node_id", "")) != node_id:
			continue
		if state.condition_met(str(choice.get("preconditions", ""))):
			result.append(choice)
	return result


func enter_node(node_id: String) -> Dictionary:
	if not data.get("nodes", {}).has(node_id):
		return _fail("找不到节点：" + node_id)
	var node: Dictionary = data["nodes"][node_id]
	if not state.condition_met(str(node.get("preconditions", ""))):
		return _fail("节点条件未满足：" + node_id)
	current_node_id = node_id
	pending_kind = ""
	pending_puzzle_id = ""
	pending_headline_choice_id = ""
	pending_choices.clear()
	dialogue_beats.clear()
	dialogue_index = -1
	current_text = ""
	feedback_next_node = ""
	feedback_choice_id = ""
	var on_enter := str(node.get("on_enter", ""))
	# D27's OnEnter cell contains a routed launch directive plus authoring
	# guidance for the following choices. It is not a state mutation.
	if node_id == "D27":
		on_enter = ""
	if not on_enter.is_empty() and not state.apply_mutations(on_enter):
		return _fail("节点进入状态写入失败：" + node_id)
	# Special-node summaries are production instructions, not player dialogue.
	# In particular, the timeline summary contains its complete solution.  For
	# normal scenes the deterministic compiler supplies the full DOCX performance
	# beats; the workbook summary remains a compatibility fallback for nodes whose
	# source text has not yet been authored.
	if str(node.get("node_type", "scene")) in ["scene", "prologue"]:
		dialogue_beats = _dialogue_beats_for_node(node)
	if not dialogue_beats.is_empty():
		dialogue_index = 0
		pending_kind = "dialogue"
		last_event = _dialogue_event(node)
		return last_event
	return _present_node_interaction(node)


func advance_dialogue() -> Dictionary:
	if pending_kind != "dialogue":
		return _fail("当前没有等待逐句对白")
	var node := current_node()
	if dialogue_index + 1 < dialogue_beats.size():
		dialogue_index += 1
		last_event = _dialogue_event(node)
		return last_event
	dialogue_beats.clear()
	dialogue_index = -1
	pending_kind = ""
	return _present_node_interaction(node)


func _present_node_interaction(node: Dictionary) -> Dictionary:
	var node_id := str(node.get("node_id", ""))
	var node_type := str(node.get("node_type", "scene"))
	if node_id == "D27" and not bool(state.get_value("proofcheck_done", false)):
		var proof_puzzle := _puzzle_for_node(node_id)
		if proof_puzzle.is_empty():
			return _fail("D27 缺少核稿谜题")
		pending_kind = "puzzle"
		pending_puzzle_id = str(proof_puzzle.get("puzzle_id", ""))
		last_event = _event(node, "puzzle", proof_puzzle)
		return last_event
	if node_type == "auto_build":
		article_preview = article_builder.build_preview()
		if not state.apply_mutations("article_auto_built=1"):
			return _fail("自动组稿状态写入失败")
		last_event = _event(node, "auto_build", article_preview)
		var next_auto := str(node.get("next_node", ""))
		if next_auto.is_empty():
			return last_event
		return enter_node(next_auto)
	if node_type == "draft_preview":
		article_preview = article_builder.build_preview()
		pending_kind = "draft_preview"
		pending_choices = _eligible_choices(node_id)
		last_event = _event(node, "draft_preview", article_preview)
		return last_event
	if node_type == "timeline_reconstruction":
		var puzzle := _puzzle_for_node(node_id)
		if puzzle.is_empty():
			return _fail("节点没有对应谜题：" + node_id)
		pending_kind = "puzzle"
		pending_puzzle_id = str(puzzle.get("puzzle_id", ""))
		pending_choices.clear()
		last_event = _event(node, "puzzle", puzzle)
		return last_event
	var choices := _eligible_choices(node_id)
	if not choices.is_empty():
		pending_kind = "choice"
		pending_choices = choices
		last_event = _event(node, "choice", {"choices": choices})
		return last_event
	var next_node := str(node.get("next_node", ""))
	if next_node == "ENDING_ROUTER":
		ending_id = resolve_ending()
		last_event = _event(node, "ending", {"ending_id": ending_id})
		return last_event
	if next_node.is_empty():
		last_event = _event(node, "pause", {})
		return last_event
	return enter_node(next_node)


func _visible_dialogue(source: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_beat: String in source.split(" / ", false):
		var beat := raw_beat.strip_edges()
		var conditions: Array[String] = []
		while true:
			var closing := ""
			var prefix_length := 0
			if beat.begins_with("【若 "):
				closing = "】"
				prefix_length = 2
			elif beat.begins_with("[若 "):
				closing = "]"
				prefix_length = 2
			else:
				break
			var end := beat.find(closing)
			if end < 0:
				break
			conditions.append(beat.substr(prefix_length, end - prefix_length).strip_edges())
			beat = beat.substr(end + 1).strip_edges()
		if beat.is_empty():
			continue
		var visible := true
		for condition: String in conditions:
			# Nodes/D68.OnEnter and StateDictionary explicitly define these
			# shorthand labels as values of yutang_departure_tone.
			var expression := condition
			if current_node_id == "D68" and condition in ["CORRECTION", "PROTECTED", "EXPOSED"]:
				expression = "yutang_departure_tone=" + condition
			if not state.condition_met(expression):
				visible = false
				break
		if visible:
			result.append({"text": beat, "conditions": conditions.duplicate()})
	return result


func _dialogue_beats_for_node(node: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var authored: Variant = node.get("dialogue_beats", [])
	if authored is Array and not (authored as Array).is_empty():
		for raw_beat: Variant in authored:
			result.append_array(_visible_dialogue(str(raw_beat)))
		return result
	return _visible_dialogue(str(node.get("player_text_summary", "")))


func _dialogue_event(node: Dictionary) -> Dictionary:
	var beat: Dictionary = dialogue_beats[dialogue_index]
	current_text = str(beat.get("text", ""))
	if dialogue_history.is_empty() or dialogue_history.back() != current_text:
		dialogue_history.append(current_text)
	return {
		"kind": "dialogue",
		"node_id": str(node.get("node_id", "")),
		"unit_id": str(node.get("unit_id", "")),
		"scene_title": str(node.get("scene_title", "")),
		"story_time": str(node.get("story_time", "")),
		"location": str(node.get("location", "")),
		"summary": current_text,
		"payload": {
			"beat": beat,
			"index": dialogue_index,
			"total": dialogue_beats.size(),
			"has_more": dialogue_index + 1 < dialogue_beats.size(),
		},
	}


func choose(choice_id: String) -> Dictionary:
	if pending_kind == "headline_confirm":
		if choice_id != pending_headline_choice_id:
			return _fail("确认交排的标题选择已改变")
		return _commit_choice(choice_id)
	if pending_kind != "choice" and pending_kind != "draft_preview":
		return _fail("当前没有等待选择：" + current_node_id)
	var choice: Dictionary = data.get("choices", {}).get(choice_id, {})
	if choice.is_empty() or str(choice.get("node_id", "")) != current_node_id:
		return _fail("选择不属于当前节点：" + choice_id)
	if not state.condition_met(str(choice.get("preconditions", ""))):
		return _fail("选择条件未满足：" + choice_id)
	if current_node_id == "D08":
		pending_headline_choice_id = choice_id
		pending_kind = "headline_confirm"
		last_event = _event(current_node(), "headline_selected", {"choice": choice})
		return last_event
	return _commit_choice(choice_id)


func confirm_headline() -> Dictionary:
	if pending_kind != "headline_confirm" or pending_headline_choice_id.is_empty():
		return _fail("当前没有等待送排确认")
	return choose(pending_headline_choice_id)


func _commit_choice(choice_id: String) -> Dictionary:
	var choice: Dictionary = data.get("choices", {}).get(choice_id, {})
	if choice.is_empty() or str(choice.get("node_id", "")) != current_node_id:
		return _fail("选择不属于当前节点：" + choice_id)
	if not state.condition_met(str(choice.get("preconditions", ""))):
		return _fail("选择条件未满足：" + choice_id)
	var snapshot_id := str(choice.get("snapshot_id", ""))
	if not snapshot_id.is_empty():
		choice_snapshots[snapshot_id] = state.create_snapshot(snapshot_id)
	var mutation := _choice_mutation(choice)
	if not mutation.is_empty() and not state.apply_mutations(mutation):
		return _fail("选择状态写入失败：" + choice_id)
	# Branch exploration is global and intentionally survives story rollback.
	state.add_value("seen_branches", str(choice.get("unit_id", choice_id)))
	pending_choices.clear()
	pending_kind = ""
	pending_headline_choice_id = ""
	var next_node := str(choice.get("next_node", ""))
	var feedback := str(choice.get("immediate_feedback", "")).strip_edges()
	# Some late-chapter cells are presentation recipes, not authored prose.
	# Keep navigating as before until full DOCX performance text is compiled;
	# never expose their DSL or route labels as player dialogue.
	if feedback.contains("=>") or feedback.begins_with("EXPOSED 路线"):
		feedback = ""
	# U28's feedback describes the backend auto-build. Its next player-facing
	# step is the preview, as required by RuntimeContract.
	var next_type := str(data.get("nodes", {}).get(next_node, {}).get("node_type", ""))
	if not feedback.is_empty() and next_type != "auto_build":
		pending_kind = "choice_feedback"
		feedback_next_node = next_node
		feedback_choice_id = choice_id
		current_text = feedback
		last_event = _event(current_node(), "choice_feedback", {})
		return last_event
	return _navigate_after_choice(next_node, choice_id)


func advance_choice_feedback() -> Dictionary:
	if pending_kind != "choice_feedback":
		return _fail("当前没有等待选择反馈")
	var next_node := feedback_next_node
	var choice_id := feedback_choice_id
	pending_kind = ""
	feedback_next_node = ""
	feedback_choice_id = ""
	return _navigate_after_choice(next_node, choice_id)


func _navigate_after_choice(next_node: String, choice_id: String) -> Dictionary:
	if next_node == "ENDING_ROUTER":
		ending_id = resolve_ending()
		last_event = {"kind": "ending", "choice_id": choice_id, "ending_id": ending_id}
		return last_event
	if next_node.is_empty():
		return _fail("选择没有下一节点：" + choice_id)
	return enter_node(next_node)


func solve_puzzle(order_or_choice: Variant) -> Dictionary:
	if pending_kind != "puzzle":
		return _fail("当前没有等待谜题")
	var puzzle: Dictionary = data.get("micro_puzzles", {}).get(pending_puzzle_id, {})
	if puzzle.is_empty():
		return _fail("找不到谜题：" + pending_puzzle_id)
	var answer := ""
	if order_or_choice is Array:
		answer = ">".join(order_or_choice)
	else:
		answer = str(order_or_choice)
	var puzzle_id := str(puzzle.get("puzzle_id", ""))
	if puzzle_id == "P_U27_PROOF":
		var expected_card := expected_invalid_card()
		# The interaction submits a card ID (C_DYNAMIC), while the route-specific
		# sentence is presentation data only.  Keep those protocols separate so
		# a dynamic sentence can never make the same answer fail its own check.
		if answer != expected_card:
			return {"kind": "puzzle_wrong", "puzzle_id": puzzle_id, "feedback": str(puzzle.get("on_wrong", "")), "expected": ""}
	elif answer != str(puzzle.get("correct_order", "")):
		return {"kind": "puzzle_wrong", "puzzle_id": puzzle_id, "feedback": str(puzzle.get("on_wrong", "")), "expected": ""}
	if not state.apply_mutations(str(puzzle.get("on_success", ""))):
		return _fail("谜题成功状态写入失败：" + puzzle_id)
	pending_kind = ""
	pending_puzzle_id = ""
	var next_node := str(puzzle.get("next_node", ""))
	# Some authoring rows carry a human-readable suffix (e.g. "D27 / reveal
	# frame choices").  Runtime navigation always uses the leading NodeID.
	if next_node.contains("/"):
		next_node = next_node.split("/", false)[0].strip_edges()
	if next_node == current_node_id:
		# "D27 / reveal frame choices" resumes this scene after proofchecking.
		# Re-entering it would replay all the dialogue before the puzzle.
		return _present_node_interaction(current_node())
	return enter_node(next_node) if not next_node.is_empty() else {"kind": "puzzle_success", "puzzle_id": puzzle_id}


func expected_invalid_card() -> String:
	# Return the selectable card ID, never the route-specific sentence.
	# `expected_invalid_card_text()` is available to presentation code.
	var puzzle: Dictionary = data.get("micro_puzzles", {}).get(pending_puzzle_id, {})
	return str(puzzle.get("correct_order", "C_DYNAMIC"))


func expected_invalid_card_text() -> String:
	var variants: Array[Dictionary] = []
	for row: Variant in data.get("puzzle_variants", []):
		if str(row.get("puzzle_id", "")) != pending_puzzle_id:
			continue
		if str(row.get("condition", "")) == "ELSE" or state.condition_met(str(row.get("condition", ""))):
			variants.append(row)
	variants.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("priority", 999)) < int(b.get("priority", 999)))
	if not variants.is_empty():
		return str(variants[0].get("dynamic_card_c", ""))
	return "路线动态不可刊句"


func rollback(snapshot_id: String) -> Dictionary:
	if not choice_snapshots.has(snapshot_id):
		return _fail("没有保存快照：" + snapshot_id)
	state.restore_snapshot(choice_snapshots[snapshot_id], true)
	var snapshot_rows: Dictionary = data.get("snapshots", {})
	var target := str(snapshot_rows.get(snapshot_id, {}).get("restore_target", ""))
	if target.is_empty():
		return _fail("快照没有恢复目标：" + snapshot_id)
	var event := enter_node(target)
	if pending_kind == "dialogue":
		# A choice snapshot restores the decision point the player already read.
		# Preserve its final visible line without requiring the scene to be read again.
		current_text = str(dialogue_beats.back().get("text", ""))
		dialogue_beats.clear()
		dialogue_index = -1
		pending_kind = ""
		return _present_node_interaction(current_node())
	return event


func confirm_typeset() -> Dictionary:
	if pending_kind != "draft_preview":
		return _fail("当前不在整版预览确认阶段")
	for choice: Dictionary in pending_choices:
		if str(choice.get("choice_id", "")) == "C_D65C_CONFIRM":
			return choose("C_D65C_CONFIRM")
	return _fail("缺少确认交排选择")


func resolve_ending() -> String:
	var candidates: Array[Dictionary] = []
	for ending_id_key: Variant in data.get("endings", {}).keys():
		var ending: Dictionary = data["endings"][ending_id_key]
		candidates.append(ending)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("priority", 999)) < int(b.get("priority", 999)))
	for ending: Dictionary in candidates:
		var condition := str(ending.get("condition", ""))
		if condition.begins_with("ELSE") or state.condition_met(condition):
			var selected := str(ending.get("ending_id", ""))
			state.add_value("unlocked_endings", selected)
			return selected
	return ""


func _puzzle_for_node(node_id: String) -> Dictionary:
	for puzzle_id: Variant in data.get("micro_puzzles", {}).keys():
		var puzzle: Dictionary = data["micro_puzzles"][puzzle_id]
		if str(puzzle.get("node_id", "")) == node_id:
			return puzzle
	return {}


func _choice_mutation(choice: Dictionary) -> String:
	var parts: Array[String] = []
	for field: String in ["set_flags", "clear_flags", "promise_change", "knowledge_change", "article_state_change"]:
		var value := str(choice.get(field, ""))
		if not value.is_empty():
			parts.append(value)
	return "; ".join(parts)


func _event(node: Dictionary, kind: String, payload: Dictionary) -> Dictionary:
	return {
		"kind": kind,
		"node_id": str(node.get("node_id", "")),
		"unit_id": str(node.get("unit_id", "")),
		"scene_title": str(node.get("scene_title", "")),
		"story_time": str(node.get("story_time", "")),
		"location": str(node.get("location", "")),
		"summary": current_text,
		"payload": payload,
	}


func _fail(message: String) -> Dictionary:
	errors.append(message)
	return {"kind": "error", "error": message, "node_id": current_node_id}
