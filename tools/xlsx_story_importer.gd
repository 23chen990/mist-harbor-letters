extends RefCounted
class_name FogHarborXlsxStoryImporter

const STORY_SHEET := "剧情剧本"
const EXPECTED_COLUMNS := 21
const StoryRepositoryScript = preload("res://scripts/story_repository.gd")

var errors: Array[String] = []


func synchronize(workbook_path: String, csv_path: String) -> bool:
	errors.clear()
	var rows := extract_story_rows(workbook_path)
	if rows.is_empty():
		return false
	if not _prepare_rows(rows):
		return false
	return _write_validated_csv(rows, csv_path)


func extract_story_rows(workbook_path: String) -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	var absolute_path := ProjectSettings.globalize_path(workbook_path)
	if not FileAccess.file_exists(absolute_path):
		errors.append("找不到剧情工作簿：%s" % absolute_path)
		return result
	var archive := ZIPReader.new()
	var open_error := archive.open(absolute_path)
	if open_error != OK:
		errors.append("无法打开剧情工作簿（错误 %d）。请先在 Excel 中保存并关闭文件。" % open_error)
		return result
	var worksheet_path := _find_worksheet_path(archive, STORY_SHEET)
	if worksheet_path.is_empty():
		archive.close()
		return result
	var shared_strings := _read_shared_strings(archive)
	result = _read_worksheet(archive, worksheet_path, shared_strings)
	archive.close()
	if result.is_empty():
		errors.append("“%s”工作表没有可同步的内容。" % STORY_SHEET)
	return result


func _find_worksheet_path(archive: ZIPReader, sheet_name: String) -> String:
	var workbook_xml := archive.read_file("xl/workbook.xml")
	var relationships_xml := archive.read_file("xl/_rels/workbook.xml.rels")
	if workbook_xml.is_empty() or relationships_xml.is_empty():
		errors.append("工作簿结构不完整：缺少 workbook.xml 或关系文件。")
		return ""
	var relationship_id := ""
	var parser := XMLParser.new()
	if parser.open_buffer(workbook_xml) != OK:
		errors.append("无法读取工作簿目录。")
		return ""
	while parser.read() == OK:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT or _local_name(parser.get_node_name()) != "sheet":
			continue
		if _attribute(parser, "name") == sheet_name:
			relationship_id = _attribute(parser, "id")
			break
	if relationship_id.is_empty():
		errors.append("工作簿中找不到“%s”工作表；请不要修改工作表名称。" % sheet_name)
		return ""
	if parser.open_buffer(relationships_xml) != OK:
		errors.append("无法读取工作表关系。")
		return ""
	while parser.read() == OK:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT or _local_name(parser.get_node_name()) != "Relationship":
			continue
		if _attribute(parser, "Id") == relationship_id:
			var target := _attribute(parser, "Target").trim_prefix("/")
			if target.begins_with("xl/"):
				return target
			return "xl/" + target.trim_prefix("../")
	errors.append("“%s”工作表缺少有效的数据文件。" % sheet_name)
	return ""


func _read_shared_strings(archive: ZIPReader) -> Array[String]:
	var result: Array[String] = []
	if not archive.file_exists("xl/sharedStrings.xml"):
		return result
	var parser := XMLParser.new()
	if parser.open_buffer(archive.read_file("xl/sharedStrings.xml")) != OK:
		errors.append("无法读取 Excel 共享文字。")
		return result
	var inside_item := false
	var inside_text := false
	var current := ""
	while parser.read() == OK:
		var node_type := parser.get_node_type()
		var node_name := _local_name(parser.get_node_name()) if node_type == XMLParser.NODE_ELEMENT or node_type == XMLParser.NODE_ELEMENT_END else ""
		if node_type == XMLParser.NODE_ELEMENT:
			if node_name == "si":
				inside_item = true
				current = ""
			elif node_name == "t" and inside_item:
				inside_text = true
		elif node_type == XMLParser.NODE_TEXT and inside_text:
			current += parser.get_node_data()
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if node_name == "t":
				inside_text = false
			elif node_name == "si":
				result.append(current)
				inside_item = false
	return result


func _read_worksheet(archive: ZIPReader, worksheet_path: String, shared_strings: Array[String]) -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	var xml := archive.read_file(worksheet_path)
	if xml.is_empty():
		errors.append("剧情工作表数据为空。")
		return result
	var parser := XMLParser.new()
	if parser.open_buffer(xml) != OK:
		errors.append("无法解析“%s”工作表。" % STORY_SHEET)
		return result
	var current_row := -1
	var current_cells: Dictionary = {}
	var current_column := -1
	var current_type := ""
	var current_value := ""
	var capture_value := false
	while parser.read() == OK:
		var node_type := parser.get_node_type()
		var node_name := _local_name(parser.get_node_name()) if node_type == XMLParser.NODE_ELEMENT or node_type == XMLParser.NODE_ELEMENT_END else ""
		if node_type == XMLParser.NODE_ELEMENT:
			if node_name == "row":
				current_row = int(_attribute(parser, "r"))
				current_cells.clear()
			elif node_name == "c" and current_row >= 0:
				current_column = _column_index(_attribute(parser, "r"))
				current_type = _attribute(parser, "t")
				current_value = ""
			elif current_column >= 0 and (node_name == "v" or node_name == "t"):
				capture_value = true
		elif node_type == XMLParser.NODE_TEXT and capture_value:
			current_value += parser.get_node_data()
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if node_name == "v" or node_name == "t":
				capture_value = false
			elif node_name == "c" and current_column >= 0:
				var resolved := _resolve_cell_value(current_value, current_type, shared_strings)
				if current_column < EXPECTED_COLUMNS and not resolved.is_empty():
					current_cells[current_column] = resolved
				current_column = -1
				current_type = ""
				current_value = ""
				capture_value = false
			elif node_name == "row" and current_row >= 0:
				if not current_cells.is_empty():
					var row := PackedStringArray()
					row.resize(EXPECTED_COLUMNS)
					for column: int in current_cells:
						row[column] = str(current_cells[column])
					result.append(row)
				current_row = -1
				current_cells.clear()
	return result


func _resolve_cell_value(value: String, cell_type: String, shared_strings: Array[String]) -> String:
	if cell_type == "s":
		var index := int(value)
		if index >= 0 and index < shared_strings.size():
			return shared_strings[index]
		return ""
	if cell_type == "b":
		return "是" if value == "1" else "否"
	return value


func _prepare_rows(rows: Array[PackedStringArray]) -> bool:
	if rows.is_empty():
		errors.append("剧情工作表没有表头。")
		return false
	var headers := rows[0]
	if headers.size() != EXPECTED_COLUMNS:
		errors.append("“%s”应有 %d 列，当前为 %d 列。" % [STORY_SHEET, EXPECTED_COLUMNS, headers.size()])
		return false
	var id_column := headers.find("自动ID")
	if id_column < 0:
		errors.append("剧情工作表缺少“自动ID”列。")
		return false
	var largest := 0
	var used: Dictionary = {}
	for row_index in range(1, rows.size()):
		var row := rows[row_index]
		row.resize(EXPECTED_COLUMNS)
		var current := row[id_column].strip_edges()
		if current.begins_with("S") and current.substr(1).is_valid_int():
			largest = maxi(largest, int(current.substr(1)))
		if not current.is_empty():
			if used.has(current):
				errors.append("自动ID重复：%s（Excel 第 %d 行）" % [current, row_index + 1])
				return false
			used[current] = true
	for row_index in range(1, rows.size()):
		if rows[row_index][id_column].strip_edges().is_empty():
			largest += 1
			rows[row_index][id_column] = "S%04d" % largest
	return true


func _write_validated_csv(rows: Array[PackedStringArray], csv_path: String) -> bool:
	var target := ProjectSettings.globalize_path(csv_path)
	var parent := target.get_base_dir()
	var directory_error := DirAccess.make_dir_recursive_absolute(parent)
	if directory_error != OK:
		errors.append("无法创建程序生成目录：%s" % parent)
		return false
	var temporary := target + ".tmp"
	var output := FileAccess.open(temporary, FileAccess.WRITE)
	if output == null:
		errors.append("无法写入临时剧情表：%s" % temporary)
		return false
	output.store_string("﻿")
	for source_row: PackedStringArray in rows:
		var row := source_row.duplicate()
		for column in row.size():
			row[column] = row[column].replace("\r\n", "\n").replace("\r", "\n").replace("\n", "\\n")
		output.store_csv_line(row, ",")
	output.close()
	var repository = StoryRepositoryScript.new()
	if not repository.load_story(temporary):
		errors.append_array(repository.errors)
		DirAccess.remove_absolute(temporary)
		return false
	if FileAccess.file_exists(target):
		# 备份不能继续使用 .csv 扩展名，否则 Godot 会把它误判为翻译表并生成大量资源。
		var backup := target + ".上次同步.bak"
		var backup_error := DirAccess.copy_absolute(target, backup)
		if backup_error != OK:
			errors.append("无法备份上一次生成的剧情表（错误 %d）。" % backup_error)
			DirAccess.remove_absolute(temporary)
			return false
	var copy_error := DirAccess.copy_absolute(temporary, target)
	DirAccess.remove_absolute(temporary)
	if copy_error != OK:
		errors.append("无法更新程序生成的剧情表（错误 %d）。" % copy_error)
		return false
	return true


func _column_index(cell_reference: String) -> int:
	var letters := ""
	for text: String in cell_reference:
		if text >= "A" and text <= "Z":
			letters += text
		else:
			break
	var result := 0
	for letter: String in letters:
		result = result * 26 + letter.unicode_at(0) - 64
	return result - 1


func _attribute(parser: XMLParser, requested_name: String) -> String:
	for index in parser.get_attribute_count():
		var attribute_name := parser.get_attribute_name(index)
		if attribute_name == requested_name or _local_name(attribute_name) == requested_name:
			return parser.get_attribute_value(index)
	return ""


func _local_name(qualified_name: String) -> String:
	var pieces := qualified_name.split(":")
	return pieces[pieces.size() - 1]
