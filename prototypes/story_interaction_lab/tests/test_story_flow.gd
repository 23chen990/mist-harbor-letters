extends SceneTree

const REQUIRED_SCENES := [
	"S00", "S01", "S02",
	"C01", "C02", "C03", "C04", "C05", "C06", "C07", "C08", "C09",
	"C10", "C11", "C12", "C13", "C14", "C15", "C16", "C17-20", "C21-22", "END",
]

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var path := "res://story_flow.json"
	_expect(FileAccess.file_exists(path), "缺少数据驱动正文 story_flow.json")
	if not FileAccess.file_exists(path):
		_finish()
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	_expect(parsed is Dictionary, "story_flow.json 不是合法 JSON 对象")
	if not parsed is Dictionary:
		_finish()
		return
	var flow: Dictionary = parsed
	var nodes: Array = flow.get("nodes", [])
	_expect(not nodes.is_empty(), "story_flow.json 没有场景 beats")
	var by_id: Dictionary = {}
	var scenes: Dictionary = {}
	for raw_node in nodes:
		_expect(raw_node is Dictionary, "flow node 必须是对象")
		if not raw_node is Dictionary:
			continue
		var node: Dictionary = raw_node
		var node_id := str(node.get("id", ""))
		var scene_id := str(node.get("scene", ""))
		_expect(not node_id.is_empty(), "flow node 缺少稳定 id")
		_expect(not by_id.has(node_id), "重复 flow node id：%s" % node_id)
		by_id[node_id] = node
		scenes[scene_id] = true
		var lines: Array = node.get("lines", [])
		_expect(not lines.is_empty() or node.has("choices") or node.has("choice_source"), "%s 没有可见正文或真实选择" % node_id)
		for raw_line in lines:
			_expect(raw_line is Dictionary and not str(raw_line.get("text", "")).is_empty(), "%s 含空白正文" % node_id)
	for scene_id: String in REQUIRED_SCENES:
		_expect(scenes.has(scene_id), "缺少完整流程场次：%s" % scene_id)
	_expect(by_id.has(str(flow.get("start", ""))), "start 没有指向有效 node")
	for raw_node in nodes:
		if not raw_node is Dictionary:
			continue
		var node: Dictionary = raw_node
		_validate_target(node.get("next", ""), by_id, str(node.get("id", "")))
		for branch in node.get("next_rules", []):
			if branch is Dictionary:
				_validate_target(branch.get("target", ""), by_id, str(node.get("id", "")))
		for choice in node.get("choices", []):
			if choice is Dictionary:
				_validate_target(choice.get("target", ""), by_id, str(node.get("id", "")))
	var source := FileAccess.get_file_as_string("res://interaction_lab.gd")
	_expect(not source.contains("func _render_s00"), "正文仍散落在专用 _render_s00 函数")
	_expect(not source.contains("func _render_desk"), "正文仍散落在专用 _render_desk 函数")
	_expect(not source.contains("const OBSERVATION_TEXT"), "观察正文仍硬编码在 renderer")
	_expect(not source.contains("const CLAIM_TEXT"), "稿句正文仍硬编码在 renderer")
	_expect(not source.contains("_make_button(\"继续\""), "renderer 仍生成通用继续按钮")
	var all_visible_text := FileAccess.get_file_as_string(path)
	_expect(not all_visible_text.contains("这里只显示"), "玩家可见正文含实现口径式证据说明")
	_expect(not all_visible_text.contains("正文不再二次高亮或解释"), "后果页含作者层呈现说明")
	_expect(not all_visible_text.contains("从实际取得后可用"), "写稿页含作者层门控说明")
	_expect(flow.has("report_lead") and not str(flow.get("report_lead", "")).is_empty(), "缺少写稿页与次日报纸共用的固定首段")
	_expect(flow.get("claims", {}).has("appointment_pair"), "缺少 v19 的侧厅约见弱路线完整稿句")
	_expect(not all_visible_text.contains("沿 C03 已见过"), "玩家叙事泄露内部场次编号")
	_expect(not all_visible_text.contains("采访本只分【原件】与【速记】"), "采访本仍使用教程式元说明")
	var project_source := FileAccess.get_file_as_string("res://project.godot")
	_expect(project_source.contains("config/name=\"雾港来信\""), "窗口项目名不只保留作品名")
	_expect(project_source.contains("window/size/borderless=true"), "窗口未设为 borderless，标题栏可能显示 DEBUG")
	_finish()


func _validate_target(raw_target, by_id: Dictionary, owner: String) -> void:
	var target := str(raw_target)
	if target.is_empty():
		return
	_expect(by_id.has(target), "%s 指向不存在的 target：%s" % [owner, target])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: story flow data")
		quit(0)
	else:
		push_error("FAIL: %d story-flow assertions" % failures)
		quit(1)
