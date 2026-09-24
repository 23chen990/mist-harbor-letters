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
	main.state.apply_result("report_focus=confirmed")
	main._go_to_stage("第一章·第一章结尾")
	await process_frame
	_expect(not main.state.demo_finished, "进入 C22_001 时不应立即结束 Demo")
	if await driver.press("继续"):
		_expect(main.state.current_stage == "第一章·第一章结尾·编辑", "C22_001 继续后应进入编辑裁决")
		_expect(not main.state.demo_finished, "编辑裁决前不应结束 Demo")
	if main.state.current_stage == "第一章·第一章结尾·编辑" and await driver.press("继续"):
		_expect(main.state.current_stage == "第一章·第一章结尾·名单", "编辑裁决后应展示站位名单机会")
		_expect(driver.button("留下。明天去抄。") != null, "站位名单应由玩家亲自选择是否留下")
	if main.state.current_stage == "第一章·第一章结尾·名单" and await driver.press("留下。明天去抄。"):
		_expect(main.state.current_stage == "第一章·第一章结尾·收束", "名单选择后应进入章末收束")
		_expect(main.state.condition_met("fang_roster_offer=accepted"), "名单选择未写入实际状态")
		_expect(not main.state.demo_finished, "玩家抵达收束画面前不应结束 Demo")
	if main.state.current_stage == "第一章·第一章结尾·收束" and await driver.press("结束本章"):
		_expect(main.state.demo_finished, "玩家点击结束本章后 Demo 应完成")
	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: C22 editor and roster hook reachable before chapter end")
		quit(0)
	else:
		push_error("FAIL: %d C22 reachability assertions" % failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
