extends SceneTree

const Driver = preload("res://tests/story_test_helpers.gd")
const COMMON := "第一章·纪念演出采访"
const LETTER := "第一章·纪念演出采访·函件"
const DISCLOSURE := "第一章·纪念演出采访·材料透露"
const HANDLING := "第一章·纪念演出采访·原件处理"
const POLICE := "第一章·沈砚舟的笔录"
const LAST_SEEN := "第一章·沈砚舟的笔录·共同问题"
const FIRST_LOOK := "第一章·沈砚舟的笔录·第一眼回答"
const DISCLOSE := "一张旧报，一张戏院草图，还有这份留底。"
const WITHHOLD := "先谈这封信。您回过吗？"
const PREPARATION := {
	"original_carried": "带上采访函留底",
	"copied": "抄下函件正文",
	"left_home": "原件先不动，只记住要点",
}
const C07 := {
	"audience": ["观众席侧边", "谢幕时，我看见他自己下台，脚步还稳。"],
	"side": ["台侧外围", "谢幕时，他沿侧台通道中央往侧厅走。"],
	"front": ["前场", "我当时在前场，没看见他从哪儿退场。"],
	"orchestra": ["乐池外围", "我当时在乐池外围，没看见他从哪儿退场。"],
}
const C09 := {
	"lin": ["看林怀安", "许先生的手指在他颈侧停了一瞬，随后拉回了护领。"],
	"position": ["看倒下的位置", "他倒在岔口靠墙的地方。"],
	"people": ["看周围的人", "阿成先看玉棠。陈九生随后从侧台另一端赶回来。"],
}
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for disclosure: String in [DISCLOSE, WITHHOLD]:
		for leave_original: bool in [true, false]:
			await _original_route(disclosure, leave_original)
	await _non_original_route("copied")
	await _non_original_route("left_home")
	for position: String in C07:
		for first_look: String in C09:
			await _observation_answers(position, first_look)
	await _unseen_observation_has_no_answer()
	if failures == 0:
		print("PASS: C04 disclosure/custody, three paper routes, and 12 C14 observation combinations via UI")
		quit(0)
	else:
		push_error("FAIL: %d interview disclosure assertions" % failures)
		quit(1)


func _new_main() -> Control:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	return main


func _dispose(main: Control) -> void:
	main.queue_free()
	await process_frame


func _prepare(driver: RefCounted, preparation: String) -> bool:
	# Isolate the interview with a read letter as a precondition, then use the
	# actual S02 button and read C01-C04 through visible UI.
	driver.main.state.apply_result("letter_read=true")
	driver.main._go_to_stage("前序·准备出发")
	await process_frame
	if not await driver.press(str(PREPARATION[preparation])):
		return false
	if not await driver.until_stage(COMMON):
		return false
	_expect(not driver.main.state.condition_met("lin_received_zhao_letter=true"), "公共采访尚未谈函就记录林已收函")
	_expect(driver.button(DISCLOSE) == null and driver.button(WITHHOLD) == null, "材料透露选项在公共采访结束前提前出现")
	return await driver.until_stage(LETTER)


func _original_route(disclosure: String, leave_original: bool) -> void:
	var main: Control = await _new_main()
	var driver := Driver.new(main, self, _expect)
	if not await _prepare(driver, "original_carried"):
		await _dispose(main)
		return
	_expect(driver.labels().contains("他寄来的那份，我收到了。"), "原件路径没有显示林承认收函")
	_expect(main.state.condition_met("lin_received_zhao_letter=true"), "玩家看到林承认收函后没有记录")
	if not await driver.press_response("留底旁没找到您的回信。"):
		await _dispose(main)
		return
	_expect(main.state.current_stage == DISCLOSURE, "有限范围寻信陈述没有进入材料反问")
	_expect(driver.labels().contains("他桌上还留了什么？"), "林没有当场反问桌上材料")
	_expect(driver.response_buttons().size() == 2, "材料透露节点不应缺少选项或强造第三种回应")
	_expect(driver.button("继续") == null, "材料透露节点可被继续跳过")
	_expect(driver.button("把函件暂时留给林怀安") == null, "还未回应反问就允许处理原件")
	_expect(not main.state.condition_met("lin_disclosure=materials") and not main.state.condition_met("lin_disclosure=letter_only"), "未选就记录材料披露范围")
	var before_history: int = main.state.choice_history.size()
	if not await driver.press_response(disclosure):
		await _dispose(main)
		return
	var expected_reply := "旧报和图也带来。演完，在侧厅等我。" if disclosure == DISCLOSE else "信的事，散场后再说。到侧厅等我。"
	var other_reply := "信的事，散场后再说。到侧厅等我。" if disclosure == DISCLOSE else "旧报和图也带来。演完，在侧厅等我。"
	_expect(driver.labels().contains(expected_reply), "透露取舍没有对应的当场回应：%s" % disclosure)
	_expect(not driver.labels().contains(other_reply), "透露路线混入另一条林的回应")
	_expect(main.state.condition_met("evidence.letter_original.holder=player"), "透露材料自动转移了采访函原件")
	_expect(main.state.condition_met("lin_disclosure=materials" if disclosure == DISCLOSE else "lin_disclosure=letter_only"), "透露范围没有记录实际选择")
	# The authored spoken choice must backtrack together with its disclosure state.
	await driver.press("测试：返回上一级选择")
	_expect(main.state.current_stage == DISCLOSURE, "撤销透露没有回到林的反问")
	_expect(main.state.choice_history.size() == before_history, "撤销透露仍保留旧发言历史")
	_expect(not main.state.condition_met("lin_disclosure=materials") and not main.state.condition_met("lin_disclosure=letter_only"), "撤销透露没有回滚披露状态")
	await driver.press_response(disclosure)
	if not await driver.until_stage(HANDLING):
		await _dispose(main)
		return
	_expect(driver.visible_story_choices().size() == 2, "两种透露之后都必须可独立交出或收回原件")
	await driver.press("把函件暂时留给林怀安" if leave_original else "让他看完后收回")
	_expect(main.state.condition_met("evidence.letter_original.holder=lin" if leave_original else "evidence.letter_original.holder=player"), "原件处理没有按实际选择转移")
	if await _reach_police(driver):
		var deliver_to_police := not leave_original and disclosure == WITHHOLD
		if not leave_original:
			var police_choice := "交出采访函留底" if deliver_to_police else "逐字说明函件内容，保留原件"
			if await driver.until_button(police_choice):
				await driver.press(police_choice)
		if await driver.until_stage(LAST_SEEN):
			var letter_mode := "original_seized" if leave_original else ("original_delivered" if deliver_to_police else "oral_with_original_held")
			_expect(main.state.condition_met("police_record.letter_mode=%s" % letter_mode), "C14 原件路线笔录状态错误")
			_expect(main.state.condition_met("evidence.letter_original.holder=police" if leave_original or deliver_to_police else "evidence.letter_original.holder=player"), "C14 错误改变原件持有人")
			if leave_original:
				_expect(driver.clicked_lines.has("是。赵敬文死前寄过采访函，报馆留了底。"), "警方从林身上取得原件后跳过了主控确认发言")
				_expect(driver.clicked_lines.has("让我散场后到侧厅等他。"), "警方取得原件后跳过了散场约见回答")
				_expect("\n".join(driver.seen_text).contains("这份是你带来的？"), "警方取得原件后没有实际显示追问")
			await _answer_observations(driver, "audience", "lin")
	var transcript := "\n".join(driver.seen_text)
	_expect(not transcript.contains("您没有回。"), "采访仍把报馆未见回函升级为对方没有回信")
	_expect(not transcript.contains("他没有回信") and not transcript.contains("他已经回信"), "回避被升级为回函存在性结论")
	await _dispose(main)


func _non_original_route(preparation: String) -> void:
	var main: Control = await _new_main()
	var driver := Driver.new(main, self, _expect)
	if not await _prepare(driver, preparation):
		await _dispose(main)
		return
	if preparation == "copied":
		_expect(driver.labels().contains("原件呢？"), "抄录路线没有询问原件位置")
		await driver.press_response("在报馆。")
		_expect(driver.labels().contains("把他桌上还有什么，一样一样说给我听。"), "抄录路线缺少对应续约")
	else:
		await driver.press_response("原件在报馆。正文我记得。")
		_expect(driver.labels().contains("把信里写了什么，一样一样说给我听。"), "无纸面路线没有保持口述续约")
	_expect(not main.state.condition_met("lin_received_zhao_letter=true"), "非原件路线自动获得林承认收函")
	_expect(main.state.condition_met("evidence.letter_original.holder=newsroom"), "非原件路线移动了报馆原件")
	if await driver.until_stage("第一章·开锣前") and await _reach_police(driver):
		if await driver.until_stage(LAST_SEEN):
			if preparation == "copied":
				_expect(main.state.condition_met("police_record.letter_mode=copy_recorded"), "抄录路线未登记为只核到抄录")
				_expect(main.state.condition_met("evidence.letter_copy.exists=true and evidence.letter_copy.holder=player"), "抄录路线丢失抄页")
			else:
				_expect(main.state.condition_met("letter_meeting_mode=oral_only"), "无纸面路线未保持纯口述")
				_expect(main.state.condition_met("police_record.letter_mode=oral_pending_newsroom_check"), "无纸面路线笔录没有登记为口述待核")
				_expect(main.state.condition_met("police_followup.newsroom_check=planned"), "无纸面路线警方没有计划核验报馆原件")
				_expect(main.state.condition_met("evidence.letter_copy.exists=false"), "无纸面路线自动生成抄页")
			await _answer_observations(driver, "audience", "lin")
	_expect(not driver.visited_stages.has(DISCLOSURE) and not driver.visited_stages.has(HANDLING), "非原件路线闯入透露/交原件节点")
	_expect(not "\n".join(driver.seen_text).contains("他桌上还留了什么？"), "非原件路线自动获得原件路径反问")
	_expect(not main.state.condition_met("lin_disclosure=materials") and not main.state.condition_met("lin_disclosure=letter_only"), "非原件路线记录了未做过的透露选择")
	_expect(main.state.condition_met("evidence.letter_original.holder=newsroom"), "C14 非原件路线让警方当晚取得原件")
	await _dispose(main)


func _reach_police(driver: RefCounted) -> bool:
	# From C05 onward this is a real player route, including two separate public
	# observations, C07, C09, and the protagonist's C08/C10/C11 replies.
	return await driver.until_stage(POLICE, 240, true)


func _observation_answers(position: String, first_look: String) -> void:
	var main: Control = await _new_main()
	var driver := Driver.new(main, self, _expect)
	# Establish both observations by their real UI choices. Only the time between
	# independent observations is skipped for this 4 x 3 answer matrix.
	main._go_to_stage("第一章·谢幕前后")
	await process_frame
	await driver.press(str(C07[position][0]))
	main._go_to_stage("第一章·第一眼")
	await process_frame
	await driver.press(str(C09[first_look][0]))
	main._go_to_stage(LAST_SEEN)
	await process_frame
	await _answer_observations(driver, position, first_look)
	await _dispose(main)


func _answer_observations(driver: RefCounted, position: String, first_look: String) -> void:
	_expect(driver.labels().contains("你最后一次看见林怀安在哪里？"), "C14 没有先显示最后所见问题")
	_expect(driver.response_buttons().size() == 1, "C14 必须只允许点击玩家实际观察过的一句回答")
	_expect(not driver.main.state.condition_met("police_record.last_seen_basis=%s" % position), "C14 未回答就登记了最后所见")
	for candidate: String in C07:
		_expect((driver.button(str(C07[candidate][1])) != null) == (candidate == position), "C14 最后所见泄露未选观察：%s / %s" % [position, candidate])
	if not await driver.press_response(str(C07[position][1])):
		return
	_expect(driver.main.state.current_stage == FIRST_LOOK, "回答最后所见后没有进入第一眼问题")
	_expect(driver.labels().contains("赶到以后，第一眼看见什么？"), "C14 没有显示第一眼问题")
	_expect(driver.response_buttons().size() == 1, "C14 第一眼没有限定为实际看见的一项")
	_expect(not driver.main.state.condition_met("police_record.shen_completed=true"), "第一眼回答前就把笔录标为完成")
	for candidate: String in C09:
		_expect((driver.button(str(C09[candidate][1])) != null) == (candidate == first_look), "C14 第一眼泄露未选观察：%s / %s" % [first_look, candidate])
	await driver.press_response(str(C09[first_look][1]))
	_expect(driver.main.state.condition_met("police_record.last_seen_basis=%s" % position), "笔录最后所见没有记录实际依据")
	_expect(driver.main.state.condition_met("police_record.first_look_basis=%s" % first_look), "笔录第一眼没有记录实际依据")
	_expect(driver.main.state.condition_met("police_record.shen_completed=true"), "两个实际回答后笔录没有完成")


func _unseen_observation_has_no_answer() -> void:
	var main: Control = await _new_main()
	var driver := Driver.new(main, self, _expect)
	for stage: String in [LAST_SEEN, FIRST_LOOK]:
		main._go_to_stage(stage)
		await process_frame
		_expect(driver.response_buttons().is_empty(), "没有观察状态时 C14 自动补造一条回答：%s" % stage)
		_expect(not main.state.condition_met("police_record.shen_completed=true"), "缺少观察状态时自动完成笔录")
	await _dispose(main)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
