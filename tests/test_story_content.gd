extends SceneTree

const StoryRepositoryScript = preload("res://scripts/story_repository.gd")
const GameStateScript = preload("res://scripts/game_state.gd")

var failures := 0


func _init() -> void:
	var story = StoryRepositoryScript.new()
	_expect(story.load_story("res://content/程序生成_请勿手改/剧情剧本.csv"), "v6 剧情 CSV 加载失败：%s" % "；".join(story.errors))
	_expect(story.errors.is_empty(), "v6 剧情表校验失败：%s" % "；".join(story.errors))
	_expect(story.row_count() == 107, "活动剧情应为序章 + C01—C22 共 107 行")
	for stage: String in [
		"前序·自由探索", "前序·准备出发", "第一章·报馆换人了", "第一章·纪念演出采访",
		"第一章·第一眼", "第一章·警方到场前", "第一章·沈砚舟的笔录", "第一章·现场收束",
		"第一章·第一篇稿", "第一章·次日见报", "第一章·第一章结尾",
	]:
		_expect(story.has_stage(stage), "v6 缺少剧情阶段：%s" % stage)
	for removed_stage: String in ["入口·被拦", "第二章·开场", "第三章·到警署", "第三章·收束"]:
		_expect(not story.has_stage(removed_stage), "活动剧情仍包含旧阶段：%s" % removed_stage)
	_check_ids_and_labels(story)
	_check_three_letter_strategies(story)
	_check_c01_to_c22(story)
	_finish()


func _check_ids_and_labels(story: RefCounted) -> void:
	var ids: Dictionary = {}
	for row: Dictionary in story.rows:
		var row_id := str(row.get("自动ID", ""))
		_expect(not row_id.is_empty() and not ids.has(row_id), "自动 ID 为空或重复：%s" % row_id)
		ids[row_id] = true
		var player_line := str(row.get("玩家可选台词", ""))
		for tag: String in ["[QUESTION]", "[ATTITUDE]", "[CONFRONT]", "[DIRECTION]"]:
			_expect(not player_line.contains(tag), "正式选项泄露技术标签：%s" % player_line)


func _check_three_letter_strategies(story: RefCounted) -> void:
	var state = GameStateScript.new()
	state.apply_result("letter_read=true")
	var choices: Array[Dictionary] = story.available_choices("前序·准备出发", state)
	_expect(choices.size() == 3, "S02 应保留三种函件准备方式")
	for line: String in ["带上采访函留底", "抄下函件正文", "原件先不动，只记住要点"]:
		_expect(_has_line(choices, line), "S02 缺少准备选项：%s" % line)
	var third := _row(story, "P0010B")
	_expect("evidence.letter_original.holder=newsroom" in str(third.get("状态写入（不显示）", "")), "第三项没有把原件留在报馆")
	_expect("evidence.letter_copy.exists=false" in str(third.get("状态写入（不显示）", "")), "第三项错误生成纸面抄件")


func _check_c01_to_c22(story: RefCounted) -> void:
	for number in range(1, 23):
		var prefix := "C%02d_" % number
		var found := false
		for row: Dictionary in story.rows:
			if str(row.get("自动ID", "")).begins_with(prefix):
				found = true
				break
		_expect(found, "活动剧情缺少 C%02d" % number)
	_expect(str(_row(story, "C22_001").get("状态写入（不显示）", "")).contains("chapter1_complete=true"), "C22 没有章末状态")


func _has_line(rows: Array[Dictionary], line: String) -> bool:
	for row: Dictionary in rows:
		if str(row.get("玩家可选台词", "")) == line:
			return true
	return false


func _row(story: RefCounted, row_id: String) -> Dictionary:
	for row: Dictionary in story.rows:
		if str(row.get("自动ID", "")) == row_id:
			return row
	_expect(false, "找不到剧情行：%s" % row_id)
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: v6 active story content")
		quit(0)
	else:
		push_error("FAIL: %d v6 content assertions" % failures)
		quit(1)
