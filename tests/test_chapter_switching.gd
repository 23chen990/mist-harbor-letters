extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main: Control = packed.instantiate()
	root.add_child(main)
	await process_frame
	main.state.apply_result("chapter1_started=true; report_focus=confirmed")
	main.state.record_choice("测试进度", "测试", "TEST_PROGRESS", false)
	_expect(not main.state.choice_history.is_empty(), "章节切换测试没有建立当前进度")

	var switch_button := _find_button(main, "测试：切换章节")
	_expect(switch_button != null, "正式试玩画面缺少切换章节的测试按钮")
	if switch_button != null:
		switch_button.pressed.emit()
		await process_frame

	var chapter_one := _find_button(main, "第一章")
	var chapter_two := _find_button(main, "第二章")
	var chapter_three := _find_button(main, "第三章")
	_expect(chapter_one != null, "章节选择层缺少第一章入口")
	_expect(chapter_two == null, "旧第二章运行数据已停用，章节选择层仍显示入口")
	_expect(chapter_three == null, "旧第三章运行数据已停用，章节选择层仍显示入口")

	if chapter_one != null:
		chapter_one.pressed.emit()
		await process_frame
		_expect(main.state.current_stage == "前序·退稿与派活", "切换第一章后没有回到编辑部开场")
		_expect(main.state.choice_history.is_empty(), "切换章节后仍保留旧选择历史")
		_expect(not main.state.condition_met("chapter1_started=true") and not main.state.condition_met("report_focus=confirmed"), "切换章节后仍保留旧技术状态")
		_expect(not main.chapter_panel.visible, "完成章节切换后选择层没有关闭")
		var back_button := _find_button(main, "测试：返回上一级选择")
		_expect(back_button != null and back_button.disabled, "切换章节后仍能退回旧章节选择")

	main.switch_to_chapter("第二章")
	_expect(main.state.current_stage == "前序·退稿与派活", "停用章节仍可被脚本切入")

	main.queue_free()
	await process_frame
	_finish()


func _choose_and_flow(main: Control, line: String) -> void:
	for row: Dictionary in main.story.available_choices(main.state.current_stage, main.state):
		if str(row.get("玩家可选台词", "")) == line:
			main.choose_story_row(row)
			await process_frame
			await _advance_until_choice(main)
			return
	_expect(false, "当前阶段没有选项：%s" % line)


func _advance_until_choice(main: Control) -> void:
	var guard := 0
	while not main.state.demo_finished and main.story.available_choices(main.state.current_stage, main.state).is_empty():
		guard += 1
		if guard > 30:
			_expect(false, "连续推进超限：%s" % main.state.current_stage)
			return
		main.advance_story()
		await process_frame


func _has_choice(main: Control, line: String) -> bool:
	for row: Dictionary in main.story.available_choices(main.state.current_stage, main.state):
		if str(row.get("玩家可选台词", "")) == line:
			return true
	return false


func _find_button(main: Control, text_value: String) -> Button:
	for node: Node in main.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text == text_value:
			return button
	return null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: chapter switching test button")
		quit(0)
	else:
		push_error("FAIL: %d chapter-switching assertions" % failures)
		quit(1)
