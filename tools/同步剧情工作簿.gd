extends SceneTree

const WORKBOOK_PATH := "res://outputs/01a037d8-c4f0-70d3-bc69-8c3819094801/雾港来信_剧情作者工作簿.xlsx"
const GENERATED_CSV_PATH := "res://content/程序生成_请勿手改/剧情剧本.csv"
const ImporterScript = preload("res://tools/xlsx_story_importer.gd")


func _init() -> void:
	var importer = ImporterScript.new()
	if not importer.synchronize(WORKBOOK_PATH, GENERATED_CSV_PATH):
		for message: String in importer.errors:
			push_error(message)
		print("同步失败：请修正上面的提示后重新双击“同步剧情工作簿.command”。")
		quit(1)
		return
	var repository = load("res://scripts/story_repository.gd").new()
	if not repository.load_story(GENERATED_CSV_PATH):
		for message: String in repository.errors:
			push_error(message)
		quit(1)
		return
	print("同步完成：Excel 工作簿 → 游戏剧情数据")
	print("现行剧情：%d 行" % repository.row_count())
	print("以后只修改：%s" % ProjectSettings.globalize_path(WORKBOOK_PATH))
	print("不要手动修改：%s" % ProjectSettings.globalize_path(GENERATED_CSV_PATH))
	quit(0)
