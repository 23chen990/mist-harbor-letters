extends Control

const RuntimeScript = preload("res://scripts/r16_2_runtime.gd")

const INK := Color("151916")
const PAPER := Color("d9cba8")
const PAPER_DARK := Color("9b8f73")
const RED := Color("9b4d43")

var runtime = RuntimeScript.new()
var header: Label
var meta_label: Label
var progress_label: Label
var speaker_label: Label
var summary: RichTextLabel
var interaction: VBoxContainer
var status_label: Label
var back_button: Button
var notebook_button: Button
var notebook_panel: PanelContainer
var notebook_text: RichTextLabel
var puzzle_selection: Array[String] = []
var current_puzzle: Dictionary = {}


func _ready() -> void:
	_build_shell()
	if not runtime.load_runtime():
		_show_error("；".join(runtime.errors))
		return
	_render(runtime.start())


func _build_shell() -> void:
	theme = Theme.new()
	var text_font := SystemFont.new()
	text_font.font_names = PackedStringArray(["PingFang SC", "Microsoft YaHei", "Noto Sans CJK SC", "WenQuanYi Zen Hei"])
	theme.default_font = text_font
	theme.set_font_size("font_size", "Button", 20)
	theme.set_color("font_color", "Button", PAPER)
	for state_name: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("272e28") if state_name in ["hover", "pressed"] else Color("1b211d")
		style.border_color = PAPER_DARK if state_name in ["hover", "focus"] else Color("4b5044")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.content_margin_left = 18
		style.content_margin_right = 18
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		theme.set_stylebox(state_name, "Button", style)
	var background := ColorRect.new()
	background.color = INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)
	var columns := VBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	margin.add_child(columns)
	header = Label.new()
	header.add_theme_font_size_override("font_size", 30)
	header.add_theme_color_override("font_color", PAPER)
	columns.add_child(header)
	var toolbar := HBoxContainer.new()
	toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(toolbar)
	progress_label = Label.new()
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label.add_theme_color_override("font_color", PAPER_DARK)
	toolbar.add_child(progress_label)
	notebook_button = Button.new()
	notebook_button.text = "采访本"
	notebook_button.custom_minimum_size = Vector2(140, 48)
	notebook_button.pressed.connect(_toggle_notebook)
	toolbar.add_child(notebook_button)
	meta_label = Label.new()
	meta_label.add_theme_color_override("font_color", PAPER_DARK)
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columns.add_child(meta_label)
	var divider := HSeparator.new()
	columns.add_child(divider)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	scroll.add_child(body)
	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 22)
	speaker_label.add_theme_color_override("font_color", RED)
	speaker_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(speaker_label)
	summary = RichTextLabel.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.bbcode_enabled = true
	summary.fit_content = true
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.custom_minimum_size = Vector2(0, 180)
	summary.add_theme_font_size_override("normal_font_size", 20)
	summary.add_theme_color_override("default_color", PAPER)
	body.add_child(summary)
	interaction = VBoxContainer.new()
	interaction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	interaction.add_theme_constant_override("separation", 8)
	body.add_child(interaction)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.add_theme_color_override("font_color", PAPER_DARK)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_add_status(body)
	notebook_panel = PanelContainer.new()
	notebook_panel.visible = false
	notebook_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	notebook_panel.custom_minimum_size = Vector2(680, 420)
	var notebook_margin := MarginContainer.new()
	notebook_margin.add_theme_constant_override("margin_left", 24)
	notebook_margin.add_theme_constant_override("margin_right", 24)
	notebook_margin.add_theme_constant_override("margin_top", 20)
	notebook_margin.add_theme_constant_override("margin_bottom", 20)
	notebook_panel.add_child(notebook_margin)
	notebook_text = RichTextLabel.new()
	notebook_text.bbcode_enabled = true
	notebook_text.fit_content = true
	notebook_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notebook_text.add_theme_font_size_override("normal_font_size", 18)
	notebook_text.add_theme_color_override("default_color", PAPER)
	notebook_margin.add_child(notebook_text)
	add_child(notebook_panel)
	back_button = Button.new()
	back_button.text = "回到上一次选择"
	back_button.visible = false
	back_button.pressed.connect(_rollback_latest)
	columns.add_child(back_button)


func _body_add_status(body: VBoxContainer) -> void:
	# Kept as a tiny helper so the status label remains outside interaction rows.
	body.add_child(status_label)


func _render(event: Dictionary) -> void:
	if event.is_empty():
		return
	_clear_interaction()
	puzzle_selection.clear()
	if str(event.get("kind", "")) != "puzzle_wrong":
		current_puzzle.clear()
	var node := runtime.current_node()
	header.text = "%s  ·  %s" % [str(node.get("unit_id", "")), str(node.get("scene_title", ""))]
	meta_label.text = "%s\n%s" % [str(node.get("story_time", "")), str(node.get("location", ""))]
	progress_label.text = _progress_text(node)
	var raw_summary := str(event.get("summary", runtime.current_text))
	speaker_label.text = _speaker_name(raw_summary)
	summary.text = _speaker_body(raw_summary)
	status_label.text = ""
	back_button.visible = not runtime.choice_snapshots.is_empty()
	_refresh_notebook()
	var kind := str(event.get("kind", ""))
	match kind:
		"dialogue": _render_dialogue(event)
		"choice_feedback": _render_feedback()
		"choice": _render_choices(event.get("payload", {}).get("choices", []))
		"headline_selected": _render_headline_confirmation(event.get("payload", {}))
		"draft_preview": _render_preview(event.get("payload", {}))
		"puzzle": _render_puzzle(event.get("payload", {}))
		"ending": _render_ending(event)
		"puzzle_wrong":
			status_label.text = str(event.get("feedback", "顺序不对，请再看相邻两张卡。"))
			var retry_puzzle: Dictionary = runtime.data.get("micro_puzzles", {}).get(str(event.get("puzzle_id", "")), {})
			_render_puzzle(retry_puzzle)
		"error": _show_error(str(event.get("error", "未知运行时错误")))
		_:
			var next := Button.new()
			next.text = "继续"
			next.pressed.connect(_advance_automatic)
			interaction.add_child(next)


func _clear_interaction() -> void:
	for child: Node in interaction.get_children():
		interaction.remove_child(child)
		child.queue_free()


func _render_dialogue(event: Dictionary) -> void:
	var payload: Dictionary = event.get("payload", {})
	if bool(payload.get("is_player_response", false)):
		# The protagonist never speaks automatically: expose the authored line
		# as the button itself, including the single-response case.
		speaker_label.text = "沈砚舟（你的回应）"
		summary.text = ""
		var response := Button.new()
		response.text = str(payload.get("response_text", ""))
		response.set_meta("player_response", true)
		response.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		response.custom_minimum_size = Vector2(0, 58)
		response.pressed.connect(_advance_dialogue)
		interaction.add_child(response)
		return
	var next := Button.new()
	next.text = "继续"
	next.custom_minimum_size = Vector2(0, 58)
	next.pressed.connect(_advance_dialogue)
	interaction.add_child(next)


func _progress_text(node: Dictionary) -> String:
	var chapter := ""
	for chapter_id: Variant in runtime.data.get("chapters", {}).keys():
		var row: Dictionary = runtime.data["chapters"][chapter_id]
		var range_text := str(row.get("range", ""))
		if range_text.contains(str(node.get("unit_id", ""))):
			chapter = "%s《%s》" % [str(chapter_id), str(row.get("title", ""))]
			break
	return chapter if not chapter.is_empty() else "冷开场"


func _speaker_name(text: String) -> String:
	var clean := text.strip_edges()
	if clean.begins_with("旁白："):
		return "旁白"
	var colon := clean.find("：")
	if colon > 0 and colon < 14:
		return clean.substr(0, colon)
	return ""


func _speaker_body(text: String) -> String:
	var lines := text.split("\n")
	var result: Array[String] = []
	for line: String in lines:
		var clean := line.strip_edges()
		if clean.is_empty():
			continue
		var colon := clean.find("：")
		if colon > 0 and colon < 14:
			result.append(clean.substr(colon + 1).strip_edges())
		else:
			result.append(clean)
	return "\n".join(result)


func _refresh_notebook() -> void:
	if notebook_text == null:
		return
	var lines: Array[String] = ["[font_size=24]采访本[/font_size]", ""]
	if runtime.dialogue_history.is_empty():
		lines.append("还没有记录。每一句已读对白会留在这里，方便回看现场信息。")
	else:
		lines.append("最近读到：")
		var start := maxi(0, runtime.dialogue_history.size() - 10)
		for index in range(start, runtime.dialogue_history.size()):
			lines.append("· " + runtime.dialogue_history[index])
	lines.append("")
	lines.append("采访本只保留原话和时间地点，不自动替你判断谁说得对。")
	notebook_text.text = "\n".join(lines)


func _toggle_notebook() -> void:
	if notebook_panel == null:
		return
	notebook_panel.visible = not notebook_panel.visible
	if notebook_panel.visible:
		_refresh_notebook()


func _render_feedback() -> void:
	var next := Button.new()
	next.text = "继续"
	next.custom_minimum_size = Vector2(0, 58)
	next.pressed.connect(func() -> void: _render(runtime.advance_choice_feedback()))
	interaction.add_child(next)


func _render_choices(rows: Array) -> void:
	for raw_choice: Variant in rows:
		var choice: Dictionary = raw_choice
		var button := Button.new()
		button.text = str(choice.get("option_text", ""))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 54)
		button.pressed.connect(_choose.bind(str(choice.get("choice_id", ""))))
		interaction.add_child(button)


func _render_headline_confirmation(payload: Dictionary) -> void:
	var choice: Dictionary = payload.get("choice", {})
	var selected := Label.new()
	selected.text = "已选标题：\n" + str(choice.get("option_text", ""))
	selected.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected.add_theme_font_size_override("font_size", 23)
	interaction.add_child(selected)
	var send := Button.new()
	send.text = "送排"
	send.custom_minimum_size = Vector2(0, 58)
	send.pressed.connect(_confirm_headline)
	interaction.add_child(send)


func _render_preview(preview: Dictionary) -> void:
	var title := Label.new()
	title.text = "整版清样 · 尚未发行"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", RED)
	interaction.add_child(title)
	var headline := Label.new()
	headline.text = str(preview.get("headline", ""))
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headline.add_theme_font_size_override("font_size", 25)
	headline.add_theme_color_override("font_color", PAPER)
	interaction.add_child(headline)
	var includes := Label.new()
	includes.text = "自动纳入：" + "；".join(preview.get("included", []))
	includes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interaction.add_child(includes)
	var excludes := Label.new()
	excludes.text = "自动保护：" + "；".join(preview.get("excluded", []))
	excludes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interaction.add_child(excludes)
	var confirm := Button.new()
	confirm.text = "确认交排"
	confirm.custom_minimum_size = Vector2(0, 58)
	confirm.pressed.connect(_confirm_typeset)
	interaction.add_child(confirm)


func _render_puzzle(puzzle: Dictionary) -> void:
	current_puzzle = puzzle
	var prompt := Label.new()
	prompt.text = str(puzzle.get("prompt", ""))
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_theme_font_size_override("font_size", 22)
	interaction.add_child(prompt)
	var puzzle_id := str(puzzle.get("puzzle_id", ""))
	if puzzle_id == "P_U27_PROOF":
		for card_id: String in ["A", "B", "C_DYNAMIC"]:
			var card := Button.new()
			card.text = _card_text(puzzle, card_id)
			card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.custom_minimum_size = Vector2(0, 54)
			card.pressed.connect(_submit_puzzle.bind(card_id))
			interaction.add_child(card)
		return
	var cards := _parse_cards(str(puzzle.get("cards", "")))
	var display_order := str(puzzle.get("initial_display_order", "")).split(">", false)
	if display_order.size() > 1:
		cards.assign(display_order)
	for card_id: String in cards:
		var card := Button.new()
		card.text = _card_text(puzzle, card_id)
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.disabled = puzzle_selection.has(card_id)
		card.custom_minimum_size = Vector2(0, 48)
		card.pressed.connect(_append_puzzle_card.bind(card_id))
		interaction.add_child(card)
	var selected := Label.new()
	var selected_text: Array[String] = []
	for index in range(puzzle_selection.size()):
		selected_text.append("%d. %s" % [index + 1, _card_text(puzzle, puzzle_selection[index])])
	selected.text = "当前顺序：\n" + "\n".join(selected_text)
	selected.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected.name = "PuzzleSelection"
	interaction.add_child(selected)
	var submit := Button.new()
	submit.text = "提交顺序"
	submit.disabled = puzzle_selection.size() != cards.size()
	submit.pressed.connect(_submit_puzzle.bind(">".join(puzzle_selection)))
	interaction.add_child(submit)
	var reset := Button.new()
	reset.text = "重新排列"
	reset.disabled = puzzle_selection.is_empty()
	reset.pressed.connect(_reset_puzzle)
	interaction.add_child(reset)


func _append_puzzle_card(card_id: String) -> void:
	if not puzzle_selection.has(card_id):
		puzzle_selection.append(card_id)
	_clear_interaction()
	_render_puzzle(current_puzzle)


func _reset_puzzle() -> void:
	puzzle_selection.clear()
	_clear_interaction()
	_render_puzzle(current_puzzle)


func _submit_puzzle(answer: String) -> void:
	var event := runtime.solve_puzzle(answer)
	_render(event)


func _choose(choice_id: String) -> void:
	_render(runtime.choose(choice_id))


func _confirm_headline() -> void:
	_render(runtime.confirm_headline())


func _confirm_typeset() -> void:
	_render(runtime.confirm_typeset())


func _advance_automatic() -> void:
	var node := runtime.current_node()
	var next_node := str(node.get("next_node", ""))
	if next_node.is_empty():
		return
	_render(runtime.enter_node(next_node))


func _advance_dialogue() -> void:
	_render(runtime.advance_dialogue())


func _rollback_latest() -> void:
	var keys: Array = runtime.choice_snapshots.keys()
	if keys.is_empty():
		return
	_render(runtime.rollback(str(keys[keys.size() - 1])))


func _render_ending(event: Dictionary) -> void:
	var ending_id := str(event.get("ending_id", ""))
	var ending: Dictionary = runtime.data.get("endings", {}).get(ending_id, {})
	var label := Label.new()
	label.text = "%s\n%s" % [ending_id, str(ending.get("name", ""))]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 28)
	interaction.add_child(label)
	var body := Label.new()
	body.text = str(ending.get("route_meaning", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interaction.add_child(body)


func _card_text(puzzle: Dictionary, card_id: String) -> String:
	if card_id == "C_DYNAMIC":
		return runtime.expected_invalid_card_text()
	for card: String in str(puzzle.get("cards", "")).split(" | ", false):
		if card.begins_with(card_id + " "):
			return card.substr(card_id.length() + 1)
	return card_id


func _parse_cards(text: String) -> Array[String]:
	var result: Array[String] = []
	for card: String in text.split(" | ", false):
		var id := card.strip_edges().substr(0, 1)
		if not id.is_empty():
			result.append(id)
	return result


func _show_error(message: String) -> void:
	if status_label:
		status_label.text = message
