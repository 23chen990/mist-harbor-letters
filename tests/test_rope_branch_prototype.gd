extends SceneTree

const Driver = preload("res://tests/story_test_helpers.gd")
const StoryRepositoryScript = preload("res://scripts/story_repository.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_story_rows()
	await _test_ui_branches()
	if failures == 0:
		print("PASS: rope branch prototype (C21 split + C22 aftermath)")
		quit(0)
	else:
		push_error("FAIL: %d rope branch prototype assertions" % failures)
		quit(1)


func _test_story_rows() -> void:
	var story = StoryRepositoryScript.new()
	_expect(story.load_story("res://content/程序生成_请勿手改/剧情剧本.csv"), "剧情 CSV 无法加载")
	_expect(story.row_count() == 147, "吊绳样板后活动剧情应为 147 行")
	for row_id: String in ["C21_004A", "C21_004B", "C22_002", "C22_003"]:
		_expect(_has_row(story, row_id), "缺少吊绳样板行：%s" % row_id)
	_expect(not _has_row(story, "C21_004"), "旧 C21_004 应已拆分为 A/B")
	var secured := _row(story, "C21_004A")
	var lost := _row(story, "C21_004B")
	_expect(str(secured.get("出现条件", "")) == "report_focus=rope and police_told_rope=true", "C21_004A 条件错误")
	_expect(str(lost.get("出现条件", "")) == "report_focus=rope and police_told_rope=false", "C21_004B 条件错误")
	_expect(str(secured.get("画面表现", "")).contains("封存"), "C21_004A 未写入封存后果")
	_expect(str(lost.get("画面表现", "")).contains("收束位置已经改变"), "C21_004B 未写入复位后果")


func _test_ui_branches() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var driver := Driver.new(main, self, _expect)
	await _assert_newspaper_branch(main, driver, true, "封存", "evidence.rope_verifiable=true")
	await _assert_newspaper_branch(main, driver, false, "收束位置已经改变", "evidence.rope_verifiable=false")
	await _assert_chapter_aftermath(main, driver, "secured", "继续封存绳排")
	await _assert_chapter_aftermath(main, driver, "lost", "拦在绳排之外")
	main.queue_free()
	await process_frame


func _assert_newspaper_branch(main: Control, driver: RefCounted, told_police: bool, expected_text: String, expected_state: String) -> void:
	main.state.reset()
	main._entry_results_applied.clear()
	main.state.apply_result("report_focus=rope; police_told_rope=%s" % str(told_police).to_lower())
	main._go_to_stage("第一章·次日见报")
	await process_frame
	var screen: String = driver.labels()
	_expect(screen.contains("春和天桥吊绳状态存疑"), "C21 未显示吊绳见报标题")
	_expect(screen.contains(expected_text), "C21 未显示吊绳分叉后果：%s" % expected_text)
	_expect(main.state.condition_met(expected_state), "C21 未写入状态：%s" % expected_state)
	_expect(main.state.condition_met("chapter1_aftermath.rope=%s" % ("secured" if told_police else "lost")), "C21 未写入章末结账状态")


func _assert_chapter_aftermath(main: Control, driver: RefCounted, aftermath: String, expected_text: String) -> void:
	main.state.reset()
	main._entry_results_applied.clear()
	main.state.apply_result("chapter1_aftermath.rope=%s" % aftermath)
	main._go_to_stage("第一章·第一章结尾")
	await process_frame
	if not driver.labels().contains("这一篇见报之后") and driver.button("继续") != null:
		await driver.press("继续")
		await process_frame
	_expect(driver.labels().contains("这一篇见报之后"), "C22 未显示见报之后栏目")
	_expect(driver.labels().contains(expected_text), "C22 未显示 %s 结账：%s" % [aftermath, expected_text])


func _has_row(story: RefCounted, row_id: String) -> bool:
	for row: Dictionary in story.rows:
		if str(row.get("自动ID", "")) == row_id:
			return true
	return false


func _row(story: RefCounted, row_id: String) -> Dictionary:
	for row: Dictionary in story.rows:
		if str(row.get("自动ID", "")) == row_id:
			return row
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
