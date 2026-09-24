extends SceneTree

const StoryRepositoryScript = preload("res://scripts/story_repository.gd")

var failures := 0


func _init() -> void:
	var story = StoryRepositoryScript.new()
	_expect(story.load_story("res://content/程序生成_请勿手改/剧情剧本.csv"), "v6 剧情表无法加载")
	_expect(story.row_count() == 147, "v6 活动剧情应为 147 行")
	_check_c04_release(story)
	_check_c14_release(story)
	_check_c18_editor_feedback(story)
	_check_core_case_terms_are_not_leaked(story)
	_finish()


func _check_c04_release(story: RefCounted) -> void:
	var original := _row(story, "C04_010")
	var copied := _row(story, "C04_020")
	var oral := _row(story, "C04_030")
	_expect("他寄来的那份，我收到了。" in str(original.get("NPC台词", "")), "原件路线没有释放林怀安收到过函件")
	_expect("原件呢？" in str(copied.get("NPC台词", "")), "抄录路线没有区分原件位置")
	_expect("原件在报馆。正文我记得。" in str(oral.get("NPC台词", "")), "第三项路线没有保持无纸面口述")
	_expect("无纸面" in str(oral.get("演出/交互方式", "")), "第三项路线缺少无纸面演出纪律")


func _check_c14_release(story: RefCounted) -> void:
	var oral_record := _row(story, "C14_040")
	var effects := str(oral_record.get("状态写入（不显示）", ""))
	_expect("只向林怀安口述了函件内容" in str(oral_record.get("NPC台词", "")), "C14 没有登记第三项路线的口述事实")
	_expect("明天去报馆核验原件" in str(oral_record.get("NPC台词", "")), "C14 没有安排之后核验原件")
	_expect("oral_pending_newsroom_check" in effects and "newsroom_check=planned" in effects, "C14 没有写入口述待核状态")


func _check_c18_editor_feedback(story: RefCounted) -> void:
	var feedback := _row(story, "C19_001")
	_expect(str(feedback.get("出现条件", "")) == "report_focus=medicine", "药盒稿件没有绑定编辑即时反馈条件")
	_expect("女儿抢药盒？那是花边" in str(feedback.get("NPC台词", "")), "药盒稿件没有显示编辑的花边判断")


func _check_core_case_terms_are_not_leaked(story: RefCounted) -> void:
	for row: Dictionary in story.rows:
		var spoken := str(row.get("NPC台词", ""))
		for forbidden: String in ["维修验收", "假验收", "签字造假", "动过药", "换回正常药", "周明远"]:
			_expect(not spoken.contains(forbidden), "第一章提前泄露核心名词“%s”：%s" % [forbidden, row.get("自动ID", "")])


func _row(story: RefCounted, row_id: String) -> Dictionary:
	for row: Dictionary in story.rows:
		if str(row.get("自动ID", "")) == row_id:
			return row
	_expect(false, "找不到 v6 剧情行：%s" % row_id)
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: v6 first-chapter secret release")
		quit(0)
	else:
		push_error("FAIL: %d v6 secret-release assertions" % failures)
		quit(1)
