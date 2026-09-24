extends SceneTree

const StoryRepositoryScript = preload("res://scripts/story_repository.gd")

var failures := 0


func _init() -> void:
	var story = StoryRepositoryScript.new()
	_expect(story.load_story("res://content/程序生成_请勿手改/剧情剧本.csv"), "剧情 CSV 无法加载：%s" % "；".join(story.errors))
	if failures > 0:
		_finish()
		return

	_expect(story.has_stage("第一章·报馆换人了"), "运行数据仍未进入 v6 C01『报馆换人了』")
	_expect(_stage_contains(story, "第一章·报馆换人了", "NPC台词", "报馆换人了？"), "v6 C01 的入口对白没有同步")
	_expect(_stage_contains(story, "第一章·方仲山", "NPC台词", "阿成，带沈记者去侧座"), "v6 C02 的方仲山派活没有同步")
	_expect(_stage_prefix_contains(story, "第一章·阿成带路", "NPC台词", "爹，方先生让我先带报馆的过去"), "v6 C03 没有保留阿成与陈九生的父子关系")
	_expect(_stage_contains(story, "第一章·纪念演出采访", "NPC台词", "二十年忌，为什么还是《夜渡》？"), "v6 C04 正常采访没有同步")
	_expect(_has_player_line(story, "原件先不动，只记住要点"), "S02 已确认保留的第三个函件处理选项没有同步")
	_expect(_stage_contains(story, "第一章·纪念演出采访·函件", "NPC台词", "原件在报馆"), "C04 第三分支没有说明原件仍在报馆")
	_expect(_stage_not_contains(story, "第一章·纪念演出采访·函件", "NPC台词", "把函件放在桌上", "letter_preparation=left_home"), "C04 第三分支错误递交了纸面原件")
	_expect(_stage_contains(story, "第一章·开锣前", "玩家可选台词", "观众席侧边"), "v6 C05 四位置观察没有同步")
	_expect(_stage_contains(story, "第一章·演出中段", "玩家可选台词", "台侧外围"), "v6 C06 单位置取舍没有同步")
	_expect(_stage_contains(story, "第一章·谢幕前后", "玩家可选台词", "乐池外围"), "v6 C07 单位置取舍没有同步")
	_expect(_stage_contains(story, "第一章·侧厅无人", "NPC台词", "林班主还没来？"), "v6 C08 侧厅无人没有同步")
	_expect(_stage_contains(story, "第一章·第一眼", "玩家可选台词", "看倒下的位置"), "v6 C09 一次性第一眼没有同步")
	_expect(_stage_contains(story, "第一章·药盒落地", "NPC台词", "你刚才到底给他看了什么？"), "v6 C10 药盒冲突没有同步")
	_expect(_stage_contains(story, "第一章·警方到场前", "玩家可选台词", "沿铁梯上天桥"), "v6 C12 警前调查选择没有同步")
	_expect(_stage_contains(story, "第一章·警方进场", "NPC台词", "谁碰过死者？谁把药拿出来的？"), "v6 C13 警方进场没有同步")
	_expect(_stage_contains(story, "第一章·沈砚舟的笔录", "NPC台词", "姓名，报馆，今晚为什么来。"), "v6 C14 笔录没有同步")
	_expect(_stage_contains(story, "第一章·沈砚舟的笔录", "NPC台词", "登记口述内容"), "C14 第三分支没有把函件内容登记为口述")
	_expect(_stage_contains(story, "第一章·沈砚舟的笔录", "NPC台词", "去报馆核验"), "C14 第三分支没有安排后续去报馆核验原件")
	_expect(_stage_contains(story, "第一章·现场收束", "玩家可选台词", "看方仲山"), "v6 C16 四人观察没有同步")
	_expect(_stage_contains(story, "第一章·末版还空着", "NPC台词", "春和那栏还空着。"), "v6 C17 回报馆没有同步")
	_expect(_stage_contains(story, "第一章·第一篇稿", "NPC台词", "截至截稿，确切死因尚未公布"), "v6 C18 写稿基础段没有同步")
	_expect(_stage_contains(story, "第一章·是否写入赵敬文", "玩家可选台词", "写入两件事的联系"), "v6 C19 是否公开关联没有同步")
	_expect(_stage_contains(story, "第一章·交稿", "玩家可选台词", "交稿"), "v6 C20 交稿没有同步")
	_expect(story.has_stage("第一章·第一章结尾"), "v6 C22 第一章结尾没有同步")

	_expect(not story.has_stage("第二章·开场"), "垂直切片仍把旧第二章作为活动运行剧情")
	_expect(not story.has_stage("第三章·到警署"), "垂直切片仍把旧第三章作为活动运行剧情")
	_expect(_no_id_prefix(story, "C2_") and _no_id_prefix(story, "C3_"), "活动剧情表仍混入旧二、三章节点")
	_expect(_no_zhao_parent_relation(story), "活动剧情表仍把赵敬文写成沈砚舟父亲")

	_finish()


func _stage_contains(story: RefCounted, stage: String, field: String, needle: String) -> bool:
	for row: Dictionary in story.stage_rows(stage):
		if needle in str(row.get(field, "")):
			return true
	return false


func _stage_prefix_contains(story: RefCounted, stage_prefix: String, field: String, needle: String) -> bool:
	for row: Dictionary in story.rows:
		if not str(row.get("对话阶段", "")).begins_with(stage_prefix):
			continue
		if needle in str(row.get(field, "")):
			return true
	return false


func _stage_not_contains(story: RefCounted, stage: String, field: String, needle: String, required_condition: String) -> bool:
	for row: Dictionary in story.stage_rows(stage):
		if required_condition in str(row.get("出现条件", "")) and needle in str(row.get(field, "")):
			return false
	return true


func _has_player_line(story: RefCounted, needle: String) -> bool:
	for row: Dictionary in story.rows:
		if needle in str(row.get("玩家可选台词", "")):
			return true
	return false


func _no_id_prefix(story: RefCounted, prefix: String) -> bool:
	for row: Dictionary in story.rows:
		if str(row.get("自动ID", "")).begins_with(prefix):
			return false
	return true


func _no_zhao_parent_relation(story: RefCounted) -> bool:
	for row: Dictionary in story.rows:
		var joined := "\n".join([
			str(row.get("NPC台词", "")),
			str(row.get("玩家可选台词", "")),
			str(row.get("设计备注", "")),
			str(row.get("玩家因此知道什么", "")),
			str(row.get("状态写入（不显示）", "")),
		])
		if "赵敬文" in joined and ("我父亲" in joined or "你父亲" in joined or "他父亲" in joined or "父亲遗物" in joined):
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: v6 workbook migration")
		quit(0)
		return
	push_error("FAIL: %d v6 workbook migration assertions" % failures)
	quit(1)
