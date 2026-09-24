extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/r16_2_main.tscn")
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame

	var summary: RichTextLabel = main.summary
	var body: Control = summary.get_parent()
	var scroll: ScrollContainer = body.get_parent()
	var columns: Control = scroll.get_parent()
	print("layout sizes main=%s columns=%s scroll=%s body=%s summary=%s" % [main.size, columns.size, scroll.size, body.size, summary.size])

	_expect((columns.size_flags_horizontal & Control.SIZE_EXPAND) != 0, "主列没有横向扩展")
	_expect((scroll.size_flags_horizontal & Control.SIZE_EXPAND) != 0, "正文滚动区没有横向扩展")
	_expect(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "正文滚动区不应允许横向挤压")
	_expect((body.size_flags_horizontal & Control.SIZE_EXPAND) != 0, "正文容器没有横向扩展")
	_expect((summary.size_flags_horizontal & Control.SIZE_EXPAND) != 0, "正文文本没有横向扩展")
	_expect((main.interaction.size_flags_horizontal & Control.SIZE_EXPAND) != 0, "交互区没有横向扩展")
	_expect(main.runtime.pending_kind == "dialogue", "主界面启动后应先显示逐句对白")
	_expect(not summary.text.contains(" / "), "主界面不应把多句对白拼成斜杠长句")
	_expect(not summary.text.contains("【若"), "主界面不应显示条件标记")
	var dialogue_button_found := false
	for child: Node in main.interaction.get_children():
		if child is Button and (child as Button).text in ["下一句", "继续"]:
			dialogue_button_found = true
	_expect(dialogue_button_found, "主界面没有逐句对白推进按钮")

	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: R16.2 layout width")
		quit(0)
	else:
		push_error("FAIL: %d R16.2 layout assertions" % failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
