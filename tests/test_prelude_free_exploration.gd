extends SceneTree

const Driver = preload("res://tests/story_test_helpers.gd")
const CLUES: Array[String] = ["「春和」工作夹", "二十年前的旧报", "寄给林怀安的采访函留底", "赵敬文死亡报道 / 旧戏院草图"]
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
	for clue: String in CLUES:
		_expect(driver.button(clue) != null, "工作桌缺少现行热点：%s" % clue)
	_expect(_hotspot_count(main) == 4, "初始工作桌热点数不是 4")
	_expect(driver.labels().contains("0 / 4"), "初始案件线索进度不是 0/4")
	_expect(driver.button("去春和戏院") == null, "未看材料就开放出发")
	for expected: String in ["赵敬文的工作桌", "靠窗空椅与桌牌", "文件柜、地图与旧报"]:
		_expect(driver.labels().contains(expected), "工作桌缺少现行场景：%s" % expected)
	for stale: String in ["沈家旧宅", "旅行箱", "父亲", "父子合照"]:
		_expect(not driver.labels().contains(stale), "工作桌仍有 v5 残留：%s" % stale)

	for index in CLUES.size():
		await driver.press(CLUES[index])
		if index == 0:
			_check_work_folder(main, driver)
		if CLUES[index] == "寄给林怀安的采访函留底":
			_expect(not main.state.knows("报馆采访函留底旁未见林怀安回函。"), "尚未主动寻信就写入回函结果")
			await driver.press("寻找回信")
		await driver.press("返回房间")
		if index < 3:
			_expect(main.state.current_stage == "前序·自由探索", "前三项材料后没有返回工作桌")
			_expect(driver.labels().contains("%d / 4" % (index + 1)), "工作桌进度没有逐项累加")
			_expect(driver.button("去春和戏院") == null, "材料未齐就出现去戏院中转")
	_expect(main.state.current_stage == "前序·准备出发", "四查后没有直接进入函件准备")
	_expect(driver.button("去春和戏院") == null and driver.button("继续") == null, "四查后仍需要额外中转点击")
	_expect(driver.visible_story_choices().size() == 3, "四查后没有同时显示三种函件准备")
	for removed: String in ["前序·证据收束", "前序·意识到缺口", "前序·决定见面"]:
		_expect(not driver.visited_stages.has(removed), "四查后仍进入已删除的自动推断：%s" % removed)
	main.queue_free()
	await process_frame
	_finish()


func _check_work_folder(main: Control, driver: RefCounted) -> void:
	_expect(main.state.current_stage == "前序·春和工作夹", "工作夹仍进入旧教学页")
	for expected: String in ["春和戏院", "二十年忌", "冬月初七晚八时开锣", "纪念白素秋逝世二十周年", "林怀安领衔《夜渡》"]:
		_expect(driver.labels().contains(expected), "工作夹缺少演出安排：%s" % expected)
	for removed: String in ["戏班换角", "教学", "谁亲眼看见", "谁只是听说"]:
		_expect(not driver.labels().contains(removed), "工作夹恢复了旧教学文字：%s" % removed)
	_expect(not main.state.condition_met("tutorial_angle_change_done=true"), "查看工作夹写入旧教学完成状态")
	_expect(not "赵敬文采访方法" in "\n".join(main.state.knowledge_lines()), "工作夹把旧教学说明写入知识")
	_expect(main.state.has_record("已查看春和工作夹"), "查看工作夹没有写入现行记录")
	_expect(not main.state.has_record("已查看旧采访本"), "工作夹仍写入旧采访本记录")


func _hotspot_count(main: Control) -> int:
	var count := 0
	for node: Node in main.canvas.find_children("*", "Button", true, false):
		if bool(node.get_meta("scene_exploration_hotspot", false)):
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: DEC34 four newsroom checks go directly to letter preparation")
		quit(0)
	else:
		push_error("FAIL: %d newsroom exploration assertions" % failures)
		quit(1)
