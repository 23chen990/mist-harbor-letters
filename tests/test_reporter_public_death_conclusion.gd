extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const PUBLIC_DEATH_CONCLUSION := "赵敬文死在春和后巷石埠附近，警方认定为失足落水身亡"

var failures := 0


func _init() -> void:
	var catalog: Array[String] = GameStateScript.KNOWLEDGE_CATALOG
	_expect(catalog.has(PUBLIC_DEATH_CONCLUSION), "运行时知识目录没有同步赵敬文失足落水身亡的公开结论")
	for entry: String in catalog:
		if entry.contains("赵敬文"):
			_expect(not entry.contains("自杀") and not entry.contains("投水自尽"), "运行时知识目录仍含赵敬文自杀的旧公开口径：%s" % entry)

	if failures == 0:
		print("PASS: reporter public death conclusion is synchronized")
		quit(0)
	else:
		push_error("FAIL: %d reporter-public-death assertions" % failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
