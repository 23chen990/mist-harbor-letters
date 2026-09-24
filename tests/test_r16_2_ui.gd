extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://scenes/r16_2_main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._render(main.runtime.enter_node("D01"))
	_expect(main.notebook_button.text == "采访本", "当前入口没有采访本入口")
	main.notebook_button.pressed.emit()
	_expect(main.notebook_panel.visible, "采访本按钮没有打开回看面板")
	main.notebook_button.pressed.emit()
	_expect(not main.notebook_panel.visible, "采访本按钮没有关闭回看面板")
	var dialogue_steps := 0
	var saw_player_response := false
	while main.runtime.pending_kind == "dialogue" and dialogue_steps < 64:
		dialogue_steps += 1
		_expect(_buttons(main).size() == 1, "U01 台词未结束时只能有一个推进按钮")
		if bool(main.runtime.last_event.get("payload", {}).get("is_player_response", false)):
			saw_player_response = true
			_expect(_buttons(main)[0].text.begins_with("沈砚舟："), "主控回应必须显示为实际台词按钮")
		_expect(not main.summary.text.contains(" / "), "U01 单句显示失败")
		_buttons(main)[0].pressed.emit()
	_expect(dialogue_steps > 5, "U01 应接入正文完整逐句对白")
	_expect(saw_player_response, "U01 应出现至少一个主控回应按钮")
	_expect(dialogue_steps < 64, "U01 逐句对白没有正常结束")
	_expect(_buttons(main).size() == 2, "U01 台词结束后应出现两个选项")
	_expect(not main.summary.text.contains(" / "), "U01 选项出现时又恢复了整段摘要")
	_buttons(main)[0].pressed.emit()
	_expect(main.runtime.pending_kind == "choice_feedback", "点击选项后缺少即时反馈")
	_expect(_buttons(main).size() == 1, "选择反馈需要独立点击继续")
	_buttons(main)[0].pressed.emit()
	_expect(main.runtime.current_node_id == "D02", "选择反馈之后应进入 U02")

	main.runtime.state.apply_mutations("liang_named_consent=1; article1_zhou_mentioned=1")
	main._render(main.runtime.enter_node("D09"))
	while main.runtime.pending_kind == "dialogue":
		_expect(not main.summary.text.contains("【若"), "U09 条件代码不能出现在台词里")
		_buttons(main)[0].pressed.emit()
	_expect(not main.summary.text.contains("【若"), "U09 条件代码不能在选择阶段重现")
	_expect(_buttons(main).size() == 2, "U09 对白结束才出现两个选择")

	main._render(main.runtime.enter_node("D15-B"))
	var starting_count: int = main.interaction.get_child_count()
	_expect(not main.summary.text.contains("→"), "排序题不应预先展示答案")
	_buttons(main)[0].pressed.emit()
	_expect(main.interaction.get_child_count() == starting_count, "点击排序卡后不应叠出另一套按钮")
	_expect(main.puzzle_selection.size() == 1, "点击排序卡只应记录一张卡")
	var reset := _find_button(main, "重新排列")
	_expect(reset != null, "排序提交前应可以重新排列")
	if reset != null:
		reset.pressed.emit()
		_expect(main.puzzle_selection.is_empty(), "重新排列必须清空当前选择")

	# Use the actual card-button signals in source order, then submit through UI.
	for card_id: String in ["A", "B", "C", "D", "E"]:
		var card := _find_button(main, main._card_text(main.current_puzzle, card_id))
		_expect(card != null, "排序卡缺失：" + card_id)
		if card != null:
			card.pressed.emit()
	var submit := _find_button(main, "提交顺序")
	_expect(submit != null and not submit.disabled, "五张卡排完后应允许提交")
	if submit != null:
		submit.pressed.emit()
	_expect(main.runtime.current_node_id == "D16", "通过 UI 提交正确顺序应进入 U16")
	_expect(main.runtime.state.get_value("medicine_chain_reconstructed", false), "通过 UI 解题应写入已完成状态")

	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: R16.2 UI dialogue-to-choice transitions, feedback, and puzzle buttons")
	quit(0 if failures == 0 else 1)


func _buttons(main: Control) -> Array[Button]:
	var result: Array[Button] = []
	for child: Node in main.interaction.get_children():
		if child is Button:
			result.append(child)
	return result


func _find_button(main: Control, text: String) -> Button:
	for button: Button in _buttons(main):
		if button.text == text:
			return button
	return null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
