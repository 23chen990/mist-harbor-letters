extends Control

## 固定正文与场次图来自 story_flow.json；本脚本只负责通用呈现和状态动作。

const StateScript = preload("res://interaction_state.gd")

const INK := Color("0b100e")
const PANEL := Color("151e19")
const PANEL_LIGHT := Color("202b24")
const PAPER := Color("e6dcc1")
const JADE := Color("87b49b")
const JADE_DARK := Color("38594a")
const GOLD := Color("d2b16c")

const PROBE_LABELS := {
	"desk_gap": "他桌上没留您的回信。",
	"no_reply": "您没有回。",
	"reply_missing": "您的回信没到他手里。",
}

var state
var flow: Dictionary = {}
var nodes_by_id: Dictionary = {}
var current_node_id := ""
var visited_scenes: Array[String] = []
var visible_lines: Array[Dictionary] = []
var line_cursor := 0
var protagonist_line_committed := false
var render_generation := 0
var ui_accept_after_msec := 0

var shell: Control
var scroll: ScrollContainer
var body: VBoxContainer
var maximize_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()
	_load_flow()
	_start_new_run()


func _load_flow() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://story_flow.json"))
	if not parsed is Dictionary:
		push_error("story_flow.json 无法解析")
		return
	flow = parsed
	nodes_by_id.clear()
	for raw_node in flow.get("nodes", []):
		if raw_node is Dictionary:
			var node: Dictionary = raw_node
			nodes_by_id[str(node.get("id", ""))] = node


func _start_new_run() -> void:
	state = StateScript.new()
	visited_scenes.clear()
	_enter_node(str(flow.get("start", "")))


func current_beat_id() -> String:
	return current_node_id


func current_scene_id() -> String:
	return str(_current_node().get("scene", ""))


func current_line_index() -> int:
	return line_cursor


func has_active_line() -> bool:
	return line_cursor >= 0 and line_cursor < visible_lines.size()


func minimize_window() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)


func toggle_window_size() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_MAXIMIZED or mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	_sync_window_controls()


func close_window() -> void:
	get_tree().quit()


func advance_line() -> bool:
	if not has_active_line():
		return false
	if _current_line_is_protagonist() and not protagonist_line_committed:
		return false
	var previous_cursor := line_cursor
	line_cursor += 1
	protagonist_line_committed = false
	if has_active_line():
		_render()
		return true
	if not _available_choices().is_empty():
		_render()
		return true
	if advance():
		return true
	line_cursor = previous_cursor
	protagonist_line_committed = true
	_render()
	return false


func advance() -> bool:
	var node := _current_node()
	var target := ""
	for raw_rule in node.get("next_rules", []):
		if raw_rule is Dictionary:
			var rule: Dictionary = raw_rule
			if _conditions_met(rule.get("requires", {})):
				target = str(rule.get("target", ""))
				break
	if target.is_empty():
		target = str(node.get("next", ""))
	if target.is_empty() or not nodes_by_id.has(target):
		return false
	_enter_node(target)
	return true


func available_choice_ids() -> Array:
	var ids: Array[String] = []
	for choice: Dictionary in _available_choices():
		ids.append(str(choice.get("id", "")))
	return ids


func choose_option(choice_id: String) -> bool:
	var selected: Dictionary = {}
	for choice: Dictionary in _available_choices():
		if str(choice.get("id", "")) == choice_id:
			selected = choice
			break
	if selected.is_empty():
		return false
	if choice_id == "speak_current_line":
		protagonist_line_committed = true
		_render()
		return true
	if not _apply_effects(selected.get("effects", [])):
		return false
	var target := str(selected.get("target", ""))
	if choice_id.begins_with("claim_"):
		_render()
		return true
	if choice_id == "submit_report":
		_enter_node("c21_consequence")
		return true
	if choice_id == "check_ledger":
		_enter_node("end")
		return true
	if target.is_empty() or not nodes_by_id.has(target):
		return false
	_enter_node(target)
	return true


func _enter_node(node_id: String) -> void:
	if not nodes_by_id.has(node_id):
		push_error("story flow 缺少 node：%s" % node_id)
		return
	current_node_id = node_id
	line_cursor = 0
	protagonist_line_committed = false
	var scene_id := current_scene_id()
	if visited_scenes.is_empty() or visited_scenes[-1] != scene_id:
		visited_scenes.append(scene_id)
	_apply_effects(_current_node().get("on_enter", []))
	visible_lines = _filtered_lines(_current_node())
	_render()


func _current_node() -> Dictionary:
	return nodes_by_id.get(current_node_id, {})


func _filtered_lines(node: Dictionary) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for raw_line in node.get("lines", []):
		if raw_line is Dictionary and _conditions_met(raw_line.get("requires", {})):
			lines.append(raw_line)
	return lines


func _current_line_is_protagonist() -> bool:
	if not has_active_line():
		return false
	var line: Dictionary = visible_lines[line_cursor]
	return str(line.get("kind", "")) == "dialogue" and str(line.get("speaker", "")) == "沈砚舟"


func _available_choices() -> Array[Dictionary]:
	if has_active_line():
		if _current_line_is_protagonist() and not protagonist_line_committed:
			return [{"id": "speak_current_line", "label": str(visible_lines[line_cursor].get("text", ""))}]
		return []
	var node := _current_node()
	var choices: Array[Dictionary] = []
	for raw_choice in node.get("choices", []):
		if raw_choice is Dictionary and _conditions_met(raw_choice.get("requires", {})):
			choices.append(raw_choice)
	var source := str(node.get("choice_source", ""))
	match source:
		"desk":
			choices.append_array(_desk_choices())
		"probe":
			choices.append_array(_probe_choices())
		"mid_hotspots":
			choices.append_array(_hotspot_choices("中段"))
		"end_hotspots":
			choices.append_array(_hotspot_choices("谢幕"))
		"first_looks":
			choices.append_array(_first_look_choices())
		"followups":
			choices.append_array(_followup_choices())
		"claims":
			choices.append_array(_claim_choices())
		"consequence":
			if state.consequence_revealed and not state.run_finished:
				choices.append({"id": "check_ledger", "label": "查收发簿", "effects": [{"method": "check_ledger"}]})
	return choices


func _desk_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var catalog: Array[Dictionary] = [
		{"id": "desk_performance", "label": "查看“春和”工作夹", "knowledge": "performance_plan", "target": "s01_performance"},
		{"id": "desk_old_report", "label": "查看二十年前的旧报", "knowledge": "old_report", "target": "s01_old_report"},
		{"id": "desk_letter", "label": "查看采访函留底", "knowledge": "interview_letter", "target": "s01_letter"},
		{"id": "desk_death", "label": "查看赵敬文死亡报道", "knowledge": "death_report", "target": "s01_death"},
		{"id": "desk_map", "label": "查看旧戏院草图（可选）", "knowledge": "old_map", "target": "s01_map"},
	]
	for choice: Dictionary in catalog:
		if not state.has_knowledge(str(choice.knowledge)):
			choices.append(choice)
	if state.desk_ready():
		choices.append({"id": "desk_done", "label": "收好材料，准备出发", "target": "s02_depart"})
	return choices


func _probe_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var targets := {"desk_gap": "c04_probe_desk", "no_reply": "c04_probe_no_reply", "reply_missing": "c04_probe_missing"}
	for probe_id: String in state.available_probe_choices():
		choices.append({"id": "probe_%s" % probe_id, "label": str(PROBE_LABELS[probe_id]), "target": str(targets[probe_id]), "effects": [{"method": "choose_probe", "args": [probe_id]}]})
	return choices


func _hotspot_choices(beat: String) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var ids := {
		"台上的林怀安": "mid_lin_stage", "通道旁的许济川": "mid_xu", "方仲山账桌": "mid_fang_desk",
		"景片下沿": "mid_scenery_height", "陈九生与阿成": "mid_chen", "侧台帘口": "mid_chen_curtain",
		"林怀安谢幕": "end_lin_stable", "台上谢幕": "end_lin_stable", "前场出口": "end_front_exit",
		"空账桌": "end_empty_desk", "舞台出口": "end_stage_exit", "林怀安路线": "end_lin_route",
		"铁梯方向": "end_ladder", "陈九生站位": "end_chen",
	}
	var targets := {
		"台上的林怀安": "c06_chest", "通道旁的许济川": "c06_treatment", "方仲山账桌": "c06_fang",
		"景片下沿": "c06_scenery", "陈九生与阿成": "c06_chen", "侧台帘口": "c06_chen",
		"林怀安谢幕": "c07_stable", "台上谢幕": "c07_stable", "前场出口": "c07_fang",
		"空账桌": "c07_fang", "舞台出口": "c07_route", "林怀安路线": "c07_route",
		"铁梯方向": "c07_shadow", "陈九生站位": "c07_chen",
	}
	for hotspot: String in state.available_hotspots(beat):
		choices.append({"id": str(ids[hotspot]), "label": hotspot, "target": str(targets[hotspot]), "effects": [{"method": "observe_hotspot", "args": [beat, hotspot]}]})
	return choices


func _first_look_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var ids := {"许济川的手": "first_neck", "近旁地面": "first_ground", "倒下的位置": "first_position", "周围的人": "first_crowd"}
	var targets := {"许济川的手": "c09_neck", "近旁地面": "c09_position", "倒下的位置": "c09_position", "周围的人": "c09_crowd"}
	for look: String in state.available_first_looks():
		choices.append({"id": str(ids[look]), "label": look, "target": str(targets[look]), "effects": [{"method": "observe_first_look", "args": [look]}]})
	return choices


func _followup_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for followup_id: String in state.available_followups():
		match followup_id:
			"yutang": choices.append({"id": "follow_yutang", "label": "为什么要把药盒往袖口里收？", "target": "c16_yutang", "effects": [{"method": "choose_followup", "args": [followup_id]}]})
			"xu_neck": choices.append({"id": "follow_xu_neck", "label": "你摸到他颈边时，为什么停了一下？", "target": "c16_xu", "effects": [{"method": "choose_followup", "args": [followup_id]}]})
			"xu_general": choices.append({"id": "follow_xu_general", "label": "你说有心疾不等于死因。你还看见了什么？", "target": "c16_xu", "effects": [{"method": "choose_followup", "args": [followup_id]}]})
			"chen":
				var chen_label := "演到一半时，你为什么问玉棠去哪儿？"
				if state.has_evidence("chen_absent"):
					chen_label = "谢幕锣响前你离开侧台，去哪儿了？"
				elif state.has_evidence("crowd_arrival"):
					chen_label = "你从侧台另一头回来，之前在哪儿？"
				choices.append({"id": "follow_chen", "label": chen_label, "target": "c16_chen", "effects": [{"method": "choose_followup", "args": [followup_id]}]})
			"fang": choices.append({"id": "follow_fang", "label": "开场前你说要去看吊绳。谢幕前后，你在哪儿？", "target": "c16_fang", "effects": [{"method": "choose_followup", "args": [followup_id]}]})
	return choices


func _claim_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var claim_texts: Dictionary = flow.get("claims", {})
	for claim_id: String in state.available_claims():
		if claim_id == state.selected_claim:
			continue
		if not state.selected_claim.is_empty() and state.claim_changes >= 1:
			continue
		choices.append({"id": "claim_%s" % claim_id, "label": str(claim_texts.get(claim_id, "")), "effects": [{"method": "select_claim", "args": [claim_id]}]})
	if not state.selected_claim.is_empty():
		choices.append({"id": "submit_report", "label": "交稿", "effects": [{"method": "submit_report"}]})
	return choices


func _apply_effects(raw_effects) -> bool:
	for raw_effect in raw_effects:
		if not raw_effect is Dictionary:
			continue
		var effect: Dictionary = raw_effect
		var method_name := str(effect.get("method", ""))
		if method_name.is_empty() or not state.has_method(method_name):
			push_error("state 缺少动作：%s" % method_name)
			return false
		var result = state.callv(method_name, effect.get("args", []))
		if result is bool and not result:
			return false
	return true


func _conditions_met(raw_conditions) -> bool:
	if not raw_conditions is Dictionary:
		return true
	var conditions: Dictionary = raw_conditions
	for key in conditions:
		var expected = conditions[key]
		match str(key):
			"letter_form":
				if state.letter_form != str(expected): return false
			"letter_control":
				if state.letter_control != str(expected): return false
			"prepolice_action":
				if state.prepolice_action != str(expected): return false
			"position":
				if state.position != str(expected): return false
			"route":
				if state.route != str(expected): return false
			"knowledge":
				if not state.has_knowledge(str(expected)): return false
			"evidence":
				if not state.has_evidence(str(expected)): return false
			"evidence_any":
				var found_any := false
				for evidence_id in expected:
					if state.has_evidence(str(evidence_id)):
						found_any = true
						break
				if not found_any: return false
			"not_evidence":
				var excluded: Array = expected if expected is Array else [expected]
				for evidence_id in excluded:
					if state.has_evidence(str(evidence_id)): return false
	return true


func _render() -> void:
	if body == null:
		return
	_clear(body)
	render_generation += 1
	ui_accept_after_msec = Time.get_ticks_msec() + 180
	var node := _current_node()
	var location := str(node.get("location", ""))
	if not location.is_empty():
		_add_kicker(location)
	if has_active_line():
		var current_line: Dictionary = visible_lines[line_cursor]
		if _current_line_is_protagonist() and not protagonist_line_committed:
			var speech_button := _make_button(str(current_line.get("text", "")), choose_option.bind("speak_current_line"))
			speech_button.set_meta("protagonist_line_choice", true)
			body.add_child(speech_button)
		else:
			_add_story_line(current_line)
	elif str(node.get("choice_source", "")) == "claims":
		_add_kicker("采访本与稿纸")
		_add_material(str(flow.get("source_context", "")))
		_add_material(str(flow.get("report_lead", "")))
		if not state.selected_claim.is_empty():
			_add_kicker("完整稿件")
			_add_material("%s\n\n%s" % [str(flow.get("report_lead", "")), str(flow.get("claims", {}).get(state.selected_claim, ""))])
	elif str(node.get("choice_source", "")) == "consequence" and state.report_submitted:
		_add_kicker("实际刊出的报纸")
		_add_material("%s\n\n%s" % [str(flow.get("report_lead", "")), str(flow.get("claims", {}).get(state.submitted_claim, ""))])
		_add_result_line(state.final_consequence(), true)
	if not has_active_line():
		for choice: Dictionary in _available_choices():
			body.add_child(_make_button(str(choice.get("label", "")), choose_option.bind(str(choice.get("id", "")))))
	call_deferred("_reset_scroll_after_layout", render_generation)
	call_deferred("_focus_first_button_after_delay", render_generation)


func _add_story_line(line: Dictionary) -> void:
	var kind := str(line.get("kind", "narration"))
	var text_value := str(line.get("text", ""))
	match kind:
		"dialogue":
			_add_speaker(str(line.get("speaker", "")))
			_add_story_card(text_value, "dialogue")
		"material":
			_add_story_card(text_value, "material")
		_:
			_add_story_card(text_value, "narration")


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	shell = Control.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shell)
	var title := _make_label("雾港来信", 28, PAPER)
	title.anchor_right = 1.0
	title.offset_left = 34
	title.offset_top = 26
	title.offset_right = -190
	title.offset_bottom = 74
	title.mouse_filter = Control.MOUSE_FILTER_STOP
	title.tooltip_text = "拖动窗口；双击放大或还原"
	title.set_meta("window_action", "drag")
	title.gui_input.connect(_on_title_gui_input)
	shell.add_child(title)
	var window_controls := HBoxContainer.new()
	window_controls.anchor_left = 1.0
	window_controls.anchor_right = 1.0
	window_controls.offset_left = -178
	window_controls.offset_top = 30
	window_controls.offset_right = -34
	window_controls.offset_bottom = 70
	window_controls.alignment = BoxContainer.ALIGNMENT_END
	window_controls.add_theme_constant_override("separation", 6)
	shell.add_child(window_controls)
	window_controls.add_child(_make_window_button("—", "最小化", "minimize", minimize_window))
	maximize_button = _make_window_button("□", "放大", "maximize", toggle_window_size)
	window_controls.add_child(maximize_button)
	window_controls.add_child(_make_window_button("×", "关闭", "close", close_window))
	var rule := ColorRect.new()
	rule.color = JADE_DARK
	rule.anchor_right = 1.0
	rule.offset_left = 34
	rule.offset_top = 86
	rule.offset_right = -34
	rule.offset_bottom = 88
	shell.add_child(rule)
	scroll = ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 34
	scroll.offset_top = 100
	scroll.offset_right = -34
	scroll.offset_bottom = -24
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shell.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	var resize_grip := Button.new()
	resize_grip.text = "◢"
	resize_grip.tooltip_text = "拖动调整窗口大小"
	resize_grip.focus_mode = Control.FOCUS_NONE
	resize_grip.flat = true
	resize_grip.anchor_left = 1.0
	resize_grip.anchor_top = 1.0
	resize_grip.anchor_right = 1.0
	resize_grip.anchor_bottom = 1.0
	resize_grip.offset_left = -32
	resize_grip.offset_top = -32
	resize_grip.offset_right = -6
	resize_grip.offset_bottom = -6
	resize_grip.add_theme_font_size_override("font_size", 16)
	resize_grip.add_theme_color_override("font_color", JADE)
	resize_grip.add_theme_color_override("font_hover_color", GOLD)
	resize_grip.set_meta("window_action", "resize")
	resize_grip.gui_input.connect(_on_resize_grip_gui_input)
	shell.add_child(resize_grip)
	get_window().size_changed.connect(_sync_window_controls)
	_sync_window_controls()


func _make_window_button(text_value: String, tooltip: String, action: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(42, 36)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_stylebox_override("normal", _box(Color("111814"), JADE_DARK, 1, 6, 4))
	button.add_theme_stylebox_override("hover", _box(PANEL_LIGHT, JADE, 1, 6, 4))
	button.add_theme_stylebox_override("pressed", _box(JADE_DARK, GOLD, 1, 6, 4))
	button.add_theme_stylebox_override("focus", _box(PANEL_LIGHT, GOLD, 2, 6, 4))
	button.set_meta("window_action", action)
	button.pressed.connect(callback)
	return button


func _on_title_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if mouse_event.double_click:
		toggle_window_size()
	else:
		DisplayServer.window_start_drag()
	get_viewport().set_input_as_handled()


func _on_resize_grip_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_start_resize(DisplayServer.WINDOW_EDGE_BOTTOM_RIGHT)
	get_viewport().set_input_as_handled()


func _sync_window_controls() -> void:
	if maximize_button == null:
		return
	var is_expanded := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_MAXIMIZED, DisplayServer.WINDOW_MODE_FULLSCREEN]
	maximize_button.text = "❐" if is_expanded else "□"
	maximize_button.tooltip_text = "还原" if is_expanded else "放大"


func _reset_scroll_after_layout(generation: int) -> void:
	await get_tree().process_frame
	if generation != render_generation or scroll == null:
		return
	scroll.scroll_horizontal = 0
	scroll.scroll_vertical = 0


func _focus_first_button() -> void:
	for child: Node in body.find_children("*", "Button", true, false):
		(child as Button).grab_focus()
		return


func _focus_first_button_after_delay(generation: int) -> void:
	await get_tree().create_timer(0.18).timeout
	if generation != render_generation:
		return
	_focus_first_button()


func _dispatch_ui(callback: Callable) -> void:
	if Time.get_ticks_msec() < ui_accept_after_msec:
		return
	callback.call()


func _clear(node: Node) -> void:
	for child: Node in node.get_children():
		child.queue_free()


func _make_button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(0, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_stylebox_override("normal", _box(PANEL_LIGHT, Color("3c5145"), 1, 7, 10))
	button.add_theme_stylebox_override("hover", _box(Color("2c493a"), JADE, 2, 7, 10))
	button.add_theme_stylebox_override("pressed", _box(Color("38594a"), GOLD, 2, 7, 10))
	button.add_theme_stylebox_override("focus", _box(Color("2c493a"), GOLD, 2, 7, 10))
	button.pressed.connect(_dispatch_ui.bind(callback))
	return button


func _make_label(text_value: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _make_panel(color: Color, border: Color = Color("33443a")) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(color, border, 1, 8, 12))
	return panel


func _box(color: Color, border: Color, border_width: int, radius: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style


func _add_kicker(text_value: String) -> void:
	var label := _make_label(text_value, 15, GOLD)
	label.custom_minimum_size = Vector2(0, 24)
	body.add_child(label)


func _add_speaker(text_value: String) -> void:
	var label := _make_label(text_value, 15, GOLD)
	label.set_meta("speaker_label", true)
	label.custom_minimum_size = Vector2(0, 24)
	body.add_child(label)


func _add_story_card(text_value: String, kind: String) -> void:
	var card := Button.new()
	card.text = text_value
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.set_meta("story_line_card", true)
	card.focus_mode = Control.FOCUS_ALL
	card.custom_minimum_size = Vector2(0, 70)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_font_size_override("font_size", 19 if kind == "dialogue" else 18)
	card.add_theme_color_override("font_color", PAPER)
	card.add_theme_color_override("font_hover_color", Color.WHITE)
	card.add_theme_color_override("font_pressed_color", PAPER)
	var base_color := Color("1b2420") if kind == "material" else Color("252a24")
	var border_color := JADE_DARK if kind == "material" else Color("665c43")
	card.add_theme_stylebox_override("normal", _box(base_color, border_color, 1, 8, 12))
	card.add_theme_stylebox_override("hover", _box(base_color.lightened(0.06), JADE, 2, 8, 12))
	card.add_theme_stylebox_override("pressed", _box(base_color.darkened(0.04), GOLD, 2, 8, 12))
	card.add_theme_stylebox_override("focus", _box(base_color, GOLD, 2, 8, 12))
	card.pressed.connect(_dispatch_ui.bind(Callable(self, "advance_line")))
	body.add_child(card)


func _add_material(text_value: String) -> void:
	var panel := _make_panel(Color("1b2420"), JADE_DARK)
	panel.add_child(_make_label(text_value, 18, PAPER))
	body.add_child(panel)


func _add_result_line(text_value: String, is_primary := false) -> void:
	if text_value.is_empty():
		return
	var panel := _make_panel(PANEL, JADE_DARK)
	if is_primary:
		panel.set_meta("primary_consequence", true)
	panel.add_child(_make_label(text_value, 17, PAPER))
	body.add_child(panel)
