extends SceneTree

const BRIDGE_SCENES := ["S00", "S01", "S02", "C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08", "C09", "C10", "C11", "C12", "C13", "C14", "C15", "C17-20", "C21-22", "END"]
const NONBRIDGE_SCENES := ["S00", "S01", "S02", "C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08", "C09", "C10", "C11", "C12", "C13", "C14", "C16", "C17-20", "C21-22", "END"]
const FORBIDDEN_PLAYER_TEXT := ["v19", "全流程灰盒", "S00", "S01", "S02", "C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08", "C09", "C10", "C11", "C12", "C13", "C14", "C15", "C16", "C17-20", "C21-22", "END", "R 重新开始", "DEBUG"]

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner_source := FileAccess.get_file_as_string("res://interaction_lab.gd")
	_expect(runner_source.contains("_reset_scroll_after_layout"), "换句/换页后没有显式复位内容滚动位置")
	var scene: PackedScene = load("res://interaction_lab.tscn")
	var probe: Control = scene.instantiate()
	root.add_child(probe)
	await process_frame
	var methods_ok := _has_methods(probe, [&"advance_line", &"has_active_line", &"available_choice_ids", &"choose_option", &"current_beat_id", &"current_scene_id", &"toggle_window_size", &"minimize_window"])
	probe.queue_free()
	await process_frame
	if not methods_ok:
		_finish()
		return
	await _test_single_line_and_protagonist_speech(scene)
	await _test_npc_lines_advance_one_at_a_time(scene)
	await _test_window_controls_and_responsive_layout(scene)
	await _test_bridge_full_flow(scene)
	await _test_nonbridge_full_flow(scene)
	await _test_ui_input_cooldown(scene)
	_finish()


func _test_single_line_and_protagonist_speech(scene: PackedScene) -> void:
	var lab: Control = scene.instantiate()
	root.add_child(lab)
	await process_frame
	_assert_player_chrome(lab)
	_expect(_story_line_card_count(lab) == 1, "初始页没有且仅有一张当前内容卡")
	_expect(_visible_text(lab).contains("电话铃、打字机"), "初始页没有第一句叙事")
	_expect(not _visible_text(lab).contains("六号码头这篇"), "初始页提前显示下一句 NPC 对白")
	_expect(_find_button(lab, "继续") == null, "玩家界面仍有通用继续按钮")

	_expect(lab.advance_line(), "点击第一张内容卡无法推进")
	await process_frame
	_expect(_visible_text(lab).contains("六号码头这篇，今天不上了"), "第二次只应出现编辑当前句")
	_expect(not _visible_text(lab).contains("末句“显然"), "编辑句出现时提前显示下一句叙事")
	lab.advance_line()
	await process_frame
	_expect(_visible_text(lab).contains("末句“显然有人事先动过手脚”"), "第三句叙事没有单独出现")
	lab.advance_line()
	await process_frame
	_expect(lab.available_choice_ids() == ["speak_current_line"], "轮到沈砚舟时没有只提供一项原句回答")
	_expect(_find_button(lab, "再给我半个钟头。我还能补出人证。") != null, "沈砚舟原句按钮没有逐字显示")
	_expect(not _visible_speaker_labels(lab).has("沈砚舟"), "点击前已把沈砚舟句显示成说过的对白")
	_expect(_story_line_card_count(lab) == 0, "点击前沈砚舟原句已成为对话卡")
	_expect(lab.choose_option("speak_current_line"), "无法选择沈砚舟原句")
	await process_frame
	_expect(_visible_speaker_labels(lab).has("沈砚舟"), "点击原句后没有显示沈砚舟说话人")
	_expect(_story_line_card_count(lab) == 1, "点击原句后没有只显示沈砚舟当前对话卡")
	_expect(lab.current_beat_id() == "s00_rejection", "选择沈砚舟原句后提前进入下一 node")
	_expect(lab.advance_line(), "沈砚舟对话卡无法再次点击推进")
	await process_frame
	_expect(lab.current_beat_id() == "s00_assignment", "沈砚舟对话卡点击后没有进入下一 node")
	_expect(_visible_text(lab).contains("编辑把他的稿子"), "进入下一 node 后没有只显示第一句")
	_expect(not _visible_text(lab).contains("赵老那张桌"), "进入下一 node 后同时显示后续 NPC 句")
	lab.queue_free()
	await process_frame


func _test_window_controls_and_responsive_layout(scene: PackedScene) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 540)
	root.add_child(viewport)
	var lab: Control = scene.instantiate()
	viewport.add_child(lab)
	await process_frame
	await process_frame
	for action: String in ["drag", "minimize", "maximize", "close", "resize"]:
		_expect(_find_window_action(lab, action) != null, "无边框窗口缺少玩家可见控制：%s" % action)
	_expect(lab.shell.size.is_equal_approx(Vector2(960, 540)), "960×540 时界面没有跟随窗口尺寸")
	_expect(lab.scroll.position.y >= 96.0 and lab.scroll.get_rect().end.y <= 540.0, "960×540 时正文滚动区超出窗口")
	viewport.size = Vector2i(1440, 900)
	await process_frame
	await process_frame
	_expect(lab.shell.size.is_equal_approx(Vector2(1440, 900)), "1440×900 时界面没有响应放大")
	_expect(lab.scroll.get_rect().end.y <= 900.0, "放大后正文滚动区被裁切")
	var project_source := FileAccess.get_file_as_string("res://project.godot")
	_expect(project_source.contains("window/size/resizable=true"), "项目没有显式允许调整窗口大小")
	_expect(project_source.contains("window/size/min_width=960") and project_source.contains("window/size/min_height=540"), "窗口没有安全的最小尺寸")
	_expect(project_source.contains("window/stretch/aspect=\"expand\""), "放大后没有采用 expand 响应策略")
	viewport.queue_free()
	await process_frame


func _test_npc_lines_advance_one_at_a_time(scene: PackedScene) -> void:
	var lab: Control = scene.instantiate()
	root.add_child(lab)
	await process_frame
	lab.call("_enter_node", "c10_drug")
	await process_frame
	_expect(_visible_text(lab).contains("玉棠，人没救回来"), "C10 第一条 NPC 对白未显示")
	_expect(not _visible_text(lab).contains("摸出小药盒"), "C10 同时显示了下一条叙事")
	_expect(not _visible_text(lab).contains("药是你配的"), "C10 同时显示了后续 NPC 对白")
	lab.advance_line()
	await process_frame
	_expect(_visible_text(lab).contains("摸出小药盒"), "C10 点击 NPC 句后没有进入下一条叙事")
	_expect(not _visible_text(lab).contains("玉棠，人没救回来"), "C10 上一句没有被当前句替换")

	lab.call("_enter_node", "c13_arrival")
	await process_frame
	_expect(_visible_text(lab).contains("顾承钧带两名警员"), "C13 第一条叙事未显示")
	_expect(not _visible_text(lab).contains("外头已经传成心疾"), "C13 提前成组显示 NPC 对白")
	lab.advance_line()
	await process_frame
	_expect(_visible_text(lab).contains("外头已经传成心疾"), "C13 第二次点击没有显示顾承钧当前句")
	_expect(not _visible_text(lab).contains("我说过他有心疾"), "C13 同时显示下一名 NPC 对白")
	lab.queue_free()
	await process_frame


func _test_bridge_full_flow(scene: PackedScene) -> void:
	var lab: Control = scene.instantiate()
	root.add_child(lab)
	await process_frame
	var sequence := [
		"s00_accept", "desk_performance", "desk_old_report", "desk_letter", "desk_death", "desk_map", "desk_done",
		"letter_original", "c01_present_pass", "c03_step_ladder", "c04_ask_old_report", "probe_reply_missing", "letter_keep",
		"position_stage", "mid_scenery_height", "end_lin_route", "route_follow", "first_neck", "pre_bridge",
		"bridge_look_down", "bridge_rope_row", "bridge_rope_close", "police_scope_contact", "police_letter_retain",
		"c15_hide", "claim_rope", "submit_report", "check_ledger",
	]
	for choice_id: String in sequence:
		await _drive_to_choice(lab, choice_id)
		_expect(lab.choose_option(choice_id), "天桥路径选择失败：%s" % choice_id)
		await process_frame
		_assert_player_chrome(lab)
	_expect(str(lab.current_scene_id()) == "END", "天桥路径查收发簿后没有进入终章")
	_expect(_has_all_scenes(lab.visited_scenes, BRIDGE_SCENES), "天桥路径缺少完整场次：%s" % str(lab.visited_scenes))
	_expect(not lab.visited_scenes.has("C16"), "天桥路径错误进入 C16")
	_expect(bool(lab.state.report_submitted) and bool(lab.state.run_finished), "天桥路径没有保存交稿或结束状态")
	lab.queue_free()
	await process_frame


func _test_nonbridge_full_flow(scene: PackedScene) -> void:
	var lab: Control = scene.instantiate()
	root.add_child(lab)
	await process_frame
	var sequence := [
		"s00_accept", "desk_performance", "desk_old_report", "desk_letter", "desk_death", "desk_done",
		"letter_copy", "c01_present_pass", "c03_step_ladder", "c04_ask_old_report", "probe_desk_gap",
		"position_front", "mid_fang_desk", "end_stage_exit", "route_wait", "first_position", "pre_guard",
		"police_scope_old_report", "follow_fang", "claim_fang_absent", "submit_report", "check_ledger",
	]
	for choice_id: String in sequence:
		await _drive_to_choice(lab, choice_id)
		_expect(lab.choose_option(choice_id), "非天桥路径选择失败：%s" % choice_id)
		await process_frame
		_assert_player_chrome(lab)
	_expect(str(lab.current_scene_id()) == "END", "非天桥路径查收发簿后没有进入终章")
	_expect(_has_all_scenes(lab.visited_scenes, NONBRIDGE_SCENES), "非天桥路径缺少完整场次：%s" % str(lab.visited_scenes))
	_expect(not lab.visited_scenes.has("C15"), "非天桥路径错误进入 C15")
	_expect(lab.state.has_evidence("fang_questioned"), "非天桥路径没有保存 C16 主动追问")
	lab.call("_start_new_run")
	await process_frame
	_expect(lab.state.knowledge.is_empty() and lab.state.evidence.is_empty(), "重开没有清空知识或证据")
	_expect(not lab.state.report_submitted and not lab.state.run_finished, "重开没有清空交稿或结束状态")
	_assert_player_chrome(lab)
	lab.queue_free()
	await process_frame


func _test_ui_input_cooldown(scene: PackedScene) -> void:
	var lab: Control = scene.instantiate()
	root.add_child(lab)
	await process_frame
	var before_line = lab.call("current_line_index")
	lab.call("_dispatch_ui", Callable(lab, "advance_line"))
	_expect(lab.call("current_line_index") == before_line, "新内容卡出现后立即接受残留点击")
	await create_timer(0.22).timeout
	lab.call("_dispatch_ui", Callable(lab, "advance_line"))
	_expect(lab.call("current_line_index") != before_line, "180ms 输入隔离结束后仍无法推进内容卡")
	lab.queue_free()
	await process_frame


func _drive_to_choice(lab: Control, choice_id: String, max_steps := 500) -> void:
	for _step in range(max_steps):
		_assert_player_chrome(lab)
		var available: Array = lab.available_choice_ids()
		if available.has(choice_id):
			return
		_expect(_find_button(lab, "继续") == null, "全流程中出现通用继续按钮")
		if available.has("speak_current_line"):
			_expect(lab.choose_option("speak_current_line"), "沈砚舟原句无法选择")
			await process_frame
		elif lab.has_active_line():
			_expect(lab.advance_line(), "当前内容卡无法推进：%s" % str(lab.current_beat_id()))
			await process_frame
		else:
			_expect(false, "到达 %s 前卡在 %s，现有选择：%s" % [choice_id, lab.current_beat_id(), str(available)])
			return
	_expect(false, "逐句推进 %d 次仍未到达选择：%s" % [max_steps, choice_id])


func _assert_player_chrome(lab: Control) -> void:
	var text := _visible_text(lab)
	for forbidden: String in FORBIDDEN_PLAYER_TEXT:
		_expect(not text.contains(forbidden), "玩家界面泄露内部/调试文字：%s" % forbidden)
	_expect(text.contains("雾港来信"), "玩家标题没有保留作品名")


func _has_methods(node: Node, methods: Array[StringName]) -> bool:
	var all_present := true
	for method_name: StringName in methods:
		if not node.has_method(method_name):
			_expect(false, "场景缺少预期 API：%s" % method_name)
			all_present = false
	return all_present


func _has_all_scenes(trace: Array, expected: Array) -> bool:
	for scene_id in expected:
		if not trace.has(scene_id):
			return false
	return true


func _visible_text(node: Node) -> String:
	var parts: Array[String] = []
	for child: Node in node.find_children("*", "Label", true, false):
		parts.append(str((child as Label).text))
	for child: Node in node.find_children("*", "Button", true, false):
		parts.append(str((child as Button).text))
	return "\n".join(parts)


func _visible_speaker_labels(node: Node) -> Array[String]:
	var speakers: Array[String] = []
	for child: Node in node.find_children("*", "Label", true, false):
		if child.has_meta("speaker_label"):
			speakers.append(str((child as Label).text))
	return speakers


func _story_line_card_count(node: Node) -> int:
	var count := 0
	for child: Node in node.find_children("*", "Button", true, false):
		if child.has_meta("story_line_card"):
			count += 1
	return count


func _find_button(node: Node, text_value: String) -> Button:
	for child: Node in node.find_children("*", "Button", true, false):
		var button := child as Button
		if button.text == text_value:
			return button
	return null


func _find_window_action(node: Node, action: String) -> Control:
	for child: Node in node.find_children("*", "Control", true, false):
		if child.has_meta("window_action") and str(child.get_meta("window_action")) == action:
			return child as Control
	return null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: interaction lab line-by-line flow")
		quit(0)
	else:
		push_error("FAIL: %d interaction-lab assertions" % failures)
		quit(1)
