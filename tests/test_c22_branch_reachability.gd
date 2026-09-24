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
	main.state.apply_result("report_focus=location")
	main._go_to_stage("第一章·第一章结尾")
	await process_frame
	_expect(not main.state.demo_finished, "疑点报道进入 C22_001 时不应提前结束")
	if await driver.press("继续"):
		_expect(main.state.current_stage == "第一章·第一章结尾·编辑", "疑点报道没有进入编辑裁决")
		_expect("这栏出去了" in driver.labels(), "疑点报道没有显示编辑的强反馈")
	if main.state.current_stage == "第一章·第一章结尾·编辑" and await driver.press("继续"):
		_expect(main.state.current_stage == "第一章·第一章结尾·名单", "编辑裁决后没有进入名单机会")
	if main.state.current_stage == "第一章·第一章结尾·名单" and await driver.press("先放着。"):
		_expect(main.state.current_stage == "第一章·第一章结尾·收束", "选择暂不抄录后没有进入收束")
		_expect(main.state.condition_met("fang_roster_offer=ignored"), "暂不抄录没有写入状态")
	if main.state.current_stage == "第一章·第一章结尾·收束" and await driver.press("结束本章"):
		_expect(main.state.demo_finished, "疑点报道路线没有完成 Demo")
		_expect(main.state.completion_label() == "第一章结束", "疑点报道路线章末名称错误")
	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: C22 non-confirmed editor feedback and roster refusal")
		quit(0)
	else:
		push_error("FAIL: %d C22 branch assertions" % failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
