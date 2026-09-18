extends SceneTree

var failures := 0
var main: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	_add_stage("测试·回答", [_row("REPLY", "测试·回答", "编辑", "编辑：「问题一？」\n沈砚舟：「回答一。」\n沈砚舟：「补充一句。」\n编辑：「问题二？」\n沈砚舟：「回答二。」", "测试·结束"), _choice("AUTHORED", "测试·回答", "我现在去。", "测试·结束")])
	_add_stage("测试·结束", [_row("END", "测试·结束", "编辑", "编辑：「对话已结束。」", "")])
	_add_stage("测试·跨段问句", [_row("QUESTION", "测试·跨段问句", "编辑", "编辑：「跨段的问题？」", "测试·首句主控")])
	_add_stage("测试·首句主控", [_row("FIRST", "测试·首句主控", "沈砚舟", "沈砚舟：「跨段的回答。」", "测试·结束")])
	_add_stage("测试·条件", [_row("A", "测试·条件", "编辑", "编辑：「条件甲？」\n沈砚舟：「答甲。」", "测试·结束", "test_route=a"), _row("B", "测试·条件", "编辑", "编辑：「条件乙？」\n沈砚舟：「答乙。」", "测试·结束", "test_route=b")])
	var inner := _row("INNER", "测试·内心", "沈砚舟", "「这只是心里想的话。」", "测试·结束")
	inner["内容类型"] = "内心"
	inner["是否说出口"] = "否"
	_add_stage("测试·内心", [inner])
	var material := _row("MATERIAL", "测试·材料", "沈砚舟", "「材料中的引文。」", "测试·结束")
	material["内容类型"] = "线索查看"
	material["是否说出口"] = "否"
	_add_stage("测试·材料", [material])

	await _test_response_and_backtracking()
	await _test_first_and_last_response()
	await _test_conditions_and_nonspoken()
	await _test_stale_continue()
	await _test_reset()
	await _test_entry_condition_snapshot()
	await _test_speaker_cues()
	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: player response UI")
		quit(0)
	else:
		push_error("FAIL: %d player-response assertions" % failures)
		quit(1)


func _test_response_and_backtracking() -> void:
	main._restart()
	main._go_to_stage("测试·回答")
	await process_frame
	_expect(_labels().contains("问题一？"), "待回答时没有保留 NPC 问句")
	_expect(not _labels().contains("回答一。"), "未点击的主控回答已经作为对白播出")
	_expect(_button("继续") == null, "主控需要回答时仍显示继续")
	_expect(main.state.choice_history.is_empty(), "未点击的主控回答写入了历史")
	for _frame in 3:
		await process_frame
	main._advance_presentation_beat()
	main.advance_story()
	await process_frame
	_expect(main.state.current_stage == "测试·回答" and _labels().contains("问题一？"), "继续越过了待选主控回答")
	var first_reply := _response("回答一。")
	_expect(first_reply != null, "NPC 问句后没有显示实际回答按钮")
	if first_reply == null:
		return
	_expect(first_reply.position.x > 640, "主控回答没有位于右侧选项区")
	first_reply.pressed.emit()
	first_reply.pressed.emit()
	await process_frame
	_expect(main.state.choice_history.size() == 1, "过期回答按钮被重复记录")
	_expect(main.state.last_spoken_line.contains("回答一。"), "点击主控回答没有记录说出口台词")
	_expect(_response("补充一句。") != null, "连续主控台词没有逐次显示回答按钮")
	_expect(_labels().contains("问题一？") and not _labels().contains("回答一。"), "连续主控句没有保留 NPC 上下文，或重复播放了已说的回答")
	await _press_response("补充一句。")
	_expect(_labels().contains("问题二？"), "点击回答后没有直接进入下一句 NPC")
	_expect(_response("回答二。") != null and _button("继续") == null, "第二个问题没有直接给出主控回答")
	main.return_to_previous_choice()
	await process_frame
	_expect(_labels().contains("问题一？") and _response("补充一句。") != null, "回退没有回到对应问题与第二句回应")
	_expect(main.state.choice_history.size() == 1, "回退没有撤销被点击的补充回答")
	await _press_response("补充一句。")
	await _press_response("回答二。")
	_expect(_button("我现在去。") != null, "末尾主控回答之后没有立即显示 authored 选项")
	_expect(_button("继续") == null and not _labels().contains("回答二。"), "末尾主控回答被重复播放或要求额外继续")
	var authored := _button("我现在去。")
	if authored != null:
		_expect(authored.has_meta("player_response"), "说出口的 authored 选项没有标记为主控回答")
		authored.pressed.emit()
		await process_frame
		main.return_to_previous_choice()
		await process_frame
		_expect(_button("我现在去。") != null and _response("回答二。") == null, "回退 authored 选项重播了已点击的末尾主控句")
	main.return_to_previous_choice()
	await process_frame
	_expect(_labels().contains("问题二？") and _response("回答二。") != null, "回退末尾回应没有恢复对应问题")
	_expect(main.state.choice_history.size() == 2, "回退末尾回应后历史数量错误")


func _test_first_and_last_response() -> void:
	main._restart()
	main._go_to_stage("测试·跨段问句")
	await process_frame
	var next := _button("继续")
	if next != null:
		next.pressed.emit()
	await process_frame
	_expect(main.state.current_stage == "测试·首句主控", "没有进入首句为主控的阶段")
	_expect(_labels().contains("跨段的问题？"), "首句主控未保留上一阶段 NPC 问句")
	_expect(not _labels().contains("跨段的回答。"), "首句主控在点击前已播出")
	await _press_response("跨段的回答。")
	_expect(main.state.current_stage == "测试·结束", "阶段末尾主控点击后未直接进入后继阶段")
	main.return_to_previous_choice()
	await process_frame
	_expect(_labels().contains("跨段的问题？") and _response("跨段的回答。") != null, "跨阶段回退丢失了 NPC 问句")
	_expect(main.state.choice_history.is_empty(), "跨阶段回退没有撤销发言")


func _test_conditions_and_nonspoken() -> void:
	main._restart()
	main.state.apply_result("test_route=b")
	main._go_to_stage("测试·条件")
	await process_frame
	_expect(_response("答乙。") != null and _response("答甲。") == null, "条件分支回答没有按当前状态筛选")
	await _press_response("答乙。")
	_expect(main.state.last_spoken_line.contains("答乙。"), "条件分支实际发言没有入历史")
	main._go_to_stage("测试·内心")
	await process_frame
	_expect(_response("这只是心里想的话。") == null and _button("继续") != null, "内心独白被当作说出口的回答")
	main._go_to_stage("测试·材料")
	await process_frame
	_expect(_response("材料中的引文。") == null and _button("返回房间") != null, "材料引文被当作说出口的回答")


func _test_stale_continue() -> void:
	_add_stage("测试·旧按钮", [_row("OLD", "测试·旧按钮", "编辑", "编辑：「前一句。」\n编辑：「当前问题？」\n沈砚舟：「我来回答。」", "测试·结束")])
	main._go_to_stage("测试·旧按钮")
	await process_frame
	var old_continue := _button("继续")
	_expect(old_continue != null, "NPC 连续对白缺少继续")
	if old_continue == null:
		return
	old_continue.pressed.emit()
	old_continue.pressed.emit()
	await process_frame
	_expect(_labels().contains("当前问题？") and _response("我来回答。") != null, "同帧过期继续按钮越过了主控回答")


func _test_reset() -> void:
	main._go_to_stage("测试·回答")
	await process_frame
	await _press_response("回答一。")
	main._restart()
	await process_frame
	_expect(main.state.choice_history.is_empty() and main._choice_checkpoints.is_empty(), "重新开始没有清除回答与回退历史")
	_expect(not _labels().contains("问题一？") and _response("补充一句。") == null, "重新开始后残留旧问题与回答")
	main._go_to_stage("测试·回答")
	await process_frame
	await _press_response("回答一。")
	main.switch_to_chapter("第一章")
	await process_frame
	_expect(main.state.choice_history.is_empty() and main._choice_checkpoints.is_empty(), "章节切换没有清除回答与回退历史")
	_expect(not _labels().contains("问题一？") and _response("补充一句。") == null, "章节切换残留旧问题与回答")


func _test_entry_condition_snapshot() -> void:
	main._restart()
	var admitted := _row("ADMITTED", "测试·入口自我失效", "编辑", "编辑：「这张纸是你的？」\n沈砚舟：「是我的。」", "测试·结束", "test_holder=lin")
	admitted["状态写入（不显示）"] = "test_holder=police"
	_add_stage("测试·入口自我失效", [admitted])
	main.state.apply_result("test_holder=lin")
	main._go_to_stage("测试·入口自我失效")
	await process_frame
	_expect(main.state.condition_met("test_holder=police"), "入口效果没有按既有规则执行")
	_expect(_labels().contains("这张纸是你的？") and _response("是我的。") != null, "入口效果使刚选中的呈现行自我失效")
	await _press_response("是我的。")
	_expect(main.state.current_stage == "测试·结束", "自我失效的入口行丢失了下一话题")
	main.return_to_previous_choice()
	await process_frame
	_expect(main.state.condition_met("test_holder=police"), "回退错误撤销了早于本次选择的入口效果")
	_expect(_labels().contains("这张纸是你的？") and _response("是我的。") != null, "回退没有恢复当时入场选中的呈现行")

	main._restart()
	var selected := _row("SELECTED", "测试·顺序路由", "编辑", "编辑：「先命中的出口。」\n沈砚舟：「采用这条。」", "测试·结束", "test_route is unset")
	selected["状态写入（不显示）"] = "test_route=selected"
	var fallback := _row("FALLBACK", "测试·顺序路由", "编辑", "编辑：「不应出现的兜底。」", "测试·结束", "test_route is unset")
	fallback["状态写入（不显示）"] = "test_route=fallback"
	_add_stage("测试·顺序路由", [selected, fallback])
	main._go_to_stage("测试·顺序路由")
	await process_frame
	_expect(main.state.condition_met("test_route=selected"), "冻结呈现改变了按顺序执行入口条件的行为")
	_expect(_labels().contains("先命中的出口。") and not _labels().contains("不应出现的兜底。"), "冻结呈现同时选中了应失效的兜底行")
	await _press_response("采用这条。")
	_expect(main.state.current_stage == "测试·结束", "顺序路由没有保留唯一出口")


func _test_speaker_cues() -> void:
	var cue_row := _row("CUES", "测试·说话人", "阿成", "陈九生把提灯塞给阿成：「这句由陈九生说。」\n陈九生：「还是陈九生。」\n玉棠想扶林怀安，许济川挡开：「这句由许济川说。」\n林玉棠转向沈砚舟：「你也别过来。」\n沈砚舟：「这句才是主控回答。」", "测试·结束")
	_add_stage("测试·说话人", [cue_row])
	var cue_rows: Array[Dictionary] = [cue_row]
	var beats: Array[Dictionary] = main._presentation_beats(cue_rows)
	var expected_speakers: Array[String] = ["陈九生", "陈九生", "许济川", "林玉棠", "沈砚舟"]
	_expect(beats.size() == expected_speakers.size(), "动作引导中的主语或受话者改变了台词数量")
	for index in mini(beats.size(), expected_speakers.size()):
		_expect(str(beats[index].get("speaker", "")) == expected_speakers[index], "动作引导台词说话人错误：%s，应为 %s" % [str(beats[index].get("text", "")), expected_speakers[index]])
		_expect(bool(beats[index].get("player_response", false)) == (expected_speakers[index] == "沈砚舟"), "NPC 对主控的话被误标为主控回答")
	main._go_to_stage("测试·说话人")
	await process_frame
	var guard := 0
	while not _labels().contains("你也别过来。") and guard < 8:
		var next := _button("继续")
		if next == null:
			break
		next.pressed.emit()
		await process_frame
		guard += 1
	_expect(_labels().contains("你也别过来。") and _labels().contains("林玉棠"), "NPC 对主控说的话没有由 NPC 呈现")
	_expect(_response("你也别过来。") == null and _response("这句才是主控回答。") != null, "真实 UI 把受话者当作说话人")

	var guest := _row("NEW_CUE", "测试·新cue人物", "编辑", "来客：「这是明确的说话人标签。」\n来客转向沈砚舟：「这句仍由来客说。」", "测试·结束")
	_add_stage("测试·新cue人物", [guest])
	var guest_rows: Array[Dictionary] = [guest]
	var guest_beats: Array[Dictionary] = main._presentation_beats(guest_rows)
	for beat: Dictionary in guest_beats:
		_expect(str(beat.get("speaker", "")) == "来客" and not bool(beat.get("player_response", false)), "明确脚本 cue 未补入人物词表，或动作中的受话者抢走发言")


func _row(id: String, stage: String, speaker: String, source: String, next_stage: String, condition := "始终") -> Dictionary:
	return {"自动ID": id, "对话阶段": stage, "场景": "测试用场景", "人物": speaker, "话题": stage, "内容类型": "NPC台词", "NPC台词": source, "玩家可选台词": "", "出现条件": condition, "下一话题": next_stage, "是否说出口": "是"}


func _choice(id: String, stage: String, line: String, next_stage: String) -> Dictionary:
	var row := _row(id, stage, "沈砚舟", "", next_stage)
	row["内容类型"] = "玩家选项"
	row["玩家可选台词"] = line
	return row


func _add_stage(stage: String, rows: Array[Dictionary]) -> void:
	main.story.rows.append_array(rows)
	main.story._stages[stage] = rows


func _press_response(fragment: String) -> void:
	var button := _response(fragment)
	_expect(button != null, "缺少主控回答：%s" % fragment)
	if button != null:
		button.pressed.emit()
		await process_frame


func _response(fragment: String) -> Button:
	for node: Node in main.canvas.find_children("*", "Button", true, false):
		var button := node as Button
		if button.has_meta("player_response") and button.text.contains(fragment):
			return button
	return null


func _button(text_value: String) -> Button:
	for node: Node in main.canvas.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text == text_value:
			return button
	return null


func _labels() -> String:
	var parts: Array[String] = []
	for node: Node in main.canvas.find_children("*", "Label", true, false):
		parts.append((node as Label).text)
	return "\n".join(parts)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
