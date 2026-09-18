extends SceneTree

const WORKBOOK_PATH := "res://outputs/01a037d8-c4f0-70d3-bc69-8c3819094801/雾港来信_剧情作者工作簿.xlsx"
const IMPORTER_PATH := "res://tools/xlsx_story_importer.gd"
const TEST_CSV_PATH := "user://雾港来信_工作簿同步测试.csv"
const StoryRepositoryScript = preload("res://scripts/story_repository.gd")

var failures := 0


func _init() -> void:
	_expect(FileAccess.file_exists(WORKBOOK_PATH), "项目内缺少唯一剧情工作簿")
	if not ResourceLoader.exists(IMPORTER_PATH):
		_expect(false, "缺少 Excel → CSV 同步器")
		_finish()
		return
	var importer = load(IMPORTER_PATH).new()
	_expect(importer.synchronize(WORKBOOK_PATH, TEST_CSV_PATH), "工作簿同步失败：%s" % "；".join(importer.errors))
	var story = StoryRepositoryScript.new()
	_expect(story.load_story(TEST_CSV_PATH), "同步生成的 CSV 无法加载：%s" % "；".join(story.errors))
	_expect(story.row_count() == 107, "同步结果应包含序章 + v6 C01—C22 共 107 条活动剧情")
	_expect(story.headers.size() == 21 and story.headers.has("场景ID") and story.headers.has("状态写入（不显示）") and story.headers.has("演出/交互方式"), "v6 同步结果列结构不完整")
	_expect(_row_field_contains(story, "P0001", "NPC台词", "春和今晚的采访，你去。赵老死后，这条线一直没人接。"), "S00 没有同步压缩后的派活开场")
	_expect(_row_field_contains(story, "P0001", "NPC台词", "他死前还在跑春和？") and _row_field_equals(story, "P0001", "下一话题", "前序·春和旧线"), "S00 第一处主控回应与后继断链")
	_expect(_row_field_contains(story, "P0001B", "NPC台词", "跑了二十年。人也是在那儿没的。") and _row_field_contains(story, "P0001B", "NPC台词", "材料给我看看。"), "S00 没有同步死亡地点钩子与查看材料回应")
	_expect(_row_field_contains(story, "P0001C", "NPC台词", "十一点半截稿，稿子拿回来再看。") and _row_field_equals(story, "P0001C", "下一话题", "前序·自由探索"), "S00 领取材料没有进入工作桌")
	_expect(not _row_contains_text(story, "P0001", "再给我半个钟头") and not _row_contains_text(story, "P0001", "留几栏"), "S00 恢复了被否决的争取时间与版面往复")
	_expect(not _row_field_contains(story, "P0001", "NPC台词", "稿纸上，末句") and not _row_field_contains(story, "P0001", "NPC台词", "两个装卸工看见"), "S00 仍用旁白解释退稿稿纸")
	_expect(_row_field_contains(story, "P0001", "画面表现", "稿纸层叠") and _row_field_contains(story, "P0001", "画面表现", "醒目的‘撤’标记"), "S00 没有把退稿结果改为直接画面表达")
	_expect(_row_field_contains(story, "P0001", "演出/交互方式", "退稿稿件UI"), "S00 没有同步退稿稿件 UI 演出标签")
	_expect(not _row_field_contains(story, "P0001", "NPC台词", "有意思，站不住"), "S00 仍保留已删除的抽象退稿判词")
	_expect(not _row_field_contains(story, "P0001", "演出/交互方式", "内心"), "S00 不应再依赖主控心声说明动机")
	_expect(not _row_field_contains(story, "P0001", "状态写入（不显示）", "警方初步认定") and not _row_field_contains(story, "P0001", "状态写入（不显示）", "约二十天"), "玩家尚未读取死亡报道，S00 不得提前写入警方结论或死亡时间")
	_expect(not _row_contains_text(story, "P0008B", "又是春和") and not _row_contains_text(story, "P0008B", "放到今晚采访单旁"), "P0008B 仍由沈砚舟替玩家连接赵敬文之死与今晚采访")
	_expect(_row_field_equals(story, "P0003A", "下一话题", "前序·春和工作夹"), "春和工作夹热点仍跳到旧采访本教学页")
	_expect(_row_field_contains(story, "P0003A", "选择结果", "已查看春和工作夹") and not _row_field_contains(story, "P0003A", "选择结果", "旧采访本"), "春和工作夹热点仍写入旧采访本记录")
	_expect(_row_field_contains(story, "P0003A", "状态写入（不显示）", "C_CHECK_SHOW_FOLDER") and _row_field_contains(story, "P0003A", "状态写入（不显示）", "show_folder_checked=true"), "春和工作夹丢失原有技术选择状态")
	_expect(_row_field_equals(story, "P0015", "对话阶段", "前序·春和工作夹") and _row_field_equals(story, "P0015", "话题", "春和工作夹"), "P0015 没有恢复为春和工作夹物件页")
	_expect(_row_field_contains(story, "P0015", "NPC台词", "冬月初七晚八时开锣") and _row_field_contains(story, "P0015", "NPC台词", "林怀安领衔《夜渡》"), "春和工作夹没有同步 v6 演出安排")
	_expect(not _row_contains_text(story, "P0015", "戏班换角") and not _row_contains_text(story, "P0015", "教学") and not _row_contains_text(story, "P0015", "tutorial_angle_change_done"), "P0015 仍保留已撤下的文字教学页")
	_expect(not _row_contains_text(story, "P0012", "教学") and not _row_contains_text(story, "P0013", "教学"), "自由探索或离开条件仍保留旧教学备注")
	_expect(_row_field_equals(story, "P0005", "下一话题", "前序·函件正文"), "点击采访函留底后没有直接进入函件正文")
	_expect(_row_field_equals(story, "P0007", "对话阶段", "前序·函件正文") and _row_field_equals(story, "P0007", "玩家可选台词", "寻找回信"), "函件正文后没有同页“寻找回信”动作")
	_expect(_row_field_equals(story, "P0007", "下一话题", "前序·寻找回信结果") and _row_field_contains(story, "P0007", "演出/交互方式", "回函搜寻动画"), "寻找回信没有接入动画与结果阶段")
	_expect(_row_field_equals(story, "P0006", "对话阶段", "前序·寻找回信结果") and _row_field_equals(story, "P0006", "NPC台词", "没找到"), "回函搜寻结果不是用户确认的“没找到”")
	_expect(not _row_field_contains(story, "P0013", "出现条件", "退稿原稿") and not _row_field_contains(story, "P0013", "出现条件", "书信夹"), "离开报馆条件仍依赖已删除的旧宅中间记录")
	_expect(_row_field_contains(story, "P0013", "出现条件", "春和工作夹") and not _row_field_contains(story, "P0013", "出现条件", "旧采访本") and _row_field_contains(story, "P0013", "出现条件", "画满铅笔圈的旧报") and _row_field_contains(story, "P0013", "出现条件", "赵敬文采访函留底") and _row_field_contains(story, "P0013", "出现条件", "记者证与采访本"), "P0013 没有逐项匹配四个现行工作桌热点的状态写入")
	_expect(_row_field_contains(story, "P0013", "演出/交互方式", "4/4") and not _row_field_contains(story, "P0013", "演出/交互方式", "3/3"), "P0013 的进度备注不是四个现行热点对应的 4/4")
	_expect(_row_field_contains(story, "P0013", "演出/交互方式", "案件线索完成自动推进") and _row_field_contains(story, "P0013", "演出/交互方式", "不显示场景行动按钮"), "P0013 没有保留四查自动完成标签")
	_expect(_row_field_equals(story, "P0013", "下一话题", "前序·准备出发"), "四查后没有直接进入函件准备")
	for removed_id: String in ["P0016", "P0017", "P0018"]:
		_expect(not _has_row(story, removed_id), "工作簿仍同步已删除的自动推断：%s" % removed_id)
	_expect(not _row_contains_text(story, "P0005", "回函缺失") and not _row_contains_text(story, "P0006", "回函缺失") and not _row_contains_text(story, "P0007", "回函缺失") and not _row_contains_text(story, "P0008", "回函缺失"), "P0005—P0008 仍保留独立“回函缺失”入口")
	_expect(not _row_contains_text(story, "P0006", "留底旁空着；无回函附件。"), "搜寻结果仍保留旧占位说明")
	_expect(_has_player_line(story, "带上采访函留底") and _has_player_line(story, "抄下函件正文") and _has_player_line(story, "原件先不动，只记住要点"), "工作簿中的三种信件准备策略没有同步")
	_expect(_row_field_contains(story, "C04_030", "NPC台词", "原件在报馆。正文我记得。") and _row_field_contains(story, "C14_040", "NPC台词", "明天去报馆核验原件"), "已确认的第三项无纸面闭环没有同步")
	_expect(story.has_stage("第一章·第一章结尾") and not story.has_stage("第二章·开场") and not story.has_stage("第三章·到警署"), "旧二、三章运行数据没有停用")
	_expect(not FileAccess.file_exists("res://content/程序生成_请勿手改/剧情剧本_上次同步.csv"), "同步备份不能使用 .csv 扩展名，否则 Godot 会误当翻译表导入")
	for row: Dictionary in story.rows:
		_expect(not str(row.get("对话阶段", "")).begins_with("停用·"), "同步结果重新带回了停用旧版行")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_CSV_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_CSV_PATH + ".上次同步.bak"))
	_finish()


func _has_row(story: RefCounted, row_id: String) -> bool:
	for row: Dictionary in story.rows:
		if str(row.get("自动ID", "")) == row_id:
			return true
	return false


func _has_player_line(story: RefCounted, line: String) -> bool:
	for row: Dictionary in story.rows:
		if str(row.get("玩家可选台词", "")) == line:
			return true
	return false


func _row_field_contains(story: RefCounted, automatic_id: String, field: String, fragment: String) -> bool:
	for row: Dictionary in story.rows:
		if str(row.get("自动ID", "")) == automatic_id:
			return fragment in str(row.get(field, ""))
	return false


func _row_field_equals(story: RefCounted, automatic_id: String, field: String, expected: String) -> bool:
	for row: Dictionary in story.rows:
		if str(row.get("自动ID", "")) == automatic_id:
			return str(row.get(field, "")) == expected
	return false


func _row_contains_text(story: RefCounted, automatic_id: String, fragment: String) -> bool:
	for row: Dictionary in story.rows:
		if str(row.get("自动ID", "")) != automatic_id:
			continue
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
		print("PASS: Excel workbook is the single story authoring source")
		quit(0)
	else:
		push_error("FAIL: %d workbook-sync assertions" % failures)
		quit(1)
