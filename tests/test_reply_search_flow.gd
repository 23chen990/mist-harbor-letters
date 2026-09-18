extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main: Control = packed.instantiate()
	root.add_child(main)
	await process_frame
	main._go_to_stage("前序·自由探索")
	await process_frame

	var letter_row := _choice(main, "寄给林怀安的采访函留底")
	_expect(not letter_row.is_empty(), "自由探索中缺少采访函留底热点")
	if not letter_row.is_empty():
		main.choose_story_row(letter_row)
		await process_frame

	_expect(main.state.current_stage == "前序·函件正文", "点击采访函没有直接显示正文，实际为：%s" % main.state.current_stage)
	_expect(_canvas_button(main, "寻找回信") != null, "读完采访函后没有“寻找回信”按钮")
	_expect(_canvas_button(main, "返回房间") == null, "采访函正文仍可绕过搜寻直接返回房间")
	_expect(not main.state.knows("报馆采访函留底旁未见林怀安回函。"), "尚未寻找回信就提前写入了未见回函知识")

	var search_button := _canvas_button(main, "寻找回信")
	if search_button != null:
		search_button.emit_signal("pressed")
		await process_frame
		_expect(main.state.current_stage == "前序·函件正文", "搜寻动画尚未结束就提前进入结果页")
		_expect(_has_search_animation_piece(main), "点击寻找回信后没有加载可观察的搜寻动画")
		_expect(_canvas_button(main, "寻找回信") == null, "搜寻动画期间仍能重复点击寻找回信")
		await create_timer(1.8).timeout

	_expect(main.state.current_stage == "前序·寻找回信结果", "搜寻动画结束后没有进入结果阶段，实际为：%s" % main.state.current_stage)
	_expect(_canvas_text(main).contains("没找到"), "搜寻动画结束后没有显示“没找到”")
	_expect(not _canvas_text(main).contains("回函缺失"), "结果页仍显示已删除的“回函缺失”")
	_expect(main.state.knows("报馆采访函留底旁未见林怀安回函。"), "完成搜寻后没有记录范围受限的未见回函知识")
	_expect(_canvas_button(main, "返回房间") != null, "查看搜寻结果后没有返回房间的出口")

	main.queue_free()
	await process_frame
	_finish()


func _choice(main: Control, line: String) -> Dictionary:
	for row: Dictionary in main.story.available_choices(main.state.current_stage, main.state):
		if str(row.get("玩家可选台词", "")) == line:
			return row
	return {}


func _canvas_button(main: Control, text_value: String) -> Button:
	for child: Node in main.canvas.find_children("*", "Button", true, false):
		if str(child.text) == text_value:
			return child as Button
	return null


func _has_search_animation_piece(main: Control) -> bool:
	for child: Node in main.canvas.find_children("*", "Control", true, false):
		if bool(child.get_meta("reply_search_animation_piece", false)):
			return true
	return false


func _canvas_text(main: Control) -> String:
	var parts: Array[String] = []
	for child: Node in main.canvas.find_children("*", "Label", true, false):
		parts.append(str(child.text))
	return "\n".join(parts)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: letter-to-reply-search flow")
		quit(0)
	else:
		push_error("FAIL: %d reply-search assertions" % failures)
		quit(1)
