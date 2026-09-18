extends SceneTree

const StoryRepositoryScript = preload("res://scripts/story_repository.gd")

var failures := 0


func _init() -> void:
	var story = StoryRepositoryScript.new()
	_expect(story.load_story("res://content/程序生成_请勿手改/剧情剧本.csv"), "v6 活动剧情无法加载")
	_expect(story.row_count() == 107, "v6 迁移后活动剧情行数不是 107")
	var folder := _row(story, "P0015")
	_expect("冬月初七晚八时开锣" in str(folder.get("NPC台词", "")) and "林怀安领衔《夜渡》" in str(folder.get("NPC台词", "")), "春和工作夹没有保留已确认演出安排")
	_expect(not "戏班换角" in str(folder) and not "教学" in str(folder), "工作夹恢复了已撤下教学页")
	var end_row := _row(story, "C22_001")
	_expect("新报与旧报标题并排" in str(end_row.get("动作/表情备注", "")), "v6 C22 章末画面缺失")
	_expect("不进入尚未正式迁移的第二章" in str(end_row.get("设计备注", "")), "C22 没有明确停在当前正式范围")
	_finish()


func _row(story: RefCounted, row_id: String) -> Dictionary:
	for row: Dictionary in story.rows:
		if str(row.get("自动ID", "")) == row_id:
			return row
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: v6 workbook content replaces v3.4.3")
		quit(0)
	else:
		push_error("FAIL: %d v6 replacement assertions" % failures)
		quit(1)
