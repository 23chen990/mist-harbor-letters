extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main: Control = packed.instantiate()
	root.add_child(main)
	await process_frame

	# DEC34 removes the former S02 monologue. Keep DEC32's rendering contract
	# with a test-only row rather than resurrecting removed formal content.
	var fixture: Dictionary = {
		"自动ID": "TEST_INNER_LAYOUT", "对话阶段": "测试·内心版式", "场景": "测试场景",
		"人物": "沈砚舟", "内容类型": "内心", "NPC台词": "先看这一页。再看下一页。",
		"出现条件": "始终", "是否说出口": "否", "下一话题": "前序·自由探索",
	}
	main.story.rows.append(fixture)
	main.story._stages["测试·内心版式"] = [fixture]
	main._go_to_stage("测试·内心版式")
	await process_frame

	_expect(main.state.current_stage == "测试·内心版式", "没有进入测试内心版式阶段")
	_expect(_has_panel(main.canvas, Rect2(70, 344, 1140, 325)), "内心独白没有使用下屏标准对话框")
	_expect(not _has_panel(main.canvas, Rect2(80, 92, 1120, 520)), "内心独白仍在使用遮住场景的大屏面板")
	var canvas_text := _canvas_text(main)
	_expect("沈砚舟" in canvas_text and "先看这一页。" in canvas_text, "下屏对话框没有保留内心独白的身份与当前句")
	_expect(not "[ 沈砚舟立绘 ]" in canvas_text, "内心独白不应因为改用标准对话框而强制弹出人物立绘")
	_expect(_canvas_button(main, "继续") != null, "内心独白下屏对话框缺少主动继续按钮")

	main.queue_free()
	await process_frame
	_finish()


func _has_panel(parent: Node, bounds: Rect2) -> bool:
	for node: Node in parent.find_children("*", "Panel", true, false):
		var panel := node as Panel
		if panel != null and panel.position.is_equal_approx(bounds.position) and panel.size.is_equal_approx(bounds.size):
			return true
	return false


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


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: inner monologue lower dialogue layout")
		quit(0)
		return
	push_error("FAIL: %d inner-monologue layout assertions" % failures)
	quit(1)
