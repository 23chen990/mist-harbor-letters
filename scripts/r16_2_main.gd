extends Control

const RuntimeScript = preload("res://scripts/r16_2_runtime.gd")

const INK := Color("151916")
const PAPER := Color("d9cba8")
const PAPER_DARK := Color("9b8f73")
const RED := Color("9b4d43")

var runtime = RuntimeScript.new()
var header: Label
var meta_label: Label
var summary: RichTextLabel
var interaction: VBoxContainer
var status_label: Label
var back_button: Button
var puzzle_selection: Array[String] = []
var current_puzzle: Dictionary = {}


func _ready() -> void:
	_build_shell()
	if not runtime.load_runtime():
		_show_error("；".join(runtime.errors))
		return
	_render(runtime.start())


func _build_shell() -> void:
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
	columns.add_theme_constant_override("separation", 12)
	margin.add_child(columns)
	header = Label.new()
	header.add_theme_font_size_override("font_size", 30)
	header.add_theme_color_override("font_color", PAPER)
	columns.add_child(header)
	meta_label = Label.new()
	meta_label.add_theme_color_override("font_color", PAPER_DARK)
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columns.add_child(meta_label)
	var divider := HSeparator.new()
	columns.add_child(divider)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(scroll)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	scroll.add_child(body)
	summary = RichTextLabel.new()
	summary.bbcode_enabled = true
	summary.fit_content = true
	summary.custom_minimum_size = Vector2(0, 180)
	summary.add_theme_font_size_override("normal_font_size", 20)
	summary.add_theme_color_override("default_color", PAPER)
	body.add_child(summary)
	interaction = VBoxContainer.new()
	interaction.add_theme_constant_override("separation", 8)
	body.add_child(interaction)
	status_label = Label.new()
	status_label.add_theme_color_override("font_color", PAPER_DARK)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_add_status(body)
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
	for child: Node in interaction.get_children():
		child.queue_free()
	puzzle_selection.clear()
	if str(event.get("kind", "")) != "puzzle_wrong":
		current_puzzle.clear()
	var node := runtime.current_node()
	header.text = "%s  ·  %s" % [str(node.get("unit_id", "")), str(node.get("scene_title", ""))]
	meta_label.text = "%s\n%s" % [str(node.get("story_time", "")), str(node.get("location", ""))]
	summary.text = str(event.get("summary", node.get("player_text_summary", "")))
	status_label.text = ""
	back_button.visible = not runtime.choice_snapshots.is_empty()
	var kind := str(event.get("kind", ""))
	match kind:
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
		cards = display_order
	for card_id: String in cards:
		var card := Button.new()
		card.text = _card_text(puzzle, card_id)
		card.custom_minimum_size = Vector2(0, 48)
		card.pressed.connect(_append_puzzle_card.bind(card_id))
		interaction.add_child(card)
	var selected := Label.new()
	selected.text = "当前顺序：" + ">".join(puzzle_selection)
	selected.name = "PuzzleSelection"
	interaction.add_child(selected)
	var submit := Button.new()
	submit.text = "提交顺序"
	submit.pressed.connect(_submit_puzzle.bind(">".join(puzzle_selection)))
	interaction.add_child(submit)


func _append_puzzle_card(card_id: String) -> void:
	if not puzzle_selection.has(card_id):
		puzzle_selection.append(card_id)
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
		return "C  " + runtime.expected_invalid_card_text()
	for card: String in str(puzzle.get("cards", "")).split(" | ", false):
		if card.begins_with(card_id + " "):
			return card
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
