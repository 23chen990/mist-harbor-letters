extends SceneTree

const Driver = preload("res://tests/story_test_helpers.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var driver := Driver.new(main, self, _expect)
	main.state.reset()
	main._entry_results_applied.clear()
	main.state.apply_result("c07_position=side; pre_police_check=path; 记录“已寻找林怀安回函”; 记录“已完成序章案件线索检查”; notes += C07_side; notes += C09_position; notes += C12_path; report_focus=confirmed")
	main._go_to_stage("第一章·第一篇稿")
	await process_frame
	var visible_text := driver.labels()
	_expect("截至截稿，确切死因尚未公布。" in visible_text, "写稿页没有显示已经排好的基础段")
	_expect("现场速记" in visible_text, "写稿页没有显示玩家取得的现场速记标题")
	_expect("林怀安沿侧台通道中央走向侧厅" in visible_text, "写稿页没有显示 C07 的现场记录")
	_expect("舞台出口到侧厅的最短路线" in visible_text, "写稿页没有显示 C12 的现场记录")
	_expect("原件｜已完成序章案件线索检查" not in visible_text and "原件｜已寻找林怀安回函" not in visible_text, "操作进度被误标成原件")
	_expect(driver.button("倒地位置与离场路线对不上") != null, "写稿页没有显示已有记录支持的报道选项")
	_expect(main.canvas.find_children("*", "ScrollContainer", true, false).size() >= 1, "材料列表没有可滚动的容器")
	if await driver.press("倒地位置与离场路线对不上"):
		_expect(main.state.current_stage == "第一章·第一篇稿", "选择报道判断后不应直接离开写稿页")
		_expect("选择支持这句话的现场记录" in driver.labels(), "选择判断后没有进入来源选择步骤")
		_expect(not main.state.condition_met("report_focus=location"), "尚未选择来源就提前写入报道口径")
		var source_button := _button_containing(main.canvas, "谢幕时沿侧台通道中央走向侧厅")
		_expect(source_button != null, "位置判断没有提供可用的现场记录来源")
		if source_button != null:
			source_button.pressed.emit()
			await process_frame
			_expect(main.state.current_stage == "第一章·是否写入赵敬文", "选择来源后没有进入下一段写稿流程")
			_expect(main.state.condition_met("report_focus=location"), "选择来源后没有写入报道口径")
	_expect(not main.state.demo_finished, "进入写稿页时不应结束 Demo")
	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: writing panel exposes source records and supported claim")
		quit(0)
	else:
		push_error("FAIL: %d writing panel assertions" % failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _button_containing(parent: Node, fragment: String) -> Button:
	for node: Node in parent.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.is_visible_in_tree() and not button.disabled and fragment in button.text:
			return button
	return null
