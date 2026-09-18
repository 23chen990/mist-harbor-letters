extends SceneTree

const Driver = preload("res://tests/story_test_helpers.gd")
const GameStateScript = preload("res://scripts/game_state.gd")
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_natural_language_story_state()
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var driver := Driver.new(main, self, _expect)
	_expect(main.state.current_stage == "前序·退稿与派活", "Demo 没有从 v6 报馆开场开始")
	if await driver.until_stage("前序·自由探索"):
		for expected: String in ["「春和」工作夹", "二十年前的旧报", "寄给林怀安的采访函留底", "赵敬文死亡报道 / 旧戏院草图"]:
			_expect(driver.button(expected) != null, "工作桌缺少现行热点：%s" % expected)
		for removed: String in ["旅行箱", "父亲最后寄出的信", "书信夹"]:
			_expect(driver.button(removed) == null, "工作桌仍出现 v5 热点：%s" % removed)
	# Isolate the existing no-paper interview route; the opening above and its
	# protagonist replies were already exercised with actual visible buttons.
	main.state.apply_result("letter_preparation=left_home; evidence.letter_original.holder=newsroom")
	main._go_to_stage("第一章·纪念演出采访")
	await process_frame
	if await driver.until_stage("第一章·纪念演出采访·函件"):
		await driver.press_response("原件在报馆。正文我记得。")
		_expect(driver.labels().contains("把信里写了什么，一样一样说给我听。"), "林怀安没有要求之后口述")
		_expect(not main.state.condition_met("lin_received_zhao_letter=true"), "无纸面路线自动获得原件路径的收函证词")
		_expect(main.state.condition_met("evidence.letter_original.holder=newsroom"), "无纸面路线移动了报馆原件")
	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: DEC34 opening logic and oral-only interview UI")
		quit(0)
	else:
		push_error("FAIL: %d opening-demo assertions" % failures)
		quit(1)


func _test_natural_language_story_state() -> void:
	var state = GameStateScript.new()
	state.apply_result("letter_preparation=left_home")
	_expect(state.condition_met("letter_preparation=left_home"), "不能判断第三项函件准备状态")
	_expect("信件准备：原件留在报馆，无纸面材料" in state.story_state_lines(), "Debug 仍把第三项写成父亲留底")
	state.reset()
	_expect(not state.condition_met("letter_preparation=left_home"), "重置后仍保留第三项状态")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
