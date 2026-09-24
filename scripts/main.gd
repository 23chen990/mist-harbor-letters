extends Control

const GameStateScript = preload("res://scripts/game_state.gd")
const StoryRepositoryScript = preload("res://scripts/story_repository.gd")

const INK := Color("151916")
const PAPER := Color("c9bc98")
const PAPER_DARK := Color("887d65")
const JADE := Color("52685e")
const RED := Color("79322e")
const RED_LIGHT := Color("b55b50")
const CHAPTER_DESTINATIONS: Dictionary = {
	"第一章": "前序·退稿与派活",
}
const CHAPTER_END_STAGES: Dictionary = {
	"第一章·第一章结尾·收束": "第一章结束",
}

var state = GameStateScript.new()
var story = StoryRepositoryScript.new()
var canvas: Control
var chapter_panel: Control
var debug_panel: Control
var _entry_results_applied: Dictionary = {}
var _choice_checkpoints: Array[Dictionary] = []
var _reply_search_run_id := 0
var _presentation_stage := ""
var _presentation_beat_index := 0
var _dialogue_context: Dictionary = {}
var _active_presentations: Array[Dictionary] = []


func _ready() -> void:
	_build_layers()
	_apply_responsive_scale()
	get_viewport().size_changed.connect(_apply_responsive_scale)
	if not story.load_story("res://content/程序生成_请勿手改/剧情剧本.csv"):
		_show_content_error()
		return
	_go_to_stage(state.current_stage)


func _apply_responsive_scale() -> void:
	# UI authored against the 1280×720 reference frame; scale uniformly while
	# preserving the detective-board composition and center it in any viewport.
	if canvas == null:
		return
	var viewport_size := get_viewport_rect().size
	var scale_factor := minf(viewport_size.x / 1280.0, viewport_size.y / 720.0)
	if scale_factor <= 0.0:
		return
	canvas.scale = Vector2.ONE * scale_factor
	chapter_panel.scale = Vector2.ONE * scale_factor
	debug_panel.scale = Vector2.ONE * scale_factor
	var offset := (viewport_size - Vector2(1280.0, 720.0) * scale_factor) * 0.5
	canvas.position = offset
	chapter_panel.position = offset
	debug_panel.position = offset


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		_toggle_debug()


func _build_layers() -> void:
	canvas = Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(canvas)
	chapter_panel = Control.new()
	chapter_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chapter_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	chapter_panel.hide()
	add_child(chapter_panel)
	debug_panel = Control.new()
	debug_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	debug_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	debug_panel.hide()
	add_child(debug_panel)


func _clear(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _go_to_stage(stage: String, presentation_index := 0, restored_presentations: Variant = null) -> void:
	_reply_search_run_id += 1
	if not story.has_stage(stage):
		_show_content_error(["找不到剧情阶段“%s”" % stage])
		return
	_presentation_stage = stage
	_presentation_beat_index = presentation_index
	var first := story.first_stage_row(stage)
	if restored_presentations == null:
		_active_presentations = _apply_entry_results(stage)
	else:
		_active_presentations.assign(restored_presentations)
	if state.demo_finished:
		_show_demo_end()
		return
	var presentations := _presentations_for_stage(stage)
	var render_row: Dictionary = presentations[0] if not presentations.is_empty() else first
	if str(render_row.get("场景", "")) != state.current_scene or str(render_row.get("内容类型", "")) != "NPC台词":
		_dialogue_context.clear()
	state.set_current_context(
		str(render_row.get("场景", "")),
		str(render_row.get("人物", "")),
		str(render_row.get("话题", "")),
		stage
	)
	if str(first.get("内容类型", "")) == "纯跳转" and story.available_choices(stage, state).is_empty():
		advance_story()
		return
	var content_type := str(render_row.get("内容类型", ""))
	if content_type == "场景探索":
		var completion_action := _automatic_scene_completion_action(stage)
		if not completion_action.is_empty():
			_follow_automatic_story_row(completion_action)
			return
		_render_scene_exploration(stage)
	elif content_type == "线索查看":
		_render_clue_inspection(stage)
	elif stage == "戏台·怀表特写" or content_type == "怀表特写":
		_show_watch()
	else:
		_render_stage(stage)
	if debug_panel.visible:
		_render_debug()


func _apply_entry_results(stage: String) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	# 条件路由必须按表格顺序逐行重算。上一行写入的路由结果会让后面的
	# “尚未设置”兜底行失效，避免一个阶段同时命中多个出口。
	for row: Dictionary in story.presentation_rows(stage):
		if not state.condition_met(str(row.get("出现条件", "始终"))):
			continue
		# 已命中的演出属于本次入场；自身效果可以改变条件，但不能抹去台词和出口。
		if story.available_presentations(stage, state).has(row):
			selected.append(row)
		var row_id := str(row.get("自动ID", ""))
		var result := _row_effect(row)
		if not result.is_empty() and not _entry_results_applied.has(row_id):
			state.apply_result(result)
			_entry_results_applied[row_id] = true
		var learned := str(row.get("玩家因此知道什么", ""))
		if not learned.is_empty() and not _entry_results_applied.has(row_id + ":knowledge"):
			state.learn_many(learned)
			_entry_results_applied[row_id + ":knowledge"] = true
	return selected


func _presentations_for_stage(stage: String) -> Array[Dictionary]:
	if stage == _presentation_stage:
		return _active_presentations
	return story.available_presentations(stage, state)


func choose_story_row(row: Dictionary) -> void:
	_store_choice_checkpoint()
	var player_line := str(row.get("玩家可选台词", ""))
	state.record_choice(player_line, str(row.get("内容类型", "")), str(row.get("自动ID", "")), str(row.get("是否说出口", "")) == "是")
	state.apply_result(_row_effect(row))
	state.learn_many(str(row.get("玩家因此知道什么", "")))
	if state.demo_finished:
		_show_demo_end()
		return
	var next_stage := str(row.get("下一话题", ""))
	if next_stage.is_empty():
		_show_content_error(["“%s”没有填写下一话题" % player_line])
		return
	if "回函搜寻动画" in str(row.get("演出/交互方式", "")):
		_play_reply_search_animation(next_stage)
		return
	_go_to_stage(next_stage)


func _automatic_scene_completion_action(stage: String) -> Dictionary:
	var completion_action: Dictionary = {}
	for row: Dictionary in story.available_choices(stage, state):
		if str(row.get("内容类型", "")) != "场景行动":
			return {}
		if "案件线索完成自动推进" not in str(row.get("演出/交互方式", "")):
			return {}
		if not completion_action.is_empty():
			return {}
		completion_action = row
	return completion_action


func _follow_automatic_story_row(row: Dictionary) -> void:
	state.apply_result(_row_effect(row))
	state.learn_many(str(row.get("玩家因此知道什么", "")))
	var next_stage := str(row.get("下一话题", ""))
	if next_stage.is_empty():
		_show_content_error(["自动完成动作“%s”没有填写下一话题" % str(row.get("自动ID", "未知行"))])
		return
	_go_to_stage(next_stage)


func advance_story() -> void:
	var beats := _presentation_beats(_presentations_for_stage(state.current_stage))
	if _pending_player_response_index(beats) >= 0:
		return
	if _is_terminal_stage(state.current_stage):
		_finish_demo()
		return
	var next_stage := ""
	for row: Dictionary in _presentations_for_stage(state.current_stage):
		var candidate := str(row.get("下一话题", ""))
		if candidate.is_empty():
			continue
		if not next_stage.is_empty() and next_stage != candidate:
			_show_content_error(["剧情阶段“%s”存在多个自动去向" % state.current_stage])
			return
		next_stage = candidate
	if next_stage.is_empty():
		_show_content_error(["剧情阶段“%s”没有可点击台词，也没有下一话题" % state.current_stage])
		return
	_go_to_stage(next_stage)


func _render_stage(stage: String) -> void:
	_clear(canvas)
	_draw_backstage()
	if stage == "第一章·是否写入赵敬文":
		_draw_writing_copy_preview()
	var presentations := _presentations_for_stage(stage)
	if stage == "第一章·第一篇稿":
		_draw_writing_panel(stage, _writing_choices_for_stage(stage))
		_draw_test_controls(canvas)
		return
	if _presentations_use_interaction(presentations, "退稿稿件UI"):
		_draw_rejected_manuscript_ui()
	var choices := story.available_choices(stage, state)
	var beats := _presentation_beats(presentations)
	if _presentation_stage != stage:
		_presentation_stage = stage
		_presentation_beat_index = 0
	if not beats.is_empty():
		_presentation_beat_index = clampi(_presentation_beat_index, 0, beats.size())
	var response_index := _pending_player_response_index(beats)
	var first: Dictionary = story.first_stage_row(stage)
	if presentations.is_empty() and not choices.is_empty():
		first = choices[0]
	var speaker := str(first.get("人物", ""))
	var body := ""
	var scene_actions: Array = []
	var dialogue_visible := true
	if not beats.is_empty():
		var current_beat: Dictionary = {}
		if _presentation_beat_index < beats.size():
			current_beat = beats[_presentation_beat_index]
		if current_beat.is_empty() or bool(current_beat.get("player_response", false)):
			current_beat = _dialogue_context.duplicate(true)
			if current_beat.is_empty():
				current_beat = {"speaker": "沈砚舟", "text": "", "dialogue_visible": true}
		elif str(current_beat.get("speaker", "")) not in ["", "沈砚舟", "场景", "旁白", "系统"] and not str(current_beat.get("text", "")).is_empty():
			_dialogue_context = current_beat.duplicate(true)
		body = str(current_beat.get("text", ""))
		speaker = str(current_beat.get("speaker", speaker))
		scene_actions = current_beat.get("scene_actions", []) as Array
		dialogue_visible = bool(current_beat.get("dialogue_visible", true))
	if not scene_actions.is_empty():
		_draw_scene_action_ui(scene_actions)
	var is_last_beat := beats.is_empty() or _presentation_beat_index >= beats.size() - 1
	var visible_choices: Array[Dictionary] = []
	if is_last_beat and response_index < 0:
		visible_choices.append_array(choices)
		if visible_choices.is_empty():
			visible_choices.append_array(_inline_successor_choices(presentations))
	var special := str(first.get("内容类型", "")) in ["判断选项", "限时观察"]
	var inner_monologue := str(first.get("内容类型", "")) == "内心"
	if dialogue_visible and not special and not inner_monologue:
		_draw_portrait(speaker)
	var dialogue_rect := Rect2(70, 344, 1140, 325)
	if special:
		dialogue_rect = Rect2(80, 82, 1120, 575)
	if dialogue_visible:
		_rect(canvas, dialogue_rect, Color(0.035, 0.052, 0.044, 0.97), RED if special else Color("655f4c"), 2)
		var speaker_color := PAPER_DARK if speaker == "场景" else RED_LIGHT
		_label(canvas, speaker, Rect2(dialogue_rect.position + Vector2(36, 18), Vector2(620, 38)), 24, speaker_color)
		var body_width := 1048.0 if special else 590.0
		var body_height := 125.0
		_label(canvas, body, Rect2(dialogue_rect.position + Vector2(36, 58), Vector2(body_width, body_height)), 19, PAPER)
	var x := dialogue_rect.position.x + (145 if special else 665)
	var y := dialogue_rect.position.y + (235 if special else 44)
	var width := 830.0 if special else 410.0
	if not dialogue_visible:
		x = 800.0
		y = 535.0
		width = 410.0
	var height := 48.0 if visible_choices.size() > 5 else 54.0
	var gap := 8.0
	for index in visible_choices.size():
		var choice: Dictionary = visible_choices[index]
		# 玩家界面只显示沈砚舟真正要说的话，不显示内容类型或技术分类。
		var choice_button := _button(canvas, str(choice.get("玩家可选台词", "")), Rect2(x, y + index * (height + gap), width, height), choose_story_row.bind(choice), index == 0)
		if str(choice.get("是否说出口", "")) == "是":
			choice_button.set_meta("player_response", true)
	if response_index >= 0:
		var response: Dictionary = beats[response_index]
		var response_button := _button(canvas, str(response.get("text", "")), Rect2(x, y, width, 72), _choose_player_response.bind(stage, response_index), true)
		response_button.set_meta("player_response", true)
		response_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		response_button.grab_focus()
	elif not is_last_beat:
		_button(canvas, "继续", Rect2(x, y, width, 54), _advance_presentation_beat, true)
	elif visible_choices.is_empty() and _has_presentation_next(stage):
		_button(canvas, "继续", Rect2(x, y, width, 54), _advance_presentation_beat, true)
	elif visible_choices.is_empty() and _is_terminal_stage(stage):
		_button(canvas, "结束本章", Rect2(x, y, width, 54), _finish_demo, true)
	_draw_test_controls(canvas)


func _draw_writing_panel(stage: String, choices: Array[Dictionary]) -> void:
	# C18 是第一次把“我亲眼看到的东西”变成公共句子。把基础段、来源和可
	# 支持的写法放在同一张稿纸上，玩家能看见每个判断来自哪条记录。
	_rect(canvas, Rect2(30, 72, 1220, 535), Color(0.035, 0.052, 0.044, 0.98), PAPER_DARK, 2)
	_label(canvas, "《雾港日报》·第一篇稿", Rect2(58, 88, 540, 38), 25, RED_LIGHT)
	_label(canvas, "把现场写成明天会被读到的句子", Rect2(650, 94, 540, 28), 16, PAPER_DARK, HORIZONTAL_ALIGNMENT_RIGHT)

	_label(canvas, "已经排好的基础段", Rect2(58, 136, 510, 28), 17, PAPER_DARK)
	_rect(canvas, Rect2(56, 168, 520, 168), Color("d2c7a5"), Color("766a52"), 2)
	var first := story.first_stage_row(stage)
	var base_text := str(first.get("动作/表情备注", "")).strip_edges()
	var closing_line := str(first.get("NPC台词", "")).strip_edges()
	if not closing_line.is_empty():
		if not base_text.is_empty():
			base_text += "\n\n"
		base_text += closing_line
	var base_label := _label(canvas, base_text, Rect2(76, 185, 480, 137), 16, INK)
	base_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_label(canvas, "现有材料（原件 / 现场速记）", Rect2(612, 136, 590, 28), 17, PAPER_DARK)
	_rect(canvas, Rect2(610, 168, 590, 168), Color("111712"), Color("465248"), 1)
	var source_lines := _writing_source_lines()
	var source_scroll := ScrollContainer.new()
	source_scroll.position = Vector2(626, 180)
	source_scroll.size = Vector2(558, 144)
	source_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(source_scroll)
	var source_list := VBoxContainer.new()
	source_list.custom_minimum_size = Vector2(530, 0)
	source_list.add_theme_constant_override("separation", 6)
	source_scroll.add_child(source_list)
	for source_line: String in source_lines:
		var source_label := _label(source_list, source_line, Rect2(0, 0, 530, 38), 14, PAPER)
		source_label.custom_minimum_size = Vector2(530, 38)
		source_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var selected_claim_id := str(state.technical_values.get("writing_claim_id", ""))
	if selected_claim_id.is_empty():
		_label(canvas, "下一步：选择一项能被记录支持的写法（一次只能提出一项待查疑点）", Rect2(58, 354, 1145, 30), 16, RED_LIGHT)
		var first_button: Button
		var columns := 2
		var button_width := 555.0
		var button_height := 58.0
		var gap_x := 28.0
		var gap_y := 10.0
		for index in choices.size():
			var choice: Dictionary = choices[index]
			var column := index % columns
			var row := index / columns
			var button_rect := Rect2(58 + column * (button_width + gap_x), 398 + row * (button_height + gap_y), button_width, button_height)
			var callback := _commit_confirmed_writing_claim.bind(choice) if str(choice.get("自动ID", "")) == "C18_010" else _select_writing_claim.bind(choice)
			var choice_button := _button(canvas, str(choice.get("玩家可选台词", "")), button_rect, callback, index == 0)
			choice_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if first_button == null:
				first_button = choice_button
		if first_button != null:
			first_button.grab_focus()
	else:
		var selected_choice := _writing_choice_by_id(choices, selected_claim_id)
		var selected_label := str(selected_choice.get("玩家可选台词", ""))
		_label(canvas, "已选择判断：%s" % selected_label, Rect2(58, 354, 1145, 30), 16, RED_LIGHT)
		_label(canvas, "选择支持这句话的现场记录：", Rect2(58, 386, 1145, 28), 16, PAPER_DARK)
		var support_sources := _writing_support_sources(selected_choice)
		var first_source_button: Button
		for index in support_sources.size():
			var source: Dictionary = support_sources[index]
			var source_button := _button(canvas, str(source.get("label", "")), Rect2(58, 422 + index * 58, 1140, 50), _commit_writing_claim.bind(selected_choice, str(source.get("id", ""))), index == 0)
			source_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if first_source_button == null:
				first_source_button = source_button
		if first_source_button != null:
			first_source_button.grab_focus()
		else:
			_label(canvas, "现有记录不足以写成这句话。", Rect2(58, 430, 1140, 52), 18, RED_LIGHT)
			var revise_button := _button(canvas, "换一项判断", Rect2(58, 500, 280, 50), _clear_writing_claim, true)
			revise_button.grab_focus()


func _draw_writing_copy_preview() -> void:
	var copy_text := str(state.technical_values.get("writing_copy_text", "")).strip_edges()
	if copy_text.is_empty():
		return
	var card := _rect(canvas, Rect2(650, 88, 560, 218), Color("d8ccb0"), Color("756d58"), 2)
	_label(canvas, "稿面预览·第二段", Rect2(674, 104, 300, 30), 18, PAPER_DARK)
	var copy_label := _label(canvas, copy_text, Rect2(674, 148, 512, 132), 17, INK)
	copy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _writing_choices_for_stage(stage: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for choice: Dictionary in story.stage_rows(stage):
		if str(choice.get("玩家可选台词", "")).is_empty():
			continue
		var row_id := str(choice.get("自动ID", ""))
		var available := state.condition_met(str(choice.get("出现条件", "始终")))
		# C18 的两句位置写法在运行数据的历史补丁中曾把强弱条件写反。
		# 这里按 v6 作者树的证据顺序收窄：亲眼看见台侧才可写强句；
		# 只走来路时只能写场务说法。生成数据仍由工作簿负责维护。
		if row_id == "C18_011":
			# 台侧站位只是路线条件；还必须实际选择 C09 的倒地位置观察。
			# 仅选择了“看林怀安”或“看周围的人”时，不足以写出位置矛盾。
			available = state.condition_met("c07_position=side") and _has_writing_note("C09_position")
		elif row_id == "C18_011B":
			available = state.condition_met("c07_position!=side and pre_police_check=path") and _has_writing_note("C12_path") and state.condition_met("lin_missing_after_curtain=true")
		elif row_id == "C18_014":
			# 离岗判断必须落到一个具体的谢幕前后记录；C06 的中段记录
			# 单独不足以写 v6 的谢幕时段句子。
			available = available and (_has_writing_note("C07_front") or _has_writing_note("C07_orchestra"))
		if available:
			result.append(choice)
	return result


func _select_writing_claim(choice: Dictionary) -> void:
	if state.current_stage != "第一章·第一篇稿":
		return
	_store_choice_checkpoint()
	_clear_writing_copy()
	state.apply_result("writing_claim_id=%s" % str(choice.get("自动ID", "")))
	_render_stage(state.current_stage)


func _clear_writing_claim() -> void:
	state.technical_values.erase("writing_claim_id")
	_clear_writing_copy()
	_render_stage(state.current_stage)


func _commit_confirmed_writing_claim(choice: Dictionary) -> void:
	if state.current_stage != "第一章·第一篇稿":
		return
	_clear_writing_copy()
	state.apply_result("writing_source_id=confirmed")
	_write_copy_for_claim(choice, "confirmed")
	choose_story_row(choice)


func _commit_writing_claim(choice: Dictionary, source_id: String) -> void:
	if state.current_stage != "第一章·第一篇稿":
		return
	if source_id.is_empty():
		return
	state.apply_result("writing_source_id=%s" % source_id)
	_write_copy_for_claim(choice, source_id)
	choose_story_row(choice)


func _clear_writing_copy() -> void:
	for key: String in ["writing_source_id", "writing_copy_variant", "writing_subject_id", "writing_copy_text"]:
		state.technical_values.erase(key)


func _write_copy_for_claim(choice: Dictionary, source_id: String) -> void:
	var claim_id := str(choice.get("自动ID", ""))
	var copy_text := ""
	var variant := ""
	var subject_id := ""
	match claim_id:
		"C18_010":
			copy_text = "林怀安生前有心疾旧患。该旧患是否与其死亡有关，仍待检验结果确认。"
			variant = "confirmed"
		"C18_011":
			if source_id == "C07_side+C09_position":
				copy_text = "本报记者在场所见，林怀安最后的行走方向与其被发现的位置并不完全相合。该位置差异是否与死亡经过有关，仍待警方查明。"
				variant = "location_strong"
		"C18_011B":
			if source_id == "C08_001+C12_path":
				copy_text = "场务称林怀安从台侧下台，侧厅未见其人。两处是否相接，尚待查明。"
				variant = "location_weak"
		"C18_012":
			if source_id == "C10_MEDICINE_BOX+C12_drug":
				copy_text = "林怀安倒下后，其女林玉棠曾将死者随身药盒取出，并一度试图将其带离现场。该药盒目前已由警方封存。"
				variant = "medicine_strong"
			elif source_id == "C10_MEDICINE_BOX":
				copy_text = "林玉棠曾从死者衣内取出随身药盒，并拒绝立即交给现场医师。"
				variant = "medicine_narrow"
		"C18_013":
			if source_id == "C12_ROPE_ANOMALY":
				copy_text = "本报记者在春和天桥看见，一根吊景绳的绳尾长度与相邻绳索不同，横杆处另有较新的麻毛。该变化形成于何时、是否与死者有关，目前尚无结论。"
				variant = "rope"
		"C18_014":
			match source_id:
				"C07_front":
					copy_text = "演出后段至谢幕期间，负责前场事务的方仲山曾离开账桌；本报记者未见其去向。"
					variant = "absence_fang"
					subject_id = "fang"
				"C07_orchestra":
					copy_text = "谢幕前后，后台总管陈九生曾离开原本位置，稍后从侧台另一端返回。其间行踪尚待核对。"
					variant = "absence_chen"
					subject_id = "chen"
	if copy_text.is_empty():
		return
	state.technical_values["writing_copy_variant"] = variant
	state.technical_values["writing_subject_id"] = subject_id
	state.technical_values["writing_copy_text"] = copy_text


func _writing_choice_by_id(choices: Array[Dictionary], row_id: String) -> Dictionary:
	for choice: Dictionary in choices:
		if str(choice.get("自动ID", "")) == row_id:
			return choice
	return {}


func _writing_support_sources(choice: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var row_id := str(choice.get("自动ID", ""))
	match row_id:
		"C18_011":
			if _has_writing_note("C07_side") and _has_writing_note("C09_position"):
				result.append({"id": "C07_side+C09_position", "label": "速记合并｜谢幕时沿侧台通道中央走向侧厅；发现时倒在岔口靠墙处。"})
		"C18_011B":
			if _has_writing_note("C12_path") and state.condition_met("lin_missing_after_curtain=true"):
				var field_report := _writing_npc_line("C08_001")
				var path_note := _writing_note_text("C12_path")
				result.append({"id": "C08_001+C12_path", "label": "现场说法 + 来路速记｜%s；来路速记｜%s" % [field_report, path_note]})
		"C18_012":
			if _has_writing_note("C10_MEDICINE_BOX"):
				result.append({"id": "C10_MEDICINE_BOX", "label": "速记（窄写法）｜" + _writing_note_text("C10_MEDICINE_BOX")})
			if _has_writing_note("C10_MEDICINE_BOX") and _has_writing_note("C12_drug"):
				result.append({"id": "C10_MEDICINE_BOX+C12_drug", "label": "速记合并｜药盒被取出后，玉棠又要求阿成把它交回。"})
		"C18_013":
			if _has_writing_note("C12_ROPE_ANOMALY"):
				result.append({"id": "C12_ROPE_ANOMALY", "label": "速记｜" + _writing_note_text("C12_ROPE_ANOMALY")})
		"C18_014":
			for note_id: String in ["C07_front", "C07_orchestra"]:
				if _has_writing_note(note_id):
					var subject := "陈九生" if note_id == "C07_orchestra" else "方仲山"
					result.append({"id": note_id, "label": "%s｜速记｜%s" % [subject, _writing_note_text(note_id)]})
	return result


func _has_writing_note(note_id: String) -> bool:
	return Array(state.technical_collections.get("notes", [])).has(note_id)


func _writing_source_lines() -> Array[String]:
	var result: Array[String] = []
	var records: Array = state.narrative_records.keys()
	records.sort()
	for record: Variant in records:
		if not str(record).begins_with("已查看"):
			continue
		var record_text := _writing_record_text(str(record))
		if not record_text.is_empty():
			result.append("原件｜%s" % record_text)
	var notes: Array = state.technical_collections.get("notes", [])
	for note: Variant in notes:
		var note_text := _writing_note_text(str(note))
		if not note_text.is_empty():
			result.append("速记｜%s" % note_text)
	if result.is_empty():
		result.append("还没有可用于提出疑点的现场速记。")
	return result


func _writing_record_text(record_name: String) -> String:
	for row: Dictionary in story.rows:
		var effects := str(row.get("选择结果", "")) + ";" + str(row.get("状态写入（不显示）", ""))
		if ("记录“%s”" % record_name) not in effects:
			continue
		var knowledge := str(row.get("玩家因此知道什么", "")).strip_edges()
		if not knowledge.is_empty():
			return knowledge
		var visual := str(row.get("画面表现", "")).strip_edges()
		if not visual.is_empty():
			return visual.split("\n", false)[0].strip_edges()
	return record_name.trim_prefix("已查看")


func _writing_note_text(note_id: String) -> String:
	var expected := "notes += %s" % note_id
	for row: Dictionary in story.rows:
		var effects := str(row.get("选择结果", "")) + ";" + str(row.get("状态写入（不显示）", ""))
		for raw_effect: String in effects.replace("；", ";").split(";", false):
			if raw_effect.strip_edges() != expected:
				continue
			var knowledge := str(row.get("玩家因此知道什么", "")).strip_edges()
			if not knowledge.is_empty():
				return knowledge
			var visual := str(row.get("画面表现", "")).strip_edges()
			if not visual.is_empty():
				return visual.split("\n", false)[0].strip_edges()
	return ""


func _writing_npc_line(row_id: String) -> String:
	for row: Dictionary in story.rows:
		if str(row.get("自动ID", "")) != row_id:
			continue
		var lines := str(row.get("NPC台词", "")).split("\n", false)
		for index in range(lines.size() - 1, -1, -1):
			var line := str(lines[index]).strip_edges()
			if not line.is_empty():
				return line
	return ""


func _inline_successor_choices(presentations: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not _presentations_use_interaction(presentations, "末句同屏后继选项"):
		return result
	var next_stage := ""
	for row: Dictionary in presentations:
		var candidate := str(row.get("下一话题", ""))
		if candidate.is_empty():
			continue
		if not next_stage.is_empty() and next_stage != candidate:
			return result
		next_stage = candidate
	if next_stage.is_empty() or not story.available_presentations(next_stage, state).is_empty():
		return result
	result.append_array(story.available_choices(next_stage, state))
	return result


func _advance_presentation_beat() -> void:
	var beats := _presentation_beats(_presentations_for_stage(state.current_stage))
	if _pending_player_response_index(beats) >= 0:
		return
	if _presentation_beat_index + 1 < beats.size():
		_presentation_beat_index += 1
		_render_stage(state.current_stage)
		if debug_panel.visible:
			_render_debug()
		return
	advance_story()


func _pending_player_response_index(beats: Array[Dictionary]) -> int:
	for index: int in [_presentation_beat_index, _presentation_beat_index + 1]:
		if index < beats.size() and bool(beats[index].get("player_response", false)):
			return index
	return -1


func _store_choice_checkpoint() -> void:
	_choice_checkpoints.append({
		"state": state.create_snapshot(),
		"entry_results_applied": _entry_results_applied.duplicate(true),
		"presentation_beat_index": _presentation_beat_index,
		"dialogue_context": _dialogue_context.duplicate(true),
		"active_presentations": _active_presentations.duplicate(true),
	})


func _choose_player_response(stage: String, response_index: int) -> void:
	if state.current_stage != stage:
		return
	var presentations := _presentations_for_stage(stage)
	var beats := _presentation_beats(presentations)
	if _pending_player_response_index(beats) != response_index:
		return
	_store_choice_checkpoint()
	var response: Dictionary = beats[response_index]
	state.record_choice(str(response.get("text", "")), "玩家选项", str(response.get("response_id", "")), true)
	_presentation_beat_index = response_index + 1
	if _presentation_beat_index >= beats.size() and story.available_choices(stage, state).is_empty() and _inline_successor_choices(presentations).is_empty():
		advance_story()
		return
	_render_stage(stage)
	if debug_panel.visible:
		_render_debug()


func _presentation_beats(presentations: Array[Dictionary]) -> Array[Dictionary]:
	var beats: Array[Dictionary] = []
	for row: Dictionary in presentations:
		var row_beats: Array[Dictionary] = []
		var speaker := str(row.get("人物", ""))
		var source := str(row.get("NPC台词", ""))
		var content_type := str(row.get("内容类型", ""))
		var interaction := str(row.get("演出/交互方式", ""))
		var scene_only := content_type in ["纯画面", "演出", "结局", "写稿"] or ("场景动作背景UI" in interaction and not _contains_direct_quote(source))
		if content_type == "内心":
			for part: String in _split_into_presentation_beats(source):
				row_beats.append({"speaker": speaker, "text": part, "scene_actions": [], "dialogue_visible": true})
		elif scene_only:
			var actions := _scene_actions_for_row(row, true)
			row_beats.append({"speaker": "", "text": "", "scene_actions": actions, "dialogue_visible": false})
		elif _contains_direct_quote(source):
			row_beats = _screenplay_presentation_beats(source, speaker)
			if not row_beats.is_empty():
				var first_beat: Dictionary = row_beats[0]
				var authored_actions := _scene_actions_for_row(row, false)
				var existing_actions: Array = first_beat.get("scene_actions", []) as Array
				for action: String in authored_actions:
					if not existing_actions.has(action):
						existing_actions.append(action)
				first_beat["scene_actions"] = existing_actions
				row_beats[0] = first_beat
		else:
			# 无引号文本是画面指令，不进对白框。
			var actions := _scene_actions_for_row(row, true)
			row_beats.append({"speaker": "", "text": "", "scene_actions": actions, "dialogue_visible": false})
		for index in row_beats.size():
			var beat: Dictionary = row_beats[index]
			var is_spoken := str(row.get("是否说出口", "")) != "否" and content_type == "NPC台词"
			beat["player_response"] = is_spoken and str(beat.get("speaker", "")) == "沈砚舟" and not str(beat.get("text", "")).is_empty()
			beat["response_id"] = "%s:reply:%d" % [str(row.get("自动ID", "")), index]
		beats.append_array(row_beats)
	return beats


func _scene_actions_for_row(row: Dictionary, include_source: bool) -> Array[String]:
	var actions: Array[String] = []
	var sources: Array[String] = []
	if include_source:
		sources.append(str(row.get("NPC台词", "")))
	sources.append(str(row.get("动作/表情备注", "")))
	sources.append(str(row.get("画面表现", "")))
	for source: String in sources:
		for action: String in _split_into_presentation_beats(source):
			if not action.is_empty() and not actions.has(action):
				actions.append(action)
	return actions


func _split_into_presentation_beats(source: String) -> Array[String]:
	var beats: Array[String] = []
	for raw_line: String in source.replace("\r\n", "\n").replace("\r", "\n").split("\n", false):
		var line := raw_line.strip_edges()
		if line.is_empty():
			continue
		var line_parts := _split_narration_sentences(line)
		for part: String in line_parts:
			beats.append(part)
	return beats


func _screenplay_presentation_beats(source: String, default_speaker: String) -> Array[Dictionary]:
	var beats: Array[Dictionary] = []
	var active_speaker := default_speaker
	var speakers := _known_story_speakers(source)
	var scene_actions: Array[String] = []
	var collecting_scene_actions := false
	for raw_line: String in source.replace("\r\n", "\n").replace("\r", "\n").split("\n", false):
		var line := raw_line.strip_edges()
		if line.is_empty():
			continue
		var quote_index := _first_direct_quote_index(line)
		if quote_index == 0:
			beats.append({"speaker": active_speaker, "text": line, "scene_actions": scene_actions.duplicate()})
			collecting_scene_actions = false
			continue
		if quote_index > 0 and _ends_with_colon(line.substr(0, quote_index)):
			var cue := line.substr(0, quote_index).strip_edges()
			var directive_speaker := _speaker_directive(cue, speakers)
			if not directive_speaker.is_empty():
				active_speaker = directive_speaker
			else:
				scene_actions.clear()
				for action: String in _split_into_presentation_beats(cue):
					scene_actions.append(action)
				active_speaker = _speaker_mentioned_in(cue, active_speaker, speakers)
			beats.append({"speaker": active_speaker, "text": line.substr(quote_index).strip_edges(), "scene_actions": scene_actions.duplicate()})
			collecting_scene_actions = false
			continue
		for part: String in _split_narration_sentences(line):
			var directive_speaker := _speaker_directive(part, speakers)
			if not directive_speaker.is_empty():
				active_speaker = directive_speaker
				continue
			if not collecting_scene_actions:
				scene_actions.clear()
				collecting_scene_actions = true
			scene_actions.append(part)
			active_speaker = _speaker_mentioned_in(part, active_speaker, speakers)
	if collecting_scene_actions and not scene_actions.is_empty():
		beats.append({"speaker": "", "text": "", "scene_actions": scene_actions.duplicate(), "dialogue_visible": false})
	return beats


func _contains_direct_quote(source: String) -> bool:
	return _first_direct_quote_index(source) >= 0


func _first_direct_quote_index(text: String) -> int:
	var result := -1
	for opening_quote: String in ["「", "『"]:
		var position := text.find(opening_quote)
		if position >= 0 and (result < 0 or position < result):
			result = position
	return result


func _speaker_directive(text: String, speakers: Array[String] = []) -> String:
	if not _ends_with_colon(text):
		return ""
	var candidate := text.strip_edges().trim_suffix("：").trim_suffix(":").strip_edges()
	if speakers.is_empty():
		speakers = _known_story_speakers()
	for speaker: String in speakers:
		if candidate == speaker or candidate == "版面%s" % speaker:
			return speaker
	return ""


func _speaker_mentioned_in(text: String, fallback: String, speakers: Array[String] = []) -> String:
	if speakers.is_empty():
		speakers = _known_story_speakers()
	var clauses := text.replace("，", "\n").replace(",", "\n").replace("。", "\n").replace("；", "\n").split("\n", false)
	clauses.reverse()
	for clause: String in clauses:
		var subject := ""
		var clean := clause.strip_edges()
		for speaker: String in speakers:
			# “甲转向乙”由甲说；“甲想扶乙，丙挡开”由最后分句主语丙说。
			if (clean.begins_with(speaker) or clean.begins_with("版面%s" % speaker)) and speaker.length() > subject.length():
				subject = speaker
		if not subject.is_empty():
			return subject
	return fallback


func _known_story_speakers(extra_source := "") -> Array[String]:
	var result: Array[String] = []
	var candidates: Array[String] = []
	var sources: Array[String] = [extra_source]
	for row: Dictionary in story.rows:
		sources.append(str(row.get("NPC台词", "")))
		var speaker := str(row.get("人物", "")).strip_edges()
		if speaker.is_empty() or speaker in ["旁白", "系统"] or result.has(speaker):
			continue
		result.append(speaker)
	# 明确的“人物：台词”也是作者给出的说话人标签，不能只依赖行的默认人物。
	for source: String in sources:
		for raw_line: String in source.replace("\r", "\n").split("\n", false):
			var line := raw_line.strip_edges()
			var quote_index := _first_direct_quote_index(line)
			var cue := line.substr(0, quote_index).strip_edges() if quote_index > 0 else line
			if not _ends_with_colon(cue):
				continue
			var candidate := cue.trim_suffix("：").trim_suffix(":").strip_edges()
			var simple_cue := not candidate.is_empty()
			for separator: String in ["，", ",", "。", "；", ";", "！", "？", " ", "\t", "：", ":", "「", "『"]:
				if candidate.contains(separator):
					simple_cue = false
					break
			if simple_cue and not result.has(candidate) and not candidates.has(candidate):
				candidates.append(candidate)
	var labels: Array[String] = result.duplicate()
	labels.append_array(candidates)
	for candidate: String in candidates:
		var extends_known_name := false
		for label: String in labels:
			if candidate != label and (candidate.begins_with(label) or candidate.begins_with("版面%s" % label)):
				extends_known_name = true
				break
		if not extends_known_name:
			result.append(candidate)
	return result


func _split_narration_sentences(line: String) -> Array[String]:
	# 直接台词保持完整；叙述中引用的原文不能阻止外层句号切分。
	var first_quote_index := -1
	for opening_quote: String in ["「", "『", "“", "‘"]:
		var quote_index := line.find(opening_quote)
		if quote_index >= 0 and (first_quote_index < 0 or quote_index < first_quote_index):
			first_quote_index = quote_index
	if first_quote_index == 0:
		return [line]
	if first_quote_index > 0 and _ends_with_colon(line.substr(0, first_quote_index)):
		return [line]
	var parts: Array[String] = []
	var current := ""
	var quote_depth := 0
	for index in line.length():
		var character := line.substr(index, 1)
		if character in ["「", "『", "“", "‘"]:
			quote_depth += 1
		current += character
		if character in ["」", "』", "”", "’"] and quote_depth > 0:
			quote_depth -= 1
		if quote_depth == 0 and character in ["。", "！", "？", "!", "?"]:
			parts.append(current.strip_edges())
			current = ""
	if not current.strip_edges().is_empty():
		parts.append(current.strip_edges())
	return parts


func _ends_with_colon(text: String) -> bool:
	var clean := text.strip_edges()
	return clean.ends_with("：") or clean.ends_with(":")


func _begins_with_quote(text: String) -> bool:
	var clean := text.strip_edges()
	return clean.begins_with("「") or clean.begins_with("『") or clean.begins_with("“") or clean.begins_with("‘")


func _render_scene_exploration(stage: String) -> void:
	_clear(canvas)
	_draw_newsroom_exploration_scene()
	var progress := _exploration_progress(stage)
	_label(canvas, "案件线索  %d / %d" % [progress.x, progress.y], Rect2(910, 18, 330, 32), 18, PAPER, HORIZONTAL_ALIGNMENT_RIGHT)
	_label(canvas, "点击房间中的物件进行查看", Rect2(420, 62, 440, 30), 16, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)

	var choices := story.available_choices(stage, state)
	var first_hotspot: Button
	var hotspot_index := 0
	for choice: Dictionary in choices:
		var content_type := str(choice.get("内容类型", ""))
		var label_text := str(choice.get("玩家可选台词", ""))
		if content_type == "场景行动":
			var leave_button := _button(canvas, label_text, Rect2(970, 555, 240, 58), choose_story_row.bind(choice), true)
			leave_button.set_meta("scene_exploration_action", true)
			continue
		var hotspot := _button(canvas, label_text, _exploration_hotspot_rect(label_text, hotspot_index), choose_story_row.bind(choice))
		hotspot.set_meta("scene_exploration_hotspot", true)
		hotspot.tooltip_text = "查看：%s" % label_text
		if first_hotspot == null:
			first_hotspot = hotspot
		hotspot_index += 1
	if first_hotspot != null:
		first_hotspot.grab_focus()
	_draw_test_controls(canvas)


func _render_clue_inspection(stage: String) -> void:
	_clear(canvas)
	_draw_newsroom_exploration_scene()
	_rect(canvas, Rect2(145, 72, 990, 535), Color(0.025, 0.04, 0.032, 0.985), PAPER_DARK, 2)
	var rows := _presentations_for_stage(stage)
	var choices := story.available_choices(stage, state)
	var first: Dictionary = story.first_stage_row(stage)
	if not rows.is_empty():
		first = rows[0]
	var title := str(first.get("话题", "查看物件"))
	var text_parts: Array[String] = []
	for row: Dictionary in rows:
		var written_text := str(row.get("NPC台词", ""))
		if not written_text.is_empty():
			text_parts.append(written_text)
		var visual_text := str(row.get("画面表现", ""))
		if not visual_text.is_empty():
			text_parts.append(visual_text)
		elif not str(row.get("动作/表情备注", "")).is_empty():
			text_parts.append(str(row.get("动作/表情备注", "")))
	var interaction := str(first.get("演出/交互方式", ""))
	var is_reply_search_result := "回函搜寻结果" in interaction
	_label(canvas, title, Rect2(200, 108, 880, 46), 28, RED_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	if stage == "前序·旧报发现":
		# 只保留原件的开放状态，不替玩家总结调查方法或安排下一步。
		_label(canvas, "状态：尚待核实", Rect2(460, 146, 360, 28), 14, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	if is_reply_search_result:
		_rect(canvas, Rect2(300, 190, 680, 240), Color("111712"), Color("465248"), 1)
		_label(canvas, "\n\n".join(text_parts), Rect2(340, 265, 600, 90), 30, PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_rect(canvas, Rect2(225, 172, 830, 290), Color("111712"), Color("465248"), 1)
		_label(canvas, "[ %s占位图 ]" % title, Rect2(250, 194, 780, 32), 17, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
		_label(canvas, "\n\n".join(text_parts), Rect2(275, 230, 730, 220), 17, PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	if not choices.is_empty():
		var first_button: Button
		for index in choices.size():
			var choice: Dictionary = choices[index]
			var action_button := _button(canvas, str(choice.get("玩家可选台词", "")), Rect2(465, 490 + index * 64, 350, 58), choose_story_row.bind(choice), index == 0)
			if first_button == null:
				first_button = action_button
		if first_button != null:
			first_button.grab_focus()
	elif _has_presentation_next(stage):
		var close_button := _button(canvas, "返回房间", Rect2(465, 490, 350, 58), advance_story, true)
		close_button.grab_focus()
	_draw_test_controls(canvas)


func _play_reply_search_animation(next_stage: String) -> void:
	_reply_search_run_id += 1
	var run_id := _reply_search_run_id
	_clear(canvas)
	_draw_newsroom_exploration_scene()
	_rect(canvas, Rect2(145, 72, 990, 535), Color(0.025, 0.04, 0.032, 0.99), PAPER_DARK, 2)
	_label(canvas, "寻找回信", Rect2(200, 108, 880, 46), 28, RED_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	_label(canvas, "翻找采访函留底旁……", Rect2(390, 465, 500, 36), 18, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)

	var folder := _rect(canvas, Rect2(385, 245, 510, 170), Color("4b4030"), Color("8f805e"), 2)
	folder.set_meta("reply_search_animation_piece", true)
	var paper_back := _rect(canvas, Rect2(430, 210, 420, 155), Color("968a6e"), Color("c9bc98"), 1)
	var paper_middle := _rect(canvas, Rect2(445, 222, 390, 145), Color("b4a886"), Color("d4c7a3"), 1)
	var paper_front := _rect(canvas, Rect2(460, 235, 360, 150), Color("c9bc98"), Color("8f805e"), 1)
	for paper: Panel in [paper_back, paper_middle, paper_front]:
		paper.set_meta("reply_search_animation_piece", true)
		paper.pivot_offset = paper.size * 0.5
	var line_one := _rect(canvas, Rect2(500, 270, 250, 3), Color("746b57"))
	var line_two := _rect(canvas, Rect2(500, 292, 210, 3), Color("746b57"))
	var line_three := _rect(canvas, Rect2(500, 314, 235, 3), Color("746b57"))
	for line: Panel in [line_one, line_two, line_three]:
		line.set_meta("reply_search_animation_piece", true)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(paper_front, "position", paper_front.position + Vector2(165, -16), 0.24)
	tween.parallel().tween_property(paper_front, "rotation", deg_to_rad(2.5), 0.24)
	tween.parallel().tween_property(line_one, "position", line_one.position + Vector2(165, -16), 0.24)
	tween.parallel().tween_property(line_two, "position", line_two.position + Vector2(165, -16), 0.24)
	tween.parallel().tween_property(line_three, "position", line_three.position + Vector2(165, -16), 0.24)
	tween.tween_interval(0.09)
	tween.tween_property(paper_middle, "position", paper_middle.position + Vector2(-145, 4), 0.23)
	tween.parallel().tween_property(paper_middle, "rotation", deg_to_rad(-2.0), 0.23)
	tween.tween_interval(0.09)
	tween.tween_property(paper_back, "position", paper_back.position + Vector2(120, 10), 0.22)
	tween.parallel().tween_property(paper_back, "rotation", deg_to_rad(1.5), 0.22)
	tween.tween_interval(0.18)
	tween.tween_callback(func() -> void:
		if run_id == _reply_search_run_id:
			_go_to_stage(next_stage)
	)


func _draw_newsroom_exploration_scene() -> void:
	_rect(canvas, Rect2(0, 0, 1280, 720), Color("0c120e"))
	_rect(canvas, Rect2(0, 55, 1280, 600), Color("242a23"))
	_rect(canvas, Rect2(50, 105, 310, 440), Color("1b211c"), Color("3d493f"), 2)
	_rect(canvas, Rect2(390, 115, 520, 365), Color("30352d"), Color("595845"), 2)
	_rect(canvas, Rect2(940, 100, 285, 430), Color("1b211c"), Color("3d493f"), 2)
	_rect(canvas, Rect2(0, 605, 1280, 115), Color("171813"))
	_label(canvas, state.current_scene, Rect2(25, 12, 520, 38), 24, PAPER)
	_label(canvas, "[ 《雾港日报》编辑部·场景占位 ]", Rect2(440, 18, 400, 30), 15, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	_label(canvas, "靠窗空椅与桌牌", Rect2(75, 475, 250, 30), 14, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	_label(canvas, "赵敬文的工作桌", Rect2(500, 430, 300, 30), 14, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	_label(canvas, "文件柜、地图与旧报", Rect2(950, 475, 265, 30), 14, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)


func _exploration_hotspot_rect(label_text: String, fallback_index: int) -> Rect2:
	var positions: Dictionary = {
		"「春和」工作夹": Rect2(92, 360, 225, 54),
		"二十年前的旧报": Rect2(455, 180, 250, 54),
		"寄给林怀安的采访函留底": Rect2(615, 330, 300, 54),
		"赵敬文死亡报道 / 旧戏院草图": Rect2(925, 185, 300, 54),
	}
	if positions.has(label_text):
		return positions[label_text]
	var column := fallback_index % 3
	var line := fallback_index / 3
	return Rect2(190 + column * 300, 190 + line * 90, 250, 54)


func _exploration_progress(stage: String) -> Vector2i:
	var first: Dictionary = story.first_stage_row(stage)
	var source_stage := str(first.get("下一话题", ""))
	for row: Dictionary in story.stage_rows(source_stage):
		if str(row.get("内容类型", "")) != "场景行动":
			continue
		var complete := 0
		var total := 0
		for clause: String in str(row.get("出现条件", "")).split(" and ", false):
			if clause.strip_edges().begins_with("已查看"):
				total += 1
				if state.condition_met(clause):
					complete += 1
		return Vector2i(complete, total)
	return Vector2i.ZERO


func _has_presentation_next(stage: String) -> bool:
	for row: Dictionary in _presentations_for_stage(stage):
		if not str(row.get("下一话题", "")).is_empty():
			return true
	return false


func _is_terminal_stage(stage: String) -> bool:
	return CHAPTER_END_STAGES.has(stage) or str(story.first_stage_row(stage).get("内容类型", "")) == "结局"


func _finish_demo() -> void:
	state.demo_finished = true
	if Array(state.technical_collections.get("endings", [])).has("E01"):
		state.completion_kind = "短结局"
		state.completion_name = "迟了一步"
	elif CHAPTER_END_STAGES.has(state.current_stage):
		state.completion_kind = "章节"
		state.completion_name = str(CHAPTER_END_STAGES[state.current_stage])
	else:
		state.completion_kind = "章节"
		state.completion_name = "本章结束"
	_show_demo_end()


func _row_effect(row: Dictionary) -> String:
	var actions: Array[String] = []
	var authored := str(row.get("选择结果", "")).strip_edges()
	var technical := str(row.get("状态写入（不显示）", "")).strip_edges()
	for source: String in [authored, technical]:
		for raw_action: String in source.replace("；", ";").split(";", false):
			var action := raw_action.strip_edges()
			if not action.is_empty() and not actions.has(action):
				actions.append(action)
	return "; ".join(actions)


func _show_watch() -> void:
	_clear(canvas)
	_rect(canvas, Rect2(0, 0, 1280, 720), Color("080b09"))
	_rect(canvas, Rect2(465, 130, 350, 350), Color("1c211d"), PAPER_DARK, 4)
	_label(canvas, "怀  表", Rect2(465, 165, 350, 50), 28, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	_label(canvas, "10:47", Rect2(465, 225, 350, 135), 70, PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	var choices := story.available_choices(state.current_stage, state)
	for row: Dictionary in choices:
		_button(canvas, str(row.get("玩家可选台词", "")), Rect2(465, 525, 350, 58), choose_story_row.bind(row), true)
	if choices.is_empty() and _has_presentation_next(state.current_stage):
		_button(canvas, "继续", Rect2(465, 525, 350, 58), advance_story, true)
	_draw_test_controls(canvas)


func _show_demo_end() -> void:
	_clear(canvas)
	_rect(canvas, Rect2(0, 0, 1280, 720), Color("080b09"))
	_label(canvas, "DEMO END", Rect2(0, 190, 1280, 80), 52, PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	var ending := state.completion_label()
	_label(canvas, ending if not ending.is_empty() else "本段结束", Rect2(0, 285, 1280, 55), 23, RED_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	_button(canvas, "重新开始", Rect2(480, 410, 320, 58), _restart, true)
	_draw_test_controls(canvas)
	if debug_panel.visible:
		_render_debug()


func _restart() -> void:
	chapter_panel.hide()
	state.reset()
	_entry_results_applied.clear()
	_choice_checkpoints.clear()
	_dialogue_context.clear()
	_go_to_stage(state.current_stage)


func return_to_previous_choice() -> void:
	if _choice_checkpoints.is_empty():
		return
	var checkpoint: Dictionary = _choice_checkpoints.pop_back()
	state.restore_snapshot(checkpoint.get("state", {}))
	_entry_results_applied = (checkpoint.get("entry_results_applied", {}) as Dictionary).duplicate(true)
	_dialogue_context = (checkpoint.get("dialogue_context", {}) as Dictionary).duplicate(true)
	_go_to_stage(state.current_stage, int(checkpoint.get("presentation_beat_index", 0)), checkpoint.get("active_presentations", null))


func _draw_test_controls(parent: Node) -> void:
	var back_button := _button(parent, "测试：返回上一级选择", Rect2(20, 672, 220, 34), return_to_previous_choice)
	back_button.disabled = _choice_checkpoints.is_empty()
	_button(parent, "测试：重新开始", Rect2(250, 672, 170, 34), _restart)
	_button(parent, "测试：切换章节", Rect2(430, 672, 180, 34), _toggle_chapter_selector)
	_label(parent, "F10 剧情作者 Debug", Rect2(880, 680, 370, 22), 13, PAPER_DARK, HORIZONTAL_ALIGNMENT_RIGHT)


func _toggle_chapter_selector() -> void:
	chapter_panel.visible = not chapter_panel.visible
	if chapter_panel.visible:
		_render_chapter_selector()


func _render_chapter_selector() -> void:
	_clear(chapter_panel)
	_rect(chapter_panel, Rect2(0, 0, 1280, 720), Color(0.015, 0.025, 0.02, 0.96))
	_rect(chapter_panel, Rect2(390, 120, 500, 480), INK, JADE, 2)
	_label(chapter_panel, "切换章节（测试）", Rect2(425, 178, 430, 48), 28, PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	_label(chapter_panel, "切换后会清空当前试玩进度", Rect2(425, 228, 430, 30), 15, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	var chapter_one := _button(chapter_panel, "第一章", Rect2(465, 300, 350, 56), switch_to_chapter.bind("第一章"), true)
	_label(chapter_panel, "第二、三章旧运行数据已停用", Rect2(465, 375, 350, 30), 15, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	_button(chapter_panel, "关闭", Rect2(540, 455, 200, 48), _toggle_chapter_selector)
	chapter_one.grab_focus()


func switch_to_chapter(chapter_name: String) -> void:
	if not CHAPTER_DESTINATIONS.has(chapter_name):
		return
	chapter_panel.hide()
	state.reset()
	_entry_results_applied.clear()
	_choice_checkpoints.clear()
	_dialogue_context.clear()
	_go_to_stage(str(CHAPTER_DESTINATIONS[chapter_name]))
func _show_content_error(extra_errors: Array[String] = []) -> void:
	_clear(canvas)
	_rect(canvas, Rect2(0, 0, 1280, 720), Color("120c0b"))
	var all_errors: Array[String] = []
	all_errors.append_array(story.errors)
	all_errors.append_array(extra_errors)
	_label(canvas, "剧情表无法加载", Rect2(80, 70, 1120, 60), 34, RED_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	_label(canvas, "\n".join(all_errors), Rect2(120, 145, 1040, 470), 18, PAPER)


func _toggle_debug() -> void:
	debug_panel.visible = not debug_panel.visible
	if debug_panel.visible:
		_render_debug()


func _render_debug() -> void:
	_clear(debug_panel)
	_rect(debug_panel, Rect2(0, 0, 1280, 720), Color(0.025, 0.035, 0.03, 0.985), JADE, 2)
	_label(debug_panel, "剧情作者 Debug", Rect2(34, 18, 500, 48), 30, PAPER)
	_button(debug_panel, "关闭（F10）", Rect2(1080, 20, 160, 42), _toggle_debug)
	var context := "当前场景：%s\n当前人物：%s\n当前话题：%s\n当前剧情阶段：%s" % [
		state.current_scene, state.current_character, state.current_topic, state.current_stage
	]
	_label(debug_panel, "当前剧情信息", Rect2(38, 76, 560, 30), 21, RED_LIGHT)
	_label(debug_panel, context, Rect2(38, 108, 565, 104), 16, PAPER)
	var prelude_status := _debug_prelude_exploration_status()
	if not prelude_status.is_empty():
		_label(debug_panel, "序章场景探索", Rect2(38, 205, 565, 26), 18, RED_LIGHT)
		_label(debug_panel, prelude_status, Rect2(38, 232, 565, 70), 14, PAPER)
	_label(debug_panel, "沈砚舟目前真正知道的事情", Rect2(38, 306, 565, 30), 21, RED_LIGHT)
	_label(debug_panel, "\n".join(state.knowledge_lines()), Rect2(38, 339, 565, 165), 14, PAPER)
	_label(debug_panel, "当前剧情状态（中文）", Rect2(38, 510, 565, 28), 19, RED_LIGHT)
	var story_states := state.story_state_lines()
	_label(debug_panel, "\n".join(story_states) if not story_states.is_empty() else "（尚未记录）", Rect2(38, 542, 565, 112), 14, PAPER)
	_label(debug_panel, "当前可点击回应", Rect2(635, 76, 590, 30), 21, RED_LIGHT)
	_label(debug_panel, _debug_available_topics(), Rect2(635, 108, 590, 160), 14, PAPER)
	_label(debug_panel, "当前选择历史", Rect2(635, 278, 590, 30), 21, RED_LIGHT)
	var history := state.history_lines(7)
	_label(debug_panel, "\n".join(history) if not history.is_empty() else "（还没有点击关键回答）", Rect2(635, 310, 590, 105), 14, PAPER)
	_label(debug_panel, "当前跨场景风险（仅 Debug）", Rect2(635, 418, 590, 28), 19, RED_LIGHT)
	_label(debug_panel, _debug_contradiction_text(), Rect2(635, 447, 590, 38), 14, PAPER)
	_label(debug_panel, "剧情快速跳转", Rect2(635, 492, 590, 30), 21, RED_LIGHT)
	var jumps := ["序章", "戏院门前", "林怀安采访", "第一眼", "警方笔录", "写稿"]
	for index in jumps.size():
		var column := index % 2
		var line := index / 2
		_button(debug_panel, jumps[index], Rect2(635 + column * 295, 528 + line * 50, 275, 40), debug_jump.bind(jumps[index]), index == 5)


func _debug_contradiction_text() -> String:
	if state.condition_met("chen_suspicion.external_actor=activated or chen_suspicion.external_actor=active"):
		return "△ 陈九生已经开始怀疑现场还有外部介入者"
	return "暂无"


func _debug_prelude_exploration_status() -> String:
	if state.current_scene != "《雾港日报》·赵敬文工作桌" or not state.current_stage.begins_with("前序·"):
		return ""
	var required: Array[Dictionary] = [
		{"label": "「春和」工作夹", "record": "已查看旧采访本"},
		{"label": "二十年前的旧报", "record": "已查看画满铅笔圈的旧报"},
		{"label": "寄给林怀安的采访函留底", "record": "已查看赵敬文采访函留底"},
		{"label": "赵敬文死亡报道 / 旧戏院草图", "record": "已查看记者证与采访本"},
	]
	var unseen: Array[String] = []
	for item: Dictionary in required:
		if not state.has_record(str(item.get("record", ""))):
			unseen.append(str(item.get("label", "")))
	var lines: Array[String] = ["案件线索：%d/%d" % [required.size() - unseen.size(), required.size()]]
	lines.append("未查看：%s" % ("、".join(unseen) if not unseen.is_empty() else "无"))
	return "\n".join(lines)


func _debug_available_topics() -> String:
	var lines: Array[String] = []
	var beats := _presentation_beats(_presentations_for_stage(state.current_stage))
	var response_index := _pending_player_response_index(beats)
	if response_index >= 0:
		return "• %s" % str(beats[response_index].get("text", ""))
	for row: Dictionary in story.available_choices(state.current_stage, state):
		lines.append("• %s" % str(row.get("玩家可选台词", "")))
	if lines.is_empty() and _has_presentation_next(state.current_stage):
		lines.append("• 继续演出")
	if lines.is_empty():
		return "（当前没有新话题）"
	return "\n".join(lines.slice(0, 7))


func debug_jump(destination: String) -> void:
	chapter_panel.hide()
	state.reset()
	_entry_results_applied.clear()
	_choice_checkpoints.clear()
	_dialogue_context.clear()
	match destination:
		"序章":
			_go_to_stage("前序·退稿与派活")
		"戏院门前":
			_go_to_stage("第一章·报馆换人了")
		"林怀安采访":
			state.apply_result("letter_preparation=left_home; evidence.letter_original.holder=newsroom")
			_go_to_stage("第一章·纪念演出采访")
		"第一眼":
			_go_to_stage("第一章·第一眼")
		"警方笔录":
			state.apply_result("letter_preparation=left_home; evidence.letter_original.holder=newsroom")
			_go_to_stage("第一章·沈砚舟的笔录")
		"写稿":
			state.apply_result("report_focus=confirmed")
			_go_to_stage("第一章·第一篇稿")


func _draw_backstage() -> void:
	var is_newsroom: bool = state.current_scene.contains("日报") or state.current_scene.contains("报纸") or state.current_scene.contains("写稿桌")
	var is_passage: bool = state.current_scene.contains("通道") or state.current_scene.contains("侧台") or state.current_scene.contains("天桥")
	var base := Color("232922") if is_newsroom else Color("2b2823")
	if is_passage:
		base = Color("252923")
	_rect(canvas, Rect2(0, 0, 1280, 720), Color("101511"))
	_rect(canvas, Rect2(0, 65, 1280, 590), base)
	if is_newsroom:
		_rect(canvas, Rect2(35, 92, 300, 235), Color("1e251f"), Color("3d493f"), 2)
		_rect(canvas, Rect2(382, 100, 500, 225), Color("34372f"), Color("5a5747"), 2)
		_rect(canvas, Rect2(925, 88, 320, 240), Color("202620"), Color("3d493f"), 2)
		_label(canvas, "排字房 / 版样", Rect2(70, 280, 230, 28), 14, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
		_label(canvas, "稿件与采访本", Rect2(500, 278, 260, 28), 14, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
		_label(canvas, "档案柜 / 旧报", Rect2(970, 280, 220, 28), 14, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_rect(canvas, Rect2(30, 90, 330, 235), Color("20251f"), Color("3d493f"), 2)
		_rect(canvas, Rect2(910, 85, 335, 240), Color("1e241f"), Color("3d493f"), 2)
		_rect(canvas, Rect2(380, 105, 500, 225), Color("31362d"), Color("4e4c3e"), 2)
		_label(canvas, "前场", Rect2(95, 278, 200, 28), 14, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
		_label(canvas, "台侧 / 景路", Rect2(520, 278, 220, 28), 14, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
		_label(canvas, "侧厅 / 通道", Rect2(980, 278, 200, 28), 14, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	_rect(canvas, Rect2(0, 610, 1280, 110), Color("171813"))
	_label(canvas, state.current_scene, Rect2(25, 12, 520, 42), 24, PAPER)
	_label(canvas, "[ 当前地点 ]", Rect2(455, 15, 370, 38), 14, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)


func _presentations_use_interaction(presentations: Array[Dictionary], interaction_tag: String) -> bool:
	for row: Dictionary in presentations:
		if interaction_tag in str(row.get("演出/交互方式", "")):
			return true
	return false


func _draw_rejected_manuscript_ui() -> void:
	# 退稿原因由稿面直接表达：层叠、密集红改、整段划去和“撤”章。
	# 不再把这些视觉信息复述成旁白，也不新增编辑方法论判词。
	var paper_shadow := _rect(canvas, Rect2(450, 126, 350, 184), Color(0.06, 0.07, 0.06, 0.42))
	var paper_back := _rect(canvas, Rect2(432, 116, 350, 184), Color("8e866f"), Color("b3a984"), 1)
	var paper_front := _rect(canvas, Rect2(455, 105, 350, 202), Color("d2c7a5"), Color("766a52"), 2)
	for paper: Control in [paper_shadow, paper_back, paper_front]:
		_mark_rejected_manuscript_node(paper)

	var title_line := _rect(canvas, Rect2(485, 132, 132, 5), Color("675f50"))
	var header_line := _rect(canvas, Rect2(485, 150, 235, 3), Color("8a8069"))
	var body_line_one := _rect(canvas, Rect2(485, 177, 265, 4), Color("746b59"))
	var body_line_two := _rect(canvas, Rect2(485, 198, 238, 4), Color("746b59"))
	var body_line_three := _rect(canvas, Rect2(485, 219, 276, 4), Color("746b59"))
	var body_line_four := _rect(canvas, Rect2(485, 240, 215, 4), Color("746b59"))
	for manuscript_line: Control in [title_line, header_line, body_line_one, body_line_two, body_line_three, body_line_four]:
		_mark_rejected_manuscript_node(manuscript_line)

	var deletion_one := _rect(canvas, Rect2(478, 194, 286, 5), RED_LIGHT)
	var deletion_two := _rect(canvas, Rect2(480, 212, 280, 5), RED_LIGHT)
	for deletion: Control in [deletion_one, deletion_two]:
		deletion.pivot_offset = deletion.size * 0.5
		deletion.rotation = deg_to_rad(-2.2)
		_mark_rejected_manuscript_node(deletion)

	var stamp_border := _rect(canvas, Rect2(678, 236, 86, 52), Color(0.45, 0.12, 0.1, 0.08), RED_LIGHT, 3)
	stamp_border.pivot_offset = stamp_border.size * 0.5
	stamp_border.rotation = deg_to_rad(-8.0)
	_mark_rejected_manuscript_node(stamp_border)
	var stamp := _label(canvas, "撤", Rect2(694, 234, 58, 52), 38, RED_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	stamp.pivot_offset = stamp.size * 0.5
	stamp.rotation = deg_to_rad(-8.0)
	_mark_rejected_manuscript_node(stamp)


func _mark_rejected_manuscript_node(node: Control) -> void:
	node.set_meta("rejected_manuscript_ui", true)


func _draw_scene_action_ui(actions: Array) -> void:
	# 场景动作只驱动背景中的物件与运动提示；动作原文永不进入对话框。
	var action_text := "\n".join(PackedStringArray(actions))
	if _should_draw_publication_text_panel(action_text):
		_draw_publication_text_panel(actions)
		return
	if "版样" in action_text and "抽走" not in action_text:
		_draw_typeset_proof_action()
	if ("稿" in action_text and "推" in action_text) or "往前" in action_text:
		_draw_manuscript_push_action()
	if "采访单" in action_text or "钥匙" in action_text:
		_draw_assignment_materials_action()
	_draw_generic_scene_action(actions)


func _should_draw_publication_text_panel(action_text: String) -> bool:
	if state.current_stage == "第一章·次日见报":
		return true
	if state.current_topic == "见报之后":
		return true
	return action_text.contains("这一篇见报之后")


func _draw_publication_text_panel(actions: Array) -> void:
	var publication_lines := _publication_copy_lines()
	if publication_lines.is_empty():
		return
	var panel_title := "《雾港日报》·见报" if state.current_stage == "第一章·次日见报" else "见报之后"
	var card := _rect(canvas, Rect2(250, 78, 780, 320), Color("d8ccb0"), Color("756d58"), 2)
	_mark_scene_action_node(card, "publication_panel")
	_label(canvas, panel_title, Rect2(278, 94, 260, 30), 18, PAPER_DARK)
	var copy_scroll := ScrollContainer.new()
	copy_scroll.position = Vector2(276, 134)
	copy_scroll.size = Vector2(730, 246)
	copy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(copy_scroll)
	var copy_list := VBoxContainer.new()
	copy_list.custom_minimum_size = Vector2(700, 0)
	copy_list.add_theme_constant_override("separation", 8)
	copy_scroll.add_child(copy_list)
	for clean: String in publication_lines:
		var line_height := 112.0 if clean.begins_with("稿件正文｜") else 54.0
		var label := _label(copy_list, clean, Rect2(0, 0, 700, line_height), 17, INK)
		label.custom_minimum_size = Vector2(700, line_height)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_mark_scene_action_node(label, "publication_panel")
	var consequence_lines := _publication_consequence_lines()
	if not consequence_lines.is_empty():
		var consequence_card := _rect(canvas, Rect2(40, 430, 700, 145), Color(0.055, 0.075, 0.06, 0.96), Color("65705e"), 1)
		_mark_scene_action_node(consequence_card, "publication_consequence")
		_label(canvas, "见报后的即时反应", Rect2(62, 444, 300, 26), 16, PAPER_DARK)
		var consequence_y := 478.0
		for consequence: String in consequence_lines:
			var consequence_label := _label(canvas, consequence, Rect2(62, consequence_y, 650, 46), 15, PAPER)
			consequence_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_mark_scene_action_node(consequence_label, "publication_consequence")
			consequence_y += 48.0


func _publication_copy_lines() -> Array[String]:
	# C21/C22 的报纸卡只承载“画面表现”里的实际见报文字。
	# 动作/表情备注仍由场景动作层使用，不能混进读者看到的版面。
	var lines: Array[String] = []
	for row: Dictionary in _presentations_for_stage(state.current_stage):
		var copy := str(row.get("画面表现", "")).strip_edges()
		if copy.is_empty():
			continue
		for raw_line: String in copy.split("\n", false):
			var clean := raw_line.strip_edges()
			if not clean.is_empty():
				lines.append(clean)
	if state.current_stage == "第一章·次日见报":
		var written_copy := str(state.technical_values.get("writing_copy_text", "")).strip_edges()
		if not written_copy.is_empty():
			lines.append("稿件正文｜" + written_copy)
	return lines


func _publication_consequence_lines() -> Array[String]:
	var lines: Array[String] = []
	for row: Dictionary in _presentations_for_stage(state.current_stage):
		var consequence := str(row.get("动作/表情备注", "")).strip_edges()
		if consequence.is_empty():
			continue
		for raw_line: String in consequence.split("\n", false):
			var clean := raw_line.strip_edges()
			if not clean.is_empty() and not lines.has(clean):
				lines.append(clean)
	return lines


func _draw_generic_scene_action(actions: Array) -> void:
	if actions.is_empty():
		return
	var card := _rect(canvas, Rect2(410, 72, 460, 72), Color(0.055, 0.075, 0.06, 0.94), Color("65705e"), 1)
	_mark_scene_action_node(card, "scene_progress")
	var visible_count := mini(actions.size(), 4)
	for index in visible_count:
		var token := _rect(canvas, Rect2(452 + index * 92, 96, 64, 20), Color("77816e"), Color("9a9277"), 1)
		_mark_scene_action_node(token, "scene_progress")


func _draw_typeset_proof_action() -> void:
	var proof_shadow := _rect(canvas, Rect2(326, 142, 118, 146), Color(0.04, 0.05, 0.04, 0.5))
	var proof := _rect(canvas, Rect2(318, 134, 118, 146), Color("b7ae92"), Color("756d58"), 2)
	var proof_header := _rect(canvas, Rect2(335, 153, 70, 5), Color("5d584c"))
	var proof_column_left := _rect(canvas, Rect2(335, 174, 30, 78), Color("89816c"))
	var proof_column_right := _rect(canvas, Rect2(374, 174, 42, 78), Color("89816c"))
	for node: Control in [proof_shadow, proof, proof_header, proof_column_left, proof_column_right]:
		_mark_scene_action_node(node, "typeset_proof")


func _draw_manuscript_push_action() -> void:
	# 稿件本体由退稿 UI 绘制；这里仅用桌面上的位移轨迹表现“推过去”。
	var motion_one := _rect(canvas, Rect2(402, 260, 34, 3), Color(0.75, 0.7, 0.55, 0.22))
	var motion_two := _rect(canvas, Rect2(414, 270, 52, 3), Color(0.75, 0.7, 0.55, 0.38))
	var motion_three := _rect(canvas, Rect2(430, 280, 62, 3), Color(0.75, 0.7, 0.55, 0.58))
	var leading_edge := _rect(canvas, Rect2(486, 104, 5, 204), Color(0.72, 0.33, 0.28, 0.75))
	for node: Control in [motion_one, motion_two, motion_three, leading_edge]:
		_mark_scene_action_node(node, "manuscript_forward")


func _draw_assignment_materials_action() -> void:
	var form_shadow := _rect(canvas, Rect2(636, 154, 126, 112), Color(0.04, 0.05, 0.04, 0.45))
	var form := _rect(canvas, Rect2(628, 146, 126, 112), Color("c2b795"), Color("736a54"), 2)
	var form_header := _rect(canvas, Rect2(646, 165, 76, 5), Color("645e4e"))
	var form_line_one := _rect(canvas, Rect2(646, 187, 88, 3), Color("837a65"))
	var form_line_two := _rect(canvas, Rect2(646, 204, 78, 3), Color("837a65"))
	var key_ring := _rect(canvas, Rect2(704, 222, 23, 23), Color(0.08, 0.09, 0.07, 0.9), PAPER_DARK, 4)
	var key_shaft := _rect(canvas, Rect2(724, 230, 58, 8), PAPER_DARK)
	var key_tooth := _rect(canvas, Rect2(766, 235, 8, 15), PAPER_DARK)
	for node: Control in [form_shadow, form, form_header, form_line_one, form_line_two, key_ring, key_shaft, key_tooth]:
		_mark_scene_action_node(node, "assignment_materials")


func _mark_scene_action_node(node: Control, action_kind: String) -> void:
	node.set_meta("scene_action_ui", true)
	node.set_meta("scene_action_kind", action_kind)


func _draw_portrait(character: String) -> void:
	if character.is_empty() or character in ["场景", "旁白", "系统"]:
		return
	var portrait_color := Color("38433b")
	if character == "林玉棠":
		portrait_color = Color("4a4038")
	elif character == "陈九生":
		portrait_color = Color("343b35")
	_rect(canvas, Rect2(125, 100, 250, 215), Color("171c18"), Color("575e50"), 2)
	_rect(canvas, Rect2(180, 132, 140, 140), portrait_color, Color("716b57"), 2)
	_label(canvas, "[ %s立绘 ]" % character, Rect2(145, 277, 210, 28), 14, PAPER_DARK, HORIZONTAL_ALIGNMENT_CENTER)


func _rect(parent: Node, bounds: Rect2, color: Color, border_color: Color = Color.TRANSPARENT, border_width := 0) -> Panel:
	var panel := Panel.new()
	panel.position = bounds.position
	panel.size = bounds.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _label(parent: Node, text_value: String, bounds: Rect2, font_size := 22, color: Color = PAPER, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = bounds.position
	label.size = bounds.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _button(parent: Node, text_value: String, bounds: Rect2, callback: Callable, accent := false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = bounds.position
	button.size = bounds.size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = RED if accent else Color(0.09, 0.13, 0.11, 0.96)
	normal.border_color = RED_LIGHT if accent else Color(0.34, 0.41, 0.35, 0.88)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = RED_LIGHT.darkened(0.25) if accent else JADE
	hover.border_color = PAPER_DARK
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.pressed.connect(func() -> void:
		if button.is_queued_for_deletion() or not button.is_inside_tree() or button.disabled:
			return
		callback.call()
	)
	parent.add_child(button)
	return button
