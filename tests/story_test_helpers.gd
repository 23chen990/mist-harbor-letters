extends RefCounted

# Click the same visible buttons as a player. Internal jump methods would bypass
# pending protagonist responses and must not be used by this flow driver.
var main: Control
var tree: SceneTree
var report: Callable
var visited_stages: Array[String] = []
var seen_text: Array[String] = []
var clicked_lines: Array[String] = []


func _init(scene: Control, scene_tree: SceneTree, expectation: Callable) -> void:
	main = scene
	tree = scene_tree
	report = expectation
	observe()


func button(text_value: String) -> Button:
	for node: Node in main.canvas.find_children("*", "Button", true, false):
		var candidate := node as Button
		if candidate != null and _plain_line(candidate.text) == _plain_line(text_value) and candidate.is_visible_in_tree() and not candidate.is_queued_for_deletion() and not candidate.disabled:
			return candidate
	return null


func response_buttons() -> Array[Button]:
	var result: Array[Button] = []
	for node: Node in main.canvas.find_children("*", "Button", true, false):
		var candidate := node as Button
		if candidate != null and candidate.is_visible_in_tree() and not candidate.is_queued_for_deletion() and not candidate.disabled and bool(candidate.get_meta("player_response", false)):
			result.append(candidate)
	return result


func labels() -> String:
	var result: Array[String] = []
	for node: Node in main.canvas.find_children("*", "Label", true, false):
		var label := node as Label
		if label != null and label.is_visible_in_tree() and not label.is_queued_for_deletion():
			result.append(label.text)
	return "\n".join(result)


func observe() -> void:
	var stage := str(main.state.current_stage)
	if not visited_stages.has(stage):
		visited_stages.append(stage)
	var screen := labels()
	if not seen_text.has(screen):
		seen_text.append(screen)


func press(text_value: String) -> bool:
	var target := button(text_value)
	report.call(target != null, "阶段“%s”没有可点击按钮：%s" % [main.state.current_stage, text_value])
	if target == null:
		return false
	observe()
	clicked_lines.append(_plain_line(text_value))
	target.pressed.emit()
	await tree.process_frame
	if text_value == "寻找回信":
		await tree.create_timer(1.4).timeout
	observe()
	return true


func press_response(text_value: String) -> bool:
	var target := button(text_value)
	report.call(target != null and bool(target.get_meta("player_response", false)), "实际回答未渲染成主控按钮：%s" % text_value)
	if target == null:
		return false
	var history_count: int = main.state.choice_history.size()
	var result := await press(text_value)
	report.call(main.state.choice_history.size() == history_count + 1, "主控回答未且仅写入一次历史：%s" % text_value)
	report.call(_plain_line(str(main.state.last_spoken_line)) == _plain_line(text_value), "主控回答未记录为实际发言：%s" % text_value)
	return result


func visible_story_choices() -> Array[Button]:
	var result: Array[Button] = []
	for row: Dictionary in main.story.available_choices(main.state.current_stage, main.state):
		var target := button(str(row.get("玩家可选台词", "")))
		if target != null:
			result.append(target)
	return result


func step(allow_choices := true) -> bool:
	var responses := response_buttons()
	if responses.size() == 1 or (allow_choices and not responses.is_empty()):
		return await press_response(responses[0].text)
	for text_value: String in ["继续", "返回房间", "结束本章"]:
		if button(text_value) != null:
			return await press(text_value)
	if allow_choices:
		var choices := visible_story_choices()
		if not choices.is_empty():
			return await press(choices[0].text)
	report.call(false, "阶段“%s”没有可推进的真实 UI，按钮不能被脚本绕过" % main.state.current_stage)
	return false


func _plain_line(text_value: String) -> String:
	# Screenplay beats retain quotation marks while authored choice rows do not.
	# Both must refer to the same actual button, not a repository-row shortcut.
	return text_value.strip_edges().trim_prefix("「").trim_suffix("」")


func until_stage(target_stage: String, limit := 100, allow_choices := false) -> bool:
	for index in limit:
		if main.state.current_stage == target_stage:
			observe()
			return true
		if not await step(allow_choices):
			return false
	report.call(false, "真实 UI 推进 %d 步后仍未抵达 %s，实际为 %s" % [limit, target_stage, main.state.current_stage])
	return false


func until_button(text_value: String, limit := 100) -> bool:
	for index in limit:
		if button(text_value) != null:
			return true
		if not await step(false):
			return false
	report.call(false, "真实 UI 推进 %d 步后仍未出现按钮：%s" % [limit, text_value])
	return false


func until_end(limit := 400) -> bool:
	for index in limit:
		if main.state.demo_finished:
			return true
		if not await step():
			return false
	report.call(false, "真实 UI 全流程超过 %d 步：%s" % [limit, main.state.current_stage])
	return false
