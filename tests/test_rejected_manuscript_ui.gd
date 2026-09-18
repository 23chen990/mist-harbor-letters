extends SceneTree

const REMOVED_EXPLANATION := "沈砚舟的稿纸上，末句“显然有人事先动过手脚”已被红笔划去。上面一行只写着：两个装卸工看见起火前有人在仓门边转过。"

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main: Control = packed.instantiate()
	root.add_child(main)
	await process_frame

	_expect(main.state.current_stage == "前序·退稿与派活", "测试必须从 P0001 开场开始")
	var row: Dictionary = main.story.first_stage_row("前序·退稿与派活")
	_expect(not REMOVED_EXPLANATION in str(row.get("NPC台词", "")), "P0001 仍把退稿稿纸写成说明旁白")
	_expect("退稿稿件UI" in str(row.get("演出/交互方式", "")), "P0001 没有使用 authored 退稿稿件 UI 标签")

	var manuscript_nodes := _nodes_with_meta(main.canvas, "rejected_manuscript_ui")
	_expect(manuscript_nodes.size() >= 6, "开场没有绘制足够可识别的退稿稿件 UI 元素")
	_expect(_canvas_text(main).contains("撤"), "退稿稿件 UI 没有醒目的撤稿标记")
	_expect(not _canvas_text(main).contains("证据不足"), "UI 擅自新增了未确认的编辑方法论判词")

	var beats: Array[Dictionary] = main._presentation_beats(main.story.available_presentations(main.state.current_stage, main.state))
	_expect(not beats.is_empty(), "P0001 对话节拍缺失")
	var guard := 0
	while main.state.current_stage != "前序·自由探索" and guard < 20:
		_expect(not _canvas_text(main).contains(REMOVED_EXPLANATION), "退稿说明旁白仍在某个逐句节拍中出现")
		var continue_button := _next_button(main)
		_expect(continue_button != null, "开场尚未完成时缺少回答或继续按钮")
		if continue_button == null:
			break
		continue_button.pressed.emit()
		await process_frame
		guard += 1

	_expect(main.state.current_stage == "前序·自由探索", "退稿稿件 UI 场景完成后没有进入自由探索")
	_expect(_nodes_with_meta(main.canvas, "rejected_manuscript_ui").is_empty(), "离开 P0001 后退稿稿件 UI 仍残留在其他场景")

	main.queue_free()
	await process_frame
	_finish()


func _nodes_with_meta(parent: Node, meta_name: StringName) -> Array[Node]:
	var matches: Array[Node] = []
	for node: Node in parent.find_children("*", "Control", true, false):
		if node.has_meta(meta_name):
			matches.append(node)
	return matches


func _canvas_text(main: Control) -> String:
	var parts: Array[String] = []
	for node: Node in main.canvas.find_children("*", "Label", true, false):
		var label := node as Label
		if label != null:
			parts.append(label.text)
	return "\n".join(parts)


func _canvas_button(main: Control, text_value: String) -> Button:
	for node: Node in main.canvas.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.text == text_value:
			return button
	return null


func _next_button(main: Control) -> Button:
	for node: Node in main.canvas.find_children("*", "Button", true, false):
		var button := node as Button
		if button.has_meta("player_response"):
			return button
	return _canvas_button(main, "继续")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: rejected manuscript UI")
		quit(0)
	else:
		push_error("FAIL: %d rejected-manuscript assertions" % failures)
		quit(1)
