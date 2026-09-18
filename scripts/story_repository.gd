extends RefCounted
class_name FogHarborStoryRepository

const REQUIRED_COLUMNS: Array[String] = [
	"自动ID", "场景ID", "场景", "对话阶段", "阶段顺序", "人物", "内容类型", "话题", "NPC台词",
	"玩家可选台词", "出现条件", "选择结果", "下一话题", "动作/表情备注", "设计备注",
	"对话动机", "画面表现", "玩家因此知道什么", "状态写入（不显示）", "是否说出口", "演出/交互方式"
]

var rows: Array[Dictionary] = []
var errors: Array[String] = []
var headers: PackedStringArray = []
var _stages: Dictionary = {}


func load_story(path: String) -> bool:
	rows.clear()
	errors.clear()
	_stages.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("无法打开：%s" % path)
		return false
	headers = file.get_csv_line(",")
	for required: String in REQUIRED_COLUMNS:
		if not headers.has(required):
			errors.append("缺少列“%s”" % required)
	if not errors.is_empty():
		return false
	var seen_ids: Dictionary = {}
	var line_number := 1
	while not file.eof_reached():
		var values := file.get_csv_line(",")
		line_number += 1
		if values.size() == 1 and values[0].strip_edges().is_empty():
			continue
		if values.size() > headers.size():
			errors.append("第 %d 行列数过多（应为 %d，实际 %d）" % [line_number, headers.size(), values.size()])
			continue
		values.resize(headers.size())
		var row: Dictionary = {}
		for index in headers.size():
			row[headers[index]] = values[index].replace("\\n", "\n").strip_edges()
		var row_id := str(row["自动ID"])
		if row_id.is_empty():
			errors.append("第 %d 行缺少自动ID；请保存 Excel 后运行“同步剧情工作簿.command”" % line_number)
		elif seen_ids.has(row_id):
			errors.append("自动ID重复：%s" % row_id)
		seen_ids[row_id] = true
		rows.append(row)
		var stage := str(row["对话阶段"])
		if not _stages.has(stage):
			_stages[stage] = []
		_stages[stage].append(row)
	_validate_links()
	return errors.is_empty()


func _validate_links() -> void:
	for row: Dictionary in rows:
		var next_stage := str(row.get("下一话题", ""))
		if not next_stage.is_empty() and not _stages.has(next_stage):
			errors.append("%s 的“下一话题”不存在：%s" % [row.get("自动ID", "未知行"), next_stage])


func row_count() -> int:
	return rows.size()


func has_stage(stage: String) -> bool:
	return _stages.has(stage)


func stage_rows(stage: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Dictionary in _stages.get(stage, []):
		result.append(row)
	return result


func presentation_rows(stage: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Dictionary in stage_rows(stage):
		if str(row.get("玩家可选台词", "")).is_empty():
			result.append(row)
	return result


func available_presentations(stage: String, state: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Dictionary in presentation_rows(stage):
		if state.condition_met(str(row.get("出现条件", "始终"))) and _required_knowledge_met(row, state):
			result.append(row)
	return result


func available_choices(stage: String, state: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var source_stage := _choice_source_stage(stage)
	for row: Dictionary in stage_rows(source_stage):
		if str(row.get("玩家可选台词", "")).is_empty():
			continue
		if state.condition_met(str(row.get("出现条件", "始终"))) and _required_knowledge_met(row, state):
			result.append(row)
	return result


func _choice_source_stage(stage: String) -> String:
	for row: Dictionary in stage_rows(stage):
		if str(row.get("内容类型", "")) not in ["对话Hub", "场景探索", "限时观察"]:
			continue
		var linked_stage := str(row.get("下一话题", ""))
		if not linked_stage.is_empty():
			return linked_stage
	return stage


func _required_knowledge_met(row: Dictionary, state: RefCounted) -> bool:
	for fact: String in str(row.get("玩家必须已经知道什么", "")).split("；", false):
		if not state.knows(fact.strip_edges()):
			return false
	return true


func first_stage_row(stage: String) -> Dictionary:
	var stage_data := stage_rows(stage)
	return stage_data[0] if not stage_data.is_empty() else {}
