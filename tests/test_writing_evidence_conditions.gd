extends SceneTree

const Driver = preload("res://tests/story_test_helpers.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_path_only_uses_weak_wording()
	await _check_side_observation_uses_strong_wording()
	await _check_side_without_position_observation_has_no_location_claim()
	await _check_medicine_requires_observed_record()
	await _check_rope_requires_observed_record()
	if failures == 0:
		print("PASS: writing claims require actual location, medicine and rope records")
		quit(0)
	else:
		push_error("FAIL: %d writing evidence condition assertions" % failures)
		quit(1)


func _check_path_only_uses_weak_wording() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var driver := Driver.new(main, self, _expect)
	main.state.reset()
	main._entry_results_applied.clear()
	main.state.apply_result("c07_position=audience; pre_police_check=path; lin_missing_after_curtain=true; notes += C12_path")
	main._go_to_stage("第一章·第一篇稿")
	await process_frame
	_expect(driver.button("场务说他从台侧下的，人却不在侧厅") != null, "只有来路记录时没有显示窄位置写法")
	_expect(driver.button("倒地位置与离场路线对不上") == null, "只有来路记录时错误显示了强位置写法")
	main.queue_free()
	await process_frame


func _check_side_observation_uses_strong_wording() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var driver := Driver.new(main, self, _expect)
	main.state.reset()
	main._entry_results_applied.clear()
	main.state.apply_result("c07_position=side; notes += C07_side; notes += C09_position")
	main._go_to_stage("第一章·第一篇稿")
	await process_frame
	_expect(driver.button("倒地位置与离场路线对不上") != null, "有台侧亲见记录时没有显示强位置写法")
	_expect(driver.button("场务说他从台侧下的，人却不在侧厅") == null, "有台侧亲见记录时错误显示了窄位置写法")
	main.queue_free()
	await process_frame


func _check_side_without_position_observation_has_no_location_claim() -> void:
	for note_id: String in ["C09_lin", "C09_people"]:
		var main: Control = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		var driver := Driver.new(main, self, _expect)
		main.state.reset()
		main._entry_results_applied.clear()
		main.state.apply_result("c07_position=side; notes += C07_side; notes += %s" % note_id)
		main._go_to_stage("第一章·第一篇稿")
		await process_frame
		_expect(driver.button("倒地位置与离场路线对不上") == null, "台侧但未观察倒地位置时错误显示强位置写法：%s" % note_id)
		_expect(driver.button("场务说他从台侧下的，人却不在侧厅") == null, "台侧路线不应显示来路窄写法：%s" % note_id)
		main.queue_free()
		await process_frame


func _check_medicine_requires_observed_record() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var driver := Driver.new(main, self, _expect)
	main.state.reset()
	main._entry_results_applied.clear()
	main._go_to_stage("第一章·第一篇稿")
	await process_frame
	_expect(driver.button("死者女儿曾试图带走药盒") == null, "没有 C10 药盒经过时错误显示药盒判断")
	_expect(driver.button("只报道已经确认的事实") != null, "没有疑点记录时应仍能选择只报确认事实")
	main.state.apply_result("notes += C10_MEDICINE_BOX")
	main._go_to_stage("第一章·第一篇稿")
	await process_frame
	_expect(driver.button("死者女儿曾试图带走药盒") != null, "取得 C10 药盒经过后没有显示药盒判断")
	main.queue_free()
	await process_frame


func _check_rope_requires_observed_record() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var driver := Driver.new(main, self, _expect)
	main.state.reset()
	main._entry_results_applied.clear()
	main.state.apply_result("pre_police_check=bridge")
	main._go_to_stage("第一章·第一篇稿")
	await process_frame
	_expect(driver.button("天桥吊绳有近期变动痕迹") == null, "只选择天桥路线、尚未看到绳结时错误显示吊绳判断")
	main.state.apply_result("notes += C12_ROPE_ANOMALY")
	main._go_to_stage("第一章·第一篇稿")
	await process_frame
	_expect(driver.button("天桥吊绳有近期变动痕迹") != null, "实际取得吊绳异常记录后没有显示吊绳判断")
	main.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
