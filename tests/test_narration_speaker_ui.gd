extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main: Control = packed.instantiate()
	root.add_child(main)
	await process_frame

	# 动作解析独立于正式开场的台词与长度。
	var beats: Array[Dictionary] = main._screenplay_presentation_beats("版面编辑夹着排好的版样。\n编辑：「这句是编辑说的。」\n沈砚舟把稿子往前推了一寸。\n沈砚舟：「这句是我的回答。」", "编辑")
	_expect(beats.size() == 2, "动作混入了人物对白节拍")
	for beat: Dictionary in beats:
		_expect(str(beat.get("speaker", "")) != "场景", "场景动作仍被生成成对话节拍")
		_expect(_is_spoken_line(str(beat.get("text", ""))), "对话节拍混入了没有说出口的动作")
		_expect(not (beat.get("scene_actions", []) as Array).is_empty(), "发言前的动作没有转成背景 UI 状态")
	if beats.size() == 2:
		_expect(str(beats[0].get("speaker", "")) == "编辑" and str(beats[1].get("speaker", "")) == "沈砚舟", "动作行导致发言人识别错误")
	var trailing_action_beats: Array[Dictionary] = main._screenplay_presentation_beats("编辑：\n「拿去重写。」\n编辑收走版样。", "编辑")
	_expect(trailing_action_beats.size() == 2, "末句后的场景动作被静默丢失")
	if trailing_action_beats.size() == 2:
		_expect(not bool(trailing_action_beats[1].get("dialogue_visible", true)), "纯背景动作仍要求显示空对话框")
		_expect(not (trailing_action_beats[1].get("scene_actions", []) as Array).is_empty(), "末句后的场景动作没有生成背景 UI 状态")

	var initial_text := _canvas_text(main)
	_expect("编辑" in initial_text and "[ 编辑立绘 ]" in initial_text, "开场没有呈现编辑身份与立绘")
	_expect(not "场景" in initial_text, "对话框仍显示场景说话者")
	_expect(not "版面编辑抽走" in initial_text, "场景动作文字仍被放进对话框")
	_expect(_nodes_with_meta(main.canvas, "scene_action_ui").size() >= 2, "开场动作没有由背景 UI 元素表现")
	var response := _player_response(main)
	_expect(response != null and _canvas_button(main, "继续") == null, "编辑说完后没有用主控回答承接")
	if response != null:
		var chosen_text := response.text
		response.pressed.emit()
		await process_frame
		var following_text := _canvas_text(main)
		_expect("编辑" in following_text, "点击主控回答之后没有显示编辑反应")
		_expect(not chosen_text in following_text, "点击后重复显示主控已说出的台词")

	# v6 的纯画面与无对白动作必须留在场景层，不能制造“系统/场景在说话”的对话框。
	main._go_to_stage("第一章·第一眼")
	await process_frame
	_expect(not _has_dialogue_panel(main.canvas), "C09 纯画面仍显示下屏对话框")
	_expect(not _canvas_text(main).contains("[ 画面演出占位 ]"), "C09 纯画面仍显示技术占位文字")
	_expect(_canvas_button(main, "看林怀安") != null, "C09 纯画面末帧没有直接显示第一眼选项")
	_expect(_nodes_with_meta(main.canvas, "scene_action_ui").size() > 0, "C09 的倒地现场没有转成背景 UI")

	main.state.apply_result("letter_preparation=copied")
	main._go_to_stage("第一章·沈砚舟的笔录")
	await process_frame
	var copied_beats: Array[Dictionary] = main._presentation_beats(main.story.available_presentations(main.state.current_stage, main.state))
	var copied_spoken := ""
	for beat: Dictionary in copied_beats:
		if bool(beat.get("dialogue_visible", true)):
			copied_spoken += str(beat.get("text", "")) + " "
	_expect(not copied_spoken.contains("警员把正文"), "C14 抄录登记的场景说明仍被当成沈砚舟对白")
	_expect_authored_speaker(main, "C03_070", "前场催灯了，你还磨蹭。", "陈九生")
	_expect_authored_speaker(main, "C03_070", "站线外。", "陈九生")
	_expect_authored_speaker(main, "C08_020", "爹！", "林玉棠")
	_expect_authored_speaker(main, "C10_001", "先别动。", "许济川")
	_expect_authored_speaker(main, "C10_001", "你也别过来。", "林玉棠")
	_expect_authored_speaker(main, "C11_001", "听说又是旧疾。", "有人")
	_expect_authored_speaker(main, "C11_001", "不是，刚才有个记者拿旧事来问他。", "另一人")

	main.queue_free()
	await process_frame
	_finish()


func _expect_authored_speaker(main: Control, row_id: String, line: String, expected_speaker: String) -> void:
	for row: Dictionary in main.story.rows:
		if str(row.get("自动ID", "")) != row_id:
			continue
		var rows: Array[Dictionary] = [row]
		for beat: Dictionary in main._presentation_beats(rows):
			if str(beat.get("text", "")) != "「%s」" % line:
				continue
			_expect(str(beat.get("speaker", "")) == expected_speaker, "%s 台词说话人错误，应为 %s：%s" % [row_id, expected_speaker, line])
			_expect(not bool(beat.get("player_response", false)), "%s NPC台词错误显示为玩家发言：%s" % [row_id, line])
			return
	_expect(false, "%s 缺少待核对台词：%s" % [row_id, line])


func _canvas_text(main: Control) -> String:
	var lines: Array[String] = []
	for node: Node in main.canvas.find_children("*", "Label", true, false):
		var label := node as Label
		if label != null and not label.text.is_empty():
			lines.append(label.text)
	return "\n".join(lines)


func _canvas_button(main: Control, text_value: String) -> Button:
	for node: Node in main.canvas.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.text == text_value:
			return button
	return null


func _player_response(main: Control) -> Button:
	for node: Node in main.canvas.find_children("*", "Button", true, false):
		var button := node as Button
		if button.has_meta("player_response"):
			return button
	return null


func _nodes_with_meta(parent: Node, meta_name: StringName) -> Array[Node]:
	var matches: Array[Node] = []
	for node: Node in parent.find_children("*", "Control", true, false):
		if node.has_meta(meta_name):
			matches.append(node)
	return matches


func _has_dialogue_panel(parent: Node) -> bool:
	for node: Node in parent.find_children("*", "Panel", true, false):
		var panel := node as Panel
		if panel != null and panel.position.is_equal_approx(Vector2(70, 344)) and panel.size.is_equal_approx(Vector2(1140, 325)):
			return true
	return false


func _is_spoken_line(text_value: String) -> bool:
	return (text_value.begins_with("「") and text_value.ends_with("」")) or (text_value.begins_with("『") and text_value.ends_with("』"))


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: narration speaker UI")
		quit(0)
		return
	push_error("FAIL: %d narration-speaker assertions" % failures)
	quit(1)
