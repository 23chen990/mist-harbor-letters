extends SceneTree

const StoryRepositoryScript = preload("res://scripts/story_repository.gd")

var failures := 0


func _init() -> void:
	var story = StoryRepositoryScript.new()
	_expect(story.load_story("res://content/程序生成_请勿手改/剧情剧本.csv"), "活动剧情无法加载")
	for removed_id: String in ["S0006", "S0035", "C2_0008"]:
		_expect(_row_optional(story, removed_id).is_empty(), "旧 v2/v3 行仍在活动 CSV：%s" % removed_id)
	for removed_text: String in ["旅行箱", "沈家旧宅", "父亲最后寄出的信"]:
		_expect(not _story_contains(story, removed_text), "活动剧情恢复了 v5/v3 残留：%s" % removed_text)
	_expect(not story.has_stage("第二章·开场") and not story.has_stage("第三章·到警署"), "旧二、三章仍可运行")
	_expect(story.has_stage("第一章·第一章结尾"), "v6 第一章章末缺失")
	_finish()


func _row_optional(story: RefCounted, row_id: String) -> Dictionary:
	for row: Dictionary in story.rows:
		if str(row.get("自动ID", "")) == row_id:
			return row
	return {}


func _story_contains(story: RefCounted, fragment: String) -> bool:
	for row: Dictionary in story.rows:
		for header: String in story.headers:
			if fragment in str(row.get(header, "")):
				return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: legacy v2/v3 runtime data retired")
		quit(0)
	else:
		push_error("FAIL: %d legacy-retirement assertions" % failures)
		quit(1)
