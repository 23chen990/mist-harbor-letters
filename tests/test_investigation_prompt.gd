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
	main._go_to_stage("前序·旧报发现")
	await process_frame
	var visible_text := _labels(main.canvas)
	_expect("照常经侧台退场" in visible_text, "旧报查看页没有把待核说法具体化")
	_expect("尚待核实" in visible_text, "旧报查看页没有保留待核说法的开放性")
	_expect("状态：尚待核实" in visible_text, "旧报查看页没有保留原件开放状态")
	_expect("调查笔记" not in visible_text, "旧报查看页仍用调查笔记替玩家总结问题")
	_expect("下一步：查纸、问人、看现场" not in visible_text, "旧报查看页仍自动安排泛化调查方法")
	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: opening report clue surfaces the reporter's open question")
		quit(0)
	else:
		push_error("FAIL: %d opening investigation prompt assertions" % failures)
		quit(1)


func _labels(parent: Node) -> String:
	var result: Array[String] = []
	for node: Node in parent.find_children("*", "Label", true, false):
		var label := node as Label
		if label != null and label.is_visible_in_tree() and not label.is_queued_for_deletion():
			result.append(label.text)
	return "\n".join(result)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
