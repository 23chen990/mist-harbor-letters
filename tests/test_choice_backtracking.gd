extends SceneTree

const Driver = preload("res://tests/story_test_helpers.gd")
const FIRST_HOTSPOT := "「春和」工作夹"
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var driver := Driver.new(main, self, _expect)
	if not await driver.until_stage("前序·自由探索"):
		main.queue_free()
		_finish()
		return
	var opening_history: int = main.state.choice_history.size()
	_expect(opening_history == 2, "进入工作桌前应实际说出两句开场回答")
	await driver.press(FIRST_HOTSPOT)
	_expect(main.state.choice_history.size() == opening_history + 1, "点击工作桌热点未且仅记录一次选择")
	_expect(main.state.has_record("已查看春和工作夹"), "点击工作夹后没有写入查看记录")
	await driver.press("测试：返回上一级选择")
	_expect(main.state.current_stage == "前序·自由探索", "返回后没有回到工作桌")
	_expect(main.state.choice_history.size() == opening_history, "撤销热点时错误清掉开场发言或保留热点历史")
	_expect(not main.state.has_record("已查看春和工作夹"), "返回后没有撤销查看记录")
	_expect(driver.button(FIRST_HOTSPOT) != null, "返回后工作夹热点没有恢复")
	await driver.press(FIRST_HOTSPOT)
	await driver.press("测试：重新开始")
	_expect(main.state.current_stage == "前序·退稿与派活", "重新开始没有回到 v6 开场")
	_expect(main.state.choice_history.is_empty(), "重新开始后仍保留旧选择与发言历史")
	_expect(not main.state.has_record("已查看春和工作夹"), "重新开始后仍保留探索记录")
	_expect(driver.button("他死前还在跑春和？") != null, "重新开始没有恢复第一句主控回答")
	main.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: exploration backtracking preserves earlier spoken history and restart resets all")
		quit(0)
	else:
		push_error("FAIL: %d backtracking assertions" % failures)
		quit(1)
