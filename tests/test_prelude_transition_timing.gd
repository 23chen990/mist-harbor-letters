extends SceneTree

const Driver = preload("res://tests/story_test_helpers.gd")
const CLUES: Array[String] = ["赵敬文死亡报道 / 旧戏院草图", "二十年前的旧报", "「春和」工作夹", "寄给林怀安的采访函留底"]
const PREPARATION: Array[String] = ["带上采访函留底", "抄下函件正文", "原件先不动，只记住要点"]
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
	for index in CLUES.size():
		await driver.press(CLUES[index])
		if index == 3:
			_expect(main.state.current_stage == "前序·函件正文", "采访函作为第四项时没有先展示原文")
			_expect(driver.button("返回房间") == null, "第四项采访函可跳过主动寻信")
			for option: String in PREPARATION:
				_expect(driver.button(option) == null, "寻信尚未完成就出现出发准备：%s" % option)
			await driver.press("寻找回信")
			_expect(main.state.current_stage == "前序·寻找回信结果", "第四项仍应实际显示没找到的结果")
			await create_timer(0.15).timeout
			_expect(main.state.current_stage == "前序·寻找回信结果", "未关闭结果就自动离开桌面")
		await driver.press("返回房间")
	_expect(main.state.current_stage == "前序·准备出发", "关闭第四项没有直接进入函件准备")
	for option: String in PREPARATION:
		_expect(driver.button(option) != null, "函件准备缺少原有路线：%s" % option)
	_expect(driver.button("继续") == null and driver.button("去春和戏院") == null, "四查后仍多出无意义的中转点击")
	_expect(not driver.labels().contains("唯一") and not driver.labels().contains("赵老死前还在查"), "进入函件准备时仍替玩家自动推理")
	await driver.press(PREPARATION[2])
	_expect(main.state.current_stage == "前序·出发", "选择函件路线后没有进入现有出发演出")
	_expect(main.state.condition_met("letter_preparation=left_home"), "函件准备没有记录第三条路线")
	_expect(main.state.condition_met("evidence.letter_original.holder=newsroom"), "第三条路线错误携带原件")
	main.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: DEC34 preparation timing, including letter as fourth check")
		quit(0)
	else:
		push_error("FAIL: %d prelude-transition assertions" % failures)
		quit(1)
