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
	var on_enter := str(node.get("on_enter", ""))
	# D27's OnEnter cell contains a routed launch directive plus authoring
	# guidance for the following choices.  It is not a state mutation; dispatch
	# the data-driven puzzle here and re-enter D27 after success so its gated
	# frame choices become available.
	if node_id == "D27":
		if not bool(state.get_value("proofcheck_done", false)):
			var proof_puzzle := _puzzle_for_node(node_id)
			if proof_puzzle.is_empty():
				return _fail("D27 缺少核稿谜题")
			pending_kind = "puzzle"
			pending_puzzle_id = str(proof_puzzle.get("puzzle_id", ""))
			last_event = _event(node, "puzzle", proof_puzzle)
			return last_event
		# The remaining text in this authoring cell is display guidance, not DSL.
		on_enter = ""
	if not on_enter.is_empty() and not state.apply_mutations(on_enter):
		return _fail("节点进入状态写入失败：" + node_id)
	var node_type := str(node.get("node_type", "scene"))
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
		pending_choices = available_choices(node_id)
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
	var choices := available_choices(node_id)
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
	return enter_node(target)


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
		"summary": str(node.get("player_text_summary", "")),
		"payload": payload,
	}


func _fail(message: String) -> Dictionary:
	errors.append(message)
	return {"kind": "error", "error": message, "node_id": current_node_id}
