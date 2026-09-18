extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main: Control = packed.instantiate()
	root.add_child(main)
	await process_frame

	_expect(main.state.current_stage == "前序·退稿与派活", "测试必须从 P0001 开场开始")
	var split_sample: Array[String] = main._split_into_presentation_beats("旁白第一句。旁白第二句。")
	_expect(split_sample.size() == 2, "普通叙述没有按完整句拆分")
	if split_sample.size() == 2:
		_expect(split_sample[0] == "旁白第一句。" and split_sample[1] == "旁白第二句。", "普通叙述没有保持一点击一句")
	var quoted_narration: Array[String] = main._split_into_presentation_beats("稿纸末句“显然有人动过手脚”已被划去。上面只留下原始观察。")
	_expect(quoted_narration.size() == 2, "叙述中的引文错误阻止了外层句号切分")
	var opening_beats: Array[Dictionary] = main._presentation_beats(main.story.available_presentations(main.state.current_stage, main.state))
	_expect(not opening_beats.is_empty(), "开场没有生成对白节拍")
	var initial_text := _canvas_text(main)
	_expect("编辑" in initial_text, "首拍没有直接显示编辑")
	_expect(not "场景" in initial_text, "场景动作仍被显示在对话框")
	for _frame in 8:
		await process_frame
	_expect(_canvas_text(main) == initial_text, "玩家没有点击时剧情句发生了自动推进")

	# 用不依赖正式开场长短的两句 NPC 对白验证一点击一句。
	var stage := "测试·逐句NPC"
	var row: Dictionary = {"自动ID": "TEST_MANUAL", "场景": "测试场景", "对话阶段": stage, "人物": "编辑", "内容类型": "NPC台词", "NPC台词": "编辑：「第一句。」\n编辑：「第二句。」", "出现条件": "始终", "下一话题": "前序·退稿与派活", "是否说出口": "是"}
	main.story.rows.append(row)
	main.story._stages[stage] = [row]
	main._go_to_stage(stage)
	await process_frame
	_expect("第一句。" in _canvas_text(main) and not "第二句。" in _canvas_text(main), "NPC 后句提前出现")
	var continue_button := _canvas_button(main, "继续")
	_expect(continue_button != null, "NPC 连续对白没有提供继续按钮")
	if continue_button != null:
		continue_button.pressed.emit()
		await process_frame
	_expect("第二句。" in _canvas_text(main) and not "第一句。" in _canvas_text(main), "点击没有逐句替换 NPC 对白")
	_expect(main.state.current_stage == stage, "一次继续越过了整个阶段")
	main._restart()
	await process_frame
	var guard := 0
	while main.state.current_stage != "前序·自由探索" and guard < 20:
		var advance := _next_button(main)
		_expect(advance != null, "开场缺少玩家可操作的下一步")
		if advance == null:
			break
		advance.pressed.emit()
		await process_frame
		guard += 1
	_expect(main.state.current_stage == "前序·自由探索", "开场短场景没有经玩家点击进入自由探索")

	main.queue_free()
	await process_frame
	_finish()


func _canvas_text(main: Control) -> String:
	var lines: Array[String] = []
	for node: Node in main.canvas.find_children("*", "Label", true, false):
		var label := node as Label
		if label != null and not label.text.is_empty():
			lines.append(label.text)
	return "\n".join(lines)


func _canvas_button(main: Control, text_value: String) -> Button:
	for node: Node in main.canvas.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.text == text_value:
			return button
	return null


func _next_button(main: Control) -> Button:
	for node: Node in main.canvas.find_children("*", "Button", true, false):
		var button := node as Button
		if button.has_meta("player_response"):
			return button
	return _canvas_button(main, "继续")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: manual line advance")
		quit(0)
	else:
		push_error("FAIL: %d manual-line assertions" % failures)
		quit(1)
