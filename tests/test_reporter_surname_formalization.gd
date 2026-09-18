extends SceneTree

const CSV_PATH := "res://content/程序生成_请勿手改/剧情剧本.csv"
const GameStateScript = preload("res://scripts/game_state.gd")

const REMOVED_NODE_IDS: Array[String] = [
	"P0002",
	"S0023", "S0023A", "S0023B", "S0023C", "S0023D", "S0023E", "S0023F",
	"C2_0052", "C2_0053", "C2_0054", "C2_0055", "C2_0056", "C2_0057", "C2_0058", "C2_0059",
]

var failures := 0


func _init() -> void:
	var csv_text := FileAccess.get_file_as_string(CSV_PATH)
	_expect(csv_text.contains("赵敬文"), "运行剧情数据尚未使用正式姓名‘赵敬文’")
	for forbidden: String in ["沈敬文", "沈老", "同姓", "本家"]:
		_expect(not csv_text.contains(forbidden), "运行剧情数据仍含已撤销内容：%s" % forbidden)
	for node_id: String in REMOVED_NODE_IDS:
		_expect(not csv_text.contains("\n%s," % node_id), "运行剧情数据仍含同姓说明链节点：%s" % node_id)

	var catalog: Array[String] = GameStateScript.KNOWLEDGE_CATALOG
	_expect(catalog.has("赵敬文是本埠知名记者"), "运行时知识目录没有同步正式姓名")
	for entry: String in catalog:
		_expect(not entry.contains("沈敬文") and not entry.contains("同姓") and not entry.contains("本家"), "运行时知识目录仍含旧姓名或同姓说明：%s" % entry)

	if failures == 0:
		print("PASS: reporter surname formalization is synchronized")
		quit(0)
	else:
		push_error("FAIL: %d reporter-surname assertions" % failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
