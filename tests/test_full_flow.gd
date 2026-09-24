extends SceneTree

const Driver = preload("res://tests/story_test_helpers.gd")
const CLUES: Array[String] = [
	"赵敬文死亡报道 / 旧戏院草图",
	"二十年前的旧报",
	"寄给林怀安的采访函留底",
	"「春和」工作夹",
]
var failures := 0
var saw_yutang_warning := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var driver := Driver.new(main, self, _expect)
	if await driver.until_stage("前序·自由探索"):
		for clue: String in CLUES:
			if not await driver.press(clue):
				break
			if clue == "寄给林怀安的采访函留底":
				await driver.press("寻找回信")
			await driver.press("返回房间")
		_expect(main.state.current_stage == "前序·准备出发", "第四项材料关闭后没有直达函件准备")
		await driver.press("原件先不动，只记住要点")
		if await driver.until_stage("第一章·报馆换人了"):
			await _play_to_end(driver)

	_expect(main.state.demo_finished, "真实 UI 流程没有抵达 Demo 终点")
	_expect(main.state.completion_label() == "第一章结束", "C22 没有显示第一章结束")
	_expect(main.state.condition_met("chapter1_complete=true"), "C22 没有写入第一章完成状态")
	_expect(main.state.condition_met("letter_meeting_mode=oral_only"), "第三项路线见林怀安时没有保持纯口述")
	_expect(main.state.condition_met("police_record.letter_mode=oral_pending_newsroom_check"), "警方笔录没有登记为口述待核")
	_expect(main.state.condition_met("police_followup.newsroom_check=planned"), "警方没有安排之后去报馆核验")
	_expect(main.state.condition_met("evidence.letter_original.holder=newsroom"), "第三项路线错误移动了报馆原件")
	_expect(main.state.condition_met("police_record.shen_completed=true"), "全流程绕过了 C14 两个真实观察回答")
	for spoken: String in [
		"他死前还在跑春和？", "材料给我看看。这趟跑完，明天还让我接着跑吗？", "嗯。", "我接他的采访。",
		"左边怎么了？", "二十年忌，为什么还是《夜渡》？",
		"二十年前的报道说，她也是唱完《夜渡》以后出的事。", "赵敬文死前，想再向您核实一处说法。",
		"原件在报馆。正文我记得。", "没有。", "赵敬文留下的采访函。",
		"我给他看的是二十年前的旧报。是他约我散场后再谈。",
		"沈砚舟，《雾港日报》。受报馆委派，采访白素秋二十年忌演出。",
		"原件在报馆。我今晚没有带纸面，只向林怀安口述了函件内容。",
		"谢幕时我看见他自己下台。", "许先生检查过他的脖子。",
	]:
		_expect(driver.clicked_lines.has(spoken), "全流程没有实际点击主控回答：%s" % spoken)
	# v6 C10: 玉棠 turns toward the protagonist and warns him. The addressee is
	# not the speaker; this must be shown as NPC dialogue, never a player reply.
	_expect(saw_yutang_warning, "C10 没有实际展示玉棠的警告：你也别过来。")
	_expect(not driver.clicked_lines.has("你也别过来。"), "把玉棠的警告误当成主控回答按钮")
	for entry: Dictionary in main.state.choice_history:
		_expect(not str(entry.get("玩家台词", "")).contains("你也别过来。"), "玉棠的警告错误进入玩家发言历史")
	_check_visited_chapters(main, driver)
	_expect(not main.story.has_stage("第二章·开场") and not main.story.has_stage("第三章·到警署"), "完整流程仍加载旧二、三章")
	_test_debug_jumps(main)
	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: DEC34 real-button S00 and C01-C22 full flow")
		quit(0)
	else:
		push_error("FAIL: %d real-UI full-flow assertions" % failures)
		quit(1)


func _play_to_end(driver: RefCounted) -> void:
	for step_index in 400:
		if driver.main.state.demo_finished:
			return
		if driver.main.state.current_stage == "第一章·药盒落地" and driver.labels().contains("你也别过来。"):
			saw_yutang_warning = true
			_expect(driver.labels().split("\n").has("林玉棠"), "C10 警告未使用实际说话人林玉棠的标签")
		if driver.main.state.current_stage == "第一章·警方到场前" and driver.button("沿铁梯上天桥") != null:
			await driver.press("沿铁梯上天桥")
		elif not await driver.step():
			return
	_expect(false, "C01—C22 真实按钮流程超过 400 次点击")


func _check_visited_chapters(main: Control, driver: RefCounted) -> void:
	var visited_ids: Array[String] = []
	for stage: String in driver.visited_stages:
		for row: Dictionary in main.story.stage_rows(stage):
			visited_ids.append(str(row.get("自动ID", "")))
	for number in range(1, 23):
		var found := false
		for row_id: String in visited_ids:
			if row_id.begins_with("C%02d_" % number):
				found = true
				break
		_expect(found, "真实 UI 流程没有到达 C%02d" % number)


func _test_debug_jumps(main: Control) -> void:
	var destinations := {
		"序章": "前序·退稿与派活", "戏院门前": "第一章·报馆换人了",
		"林怀安采访": "第一章·纪念演出采访", "第一眼": "第一章·第一眼",
		"警方笔录": "第一章·沈砚舟的笔录", "写稿": "第一章·第一篇稿",
	}
	for label: String in destinations:
		main.debug_jump(label)
		_expect(main.state.current_stage == destinations[label], "v6 Debug 跳转失败：%s" % label)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
