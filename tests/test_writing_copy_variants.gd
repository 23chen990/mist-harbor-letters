extends SceneTree

const Driver = preload("res://tests/story_test_helpers.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_medicine_narrow_copy()
	await _check_medicine_strong_copy_and_publication()
	await _check_weak_location_copy()
	await _check_absence_subject_copy("C07_orchestra", "陈九生｜速记｜", "writing_subject_id", "chen", "谢幕前后，后台总管陈九生曾离开原本位置")
	await _check_absence_subject_copy("C07_front", "方仲山｜速记｜", "writing_subject_id", "fang", "演出后段至谢幕期间，负责前场事务的方仲山曾离开账桌")
	await _check_absence_requires_a_named_record()
	await _check_middle_front_alone_does_not_name_absence()
	await _check_weak_location_requires_the_empty_hall_record()
	if failures == 0:
		print("PASS: writing source choices produce distinct copy and named subjects")
		quit(0)
	else:
		push_error("FAIL: %d writing copy assertions" % failures)
		quit(1)


func _check_medicine_narrow_copy() -> void:
	var main: Control = await _open_writing(["C10_MEDICINE_BOX"])
	var driver := Driver.new(main, self, _expect)
	_expect(await driver.press("死者女儿曾试图带走药盒"), "药盒判断按钮不可达")
	_expect(await _press_fragment(main, "速记（窄写法）"), "药盒窄写法来源不可达")
	_expect(str(main.state.technical_values.get("writing_copy_variant", "")) == "medicine_narrow", "仅 C10 记录没有写入窄写法状态")
	_expect("林玉棠曾从死者衣内取出随身药盒，并拒绝立即交给现场医师。" in driver.labels(), "C19 没有显示药盒窄写法稿面预览")
	main.queue_free()
	await process_frame


func _check_medicine_strong_copy_and_publication() -> void:
	var main: Control = await _open_writing(["C10_MEDICINE_BOX", "C12_drug"])
	var driver := Driver.new(main, self, _expect)
	_expect(await driver.press("死者女儿曾试图带走药盒"), "药盒强写法判断按钮不可达")
	_expect(await _press_fragment(main, "速记合并"), "药盒合并来源不可达")
	var strong_copy := "林怀安倒下后，其女林玉棠曾将死者随身药盒取出，并一度试图将其带离现场。"
	_expect(str(main.state.technical_values.get("writing_copy_variant", "")) == "medicine_strong", "C10+C12 没有写入强写法状态")
	_expect(str(main.state.technical_values.get("writing_copy_text", "")).begins_with(strong_copy), "C19 没有形成药盒强写法")
	main.state.apply_result("report_focus=medicine")
	main._go_to_stage("第一章·次日见报")
	await process_frame
	_expect(("稿件正文｜" + str(main.state.technical_values.get("writing_copy_text", ""))) in driver.labels(), "C21 没有显示药盒强写法正文")
	main.queue_free()
	await process_frame


func _check_weak_location_copy() -> void:
	var main: Control = await _open_writing(["C12_path"])
	var driver := Driver.new(main, self, _expect)
	main.state.apply_result("c07_position=audience; pre_police_check=path; lin_missing_after_curtain=true")
	main._go_to_stage("第一章·第一篇稿")
	await process_frame
	_expect(await driver.press("场务说他从台侧下的，人却不在侧厅"), "窄位置判断按钮不可达")
	_expect(await _press_fragment(main, "现场说法 + 来路速记"), "窄位置来源按钮不可达")
	_expect(str(main.state.technical_values.get("writing_copy_variant", "")) == "location_weak", "窄位置来源没有写入对应状态")
	_expect("场务称林怀安从台侧下台，侧厅未见其人" in str(main.state.technical_values.get("writing_copy_text", "")), "窄位置稿件没有保留场务说法")
	main.queue_free()
	await process_frame


func _check_absence_subject_copy(note_id: String, source_fragment: String, state_key: String, expected_subject: String, copy_fragment: String) -> void:
	var main: Control = await _open_writing([note_id])
	var driver := Driver.new(main, self, _expect)
	var position := "orchestra" if note_id == "C07_orchestra" else "front"
	main.state.apply_result("c07_position=%s" % position)
	main._go_to_stage("第一章·第一篇稿")
	await process_frame
	_expect(await driver.press("后台人员在关键时段离开岗位"), "离岗判断按钮不可达：%s" % note_id)
	_expect(await _press_fragment(main, source_fragment), "离岗来源没有标明具体人物：%s" % note_id)
	_expect(str(main.state.technical_values.get(state_key, "")) == expected_subject, "离岗来源没有写入主体：%s" % note_id)
	_expect(copy_fragment in str(main.state.technical_values.get("writing_copy_text", "")), "离岗稿件没有保留具体主体：%s" % note_id)
	main.queue_free()
	await process_frame


func _check_absence_requires_a_named_record() -> void:
	var main: Control = await _open_writing([])
	var driver := Driver.new(main, self, _expect)
	_expect(driver.button("后台人员在关键时段离开岗位") == null, "没有具体人物现场速记时错误显示离岗判断")
	main.queue_free()
	await process_frame


func _check_middle_front_alone_does_not_name_absence() -> void:
	var main: Control = await _open_writing(["C06_front"])
	var driver := Driver.new(main, self, _expect)
	main.state.apply_result("c06_position=front; c07_position=side")
	main._go_to_stage("第一章·第一篇稿")
	await process_frame
	_expect(driver.button("后台人员在关键时段离开岗位") == null, "仅有中段前场记录时错误写成谢幕前后离岗")
	main.queue_free()
	await process_frame


func _check_weak_location_requires_the_empty_hall_record() -> void:
	var main: Control = await _open_writing(["C12_path"])
	main.state.apply_result("c07_position=audience; pre_police_check=path")
	main._go_to_stage("第一章·第一篇稿")
	await process_frame
	var driver := Driver.new(main, self, _expect)
	_expect(driver.button("场务说他从台侧下的，人却不在侧厅") == null, "没有侧厅原话时错误显示窄位置写法")
	main.queue_free()
	await process_frame


func _open_writing(notes: Array[String]) -> Control:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.state.reset()
	main._entry_results_applied.clear()
	var effects := ""
	for note_id: String in notes:
		effects += (";" if not effects.is_empty() else "") + "notes += %s" % note_id
	main.state.apply_result(effects)
	main._go_to_stage("第一章·第一篇稿")
	await process_frame
	return main


func _press_fragment(main: Control, fragment: String) -> bool:
	for node: Node in main.canvas.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.is_visible_in_tree() and not button.disabled and fragment in button.text:
			button.pressed.emit()
			await process_frame
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
