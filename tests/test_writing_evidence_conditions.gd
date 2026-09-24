extends SceneTree

const Driver = preload("res://tests/story_test_helpers.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_path_only_uses_weak_wording()
	await _check_side_observation_uses_strong_wording()
	await _check_side_without_position_observation_has_no_location_claim()
	if failures == 0:
		print("PASS: writing claims follow the available route evidence")
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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
