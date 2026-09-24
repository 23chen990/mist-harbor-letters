extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.state.reset()
	main._entry_results_applied.clear()
	main.state.apply_result("report_focus=medicine")
	main._go_to_stage("第一章·次日见报")
	await process_frame
	var publication_text := _publication_labels(main)
	_expect("死者随身药盒已被封存" in publication_text, "C21 报纸卡缺少实际见报正文")
	_expect("其他记者在春和门外追问玉棠" not in publication_text, "C21 报纸卡把动作/表情备注当成正文")
	var consequence_text := _consequence_labels(main)
	_expect("其他记者在春和门外追问玉棠" in consequence_text, "C21 报纸卡移除正文后没有保留即时后果")
	_expect(main.canvas.find_children("*", "ScrollContainer", true, false).size() >= 1, "C21 长稿件正文没有滚动容器")
	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: publication card separates copy from scene directions")
		quit(0)
	else:
		push_error("FAIL: %d publication text separation assertions" % failures)
		quit(1)


func _publication_labels(main: Control) -> String:
	var result: Array[String] = []
	for node: Node in main.canvas.find_children("*", "Label", true, false):
		var label := node as Label
		if label == null or not label.is_visible_in_tree() or label.is_queued_for_deletion():
			continue
		if bool(label.get_meta("scene_action_ui", false)) and str(label.get_meta("scene_action_kind", "")) == "publication_panel":
			result.append(label.text)
	return "\n".join(result)


func _consequence_labels(main: Control) -> String:
	var result: Array[String] = []
	for node: Node in main.canvas.find_children("*", "Label", true, false):
		var label := node as Label
		if label == null or not label.is_visible_in_tree() or label.is_queued_for_deletion():
			continue
		if bool(label.get_meta("scene_action_ui", false)) and str(label.get_meta("scene_action_kind", "")) == "publication_consequence":
			result.append(label.text)
	return "\n".join(result)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
