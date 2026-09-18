extends SceneTree

const PORTRAIT_PATH := "res://art/角色立绘/沈砚舟_序章_平静观察_半身.png"

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main: Control = packed.instantiate()
	root.add_child(main)
	await process_frame

	# 回答区保留 NPC 上下文，不再通过点击继续播放主控台词。
	# 真实立绘资源与绘制能力仍独立验证，不能用新回答流程掩盖资源缺失。
	main._clear(main.canvas)
	main._draw_portrait("沈砚舟")
	await process_frame

	_expect(ResourceLoader.exists(PORTRAIT_PATH), "沈砚舟序章实机立绘资源尚未建立")
	var portrait := _character_portrait(main.canvas, "沈砚舟")
	_expect(portrait != null, "沈砚舟说话时没有使用真实透明立绘")
	_expect(not "[ 沈砚舟立绘 ]" in _canvas_text(main), "沈砚舟真实立绘已接入后仍显示技术占位文字")
	if portrait != null:
		_expect(portrait.texture != null, "沈砚舟立绘节点没有纹理")
		_expect(portrait.size.x >= 200.0 and portrait.size.y >= 200.0, "沈砚舟立绘在1280×720界面中的显示面积过小")
		if portrait.texture != null:
			var image := portrait.texture.get_image()
			_expect(image.get_width() == 1024 and image.get_height() == 1024, "沈砚舟立绘源图必须是1024×1024方形半身图")
			_expect(_corners_are_transparent(image), "沈砚舟立绘四角没有透明留白")
			_expect(image.get_pixel(image.get_width() / 2, image.get_height() / 2).a > 0.5, "沈砚舟立绘中心没有可见人物")

	var inner_stage := "测试·内心立绘"
	var inner_row: Dictionary = {"自动ID": "TEST_INNER_PORTRAIT", "对话阶段": inner_stage, "场景": "测试场景", "人物": "沈砚舟", "内容类型": "内心", "NPC台词": "只是一句内心独白。", "出现条件": "始终", "下一话题": "前序·退稿与派活", "是否说出口": "否"}
	main.story.rows.append(inner_row)
	main.story._stages[inner_stage] = [inner_row]
	main._go_to_stage(inner_stage)
	await process_frame
	_expect(_character_portrait(main.canvas, "沈砚舟") == null, "内心独白不应强制显示沈砚舟立绘")

	main.queue_free()
	await process_frame
	_finish()


func _character_portrait(parent: Node, character: String) -> TextureRect:
	for node: Node in parent.find_children("*", "TextureRect", true, false):
		var portrait := node as TextureRect
		if portrait != null and str(portrait.get_meta("character_portrait", "")) == character:
			return portrait
	return null


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


func _corners_are_transparent(image: Image) -> bool:
	var max_x := image.get_width() - 1
	var max_y := image.get_height() - 1
	return (
		image.get_pixel(0, 0).a < 0.05
		and image.get_pixel(max_x, 0).a < 0.05
		and image.get_pixel(0, max_y).a < 0.05
		and image.get_pixel(max_x, max_y).a < 0.05
	)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: Shen Yanzhou in-game portrait")
		quit(0)
		return
	push_error("FAIL: %d Shen-Yanzhou portrait assertions" % failures)
	quit(1)
