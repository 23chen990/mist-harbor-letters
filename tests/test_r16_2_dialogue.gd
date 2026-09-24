extends SceneTree

const RuntimeScript = preload("res://scripts/r16_2_runtime.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var runtime = RuntimeScript.new()
	_expect(runtime.load_runtime(), "R16.2 runtime JSON 无法加载")
	if failures > 0:
		_finish()
		return

	var event: Dictionary = runtime.enter_node("D02")
	_expect(str(event.get("kind", "")) == "dialogue", "D02 应先进入逐句对白，而不是直接显示选项")
	_expect(not str(event.get("summary", "")).contains(" / "), "D02 首次对白不应包含整段斜杠串联文本")
	_expect(not str(event.get("summary", "")).contains("【若"), "玩家对白不应显示条件标记")
	_expect(runtime.pending_kind == "dialogue", "逐句对白未结束前运行时应保持 dialogue 状态")
	_expect(runtime.available_choices().is_empty(), "逐句对白未结束前不应暴露节点选择")
	var saw_player_response := false

	var dialogue_steps := 0
	while runtime.pending_kind == "dialogue" and dialogue_steps < 64:
		dialogue_steps += 1
		if bool(event.get("payload", {}).get("is_player_response", false)):
			saw_player_response = true
			_expect(not str(event.get("payload", {}).get("response_text", "")).is_empty(), "主控回应必须携带实际台词")
		event = runtime.advance_dialogue()
	_expect(dialogue_steps > 3, "D02 应使用正文完整逐句对白，不能只剩接入表摘要（实际 %d 句）" % dialogue_steps)
	_expect(dialogue_steps < 64, "D02 逐句对白没有正常结束")
	_expect(str(event.get("kind", "")) == "choice", "D02 最后一句后才应显示选择")
	_expect(runtime.available_choices().size() == 2, "D02 最后一句后应显示两项选择")
	_expect(saw_player_response, "D02 应至少出现一个可点击的主控回应节拍")
	_expect(not str(event.get("summary", "")).contains(" / "), "D02 选择阶段不能恢复整段摘要")
	_expect(not str(event.get("summary", "")).is_empty(), "选择阶段应保留最后一句已读对白")
	event = runtime.choose("C_U02_A")
	_expect(str(event.get("kind", "")) == "choice_feedback", "选择后应先展示接入表中的即时反馈")
	_expect(str(event.get("summary", "")) == str(runtime.data.choices.C_U02_A.immediate_feedback), "选择反馈必须与接入表一致")
	_expect(runtime.current_node_id == "D02", "反馈读完前不应跳到下一场")
	event = runtime.rollback("SS_C_U02_A")
	_expect(event.get("kind") == "choice", "回到上一次选择应直接回到选项，不重播整场")
	_expect(not runtime.state.get_value("heard_fang_first", false), "回退应撤销该次选择写入")

	event = runtime.enter_node("D09")
	_expect(str(event.get("kind", "")) == "dialogue", "D09 应进入条件过滤后的逐句对白")
	_expect(not str(event.get("summary", "")).contains("【若"), "D09 条件标记不应泄露给玩家")
	_expect(not str(event.get("summary", "")).contains("/"), "D09 首句不应把多条对白一次性显示")
	while runtime.pending_kind == "dialogue":
		event = runtime.advance_dialogue()
	_expect(not str(event.get("summary", "")).contains("【若"), "D09 选项出现时也不能恢复条件原文")

	for route: String in ["article_final_correction_only", "article_final_privacy", "article_final_full"]:
		runtime.load_runtime()
		runtime.state.apply_mutations(route + "=1")
		event = runtime.enter_node("D68")
		_expect(event.get("kind") == "dialogue", "U31 必须显示对应的离别路线反馈")
		_expect(runtime.dialogue_beats.size() > 1, "U31 应显示路线反馈及其后续完整对白")
		var route_text := str(event.get("summary", ""))
		if bool(event.get("payload", {}).get("is_player_response", false)):
			route_text = str(event.get("payload", {}).get("response_text", ""))
		_expect(not route_text.is_empty(), "U31 路线反馈应来自正文对白或主控回应按钮")
		_expect(runtime.state.evaluator.errors.is_empty(), "U31 条件别名不能造成 DSL 错误")

	runtime.load_runtime()
	event = runtime.enter_node("D15-B")
	_expect(event.get("kind") == "puzzle", "排序场景应直接显示交互，不朗读后台摘要")
	_expect(not str(event.get("summary", "")).contains("→"), "排序题不能先泄露正确顺序")
	runtime.state.apply_mutations("draft_main=FACTS_PRIVACY")
	event = runtime.enter_node("D65-B")
	_expect(event.get("kind") == "draft_preview", "自动组稿不应成为需要点击的对白")
	_expect(runtime.current_node_id == "D65-C", "自动组稿应直接进入预览")

	runtime.load_runtime()
	event = runtime.enter_node("D27")
	while runtime.pending_kind == "dialogue":
		event = runtime.advance_dialogue()
	event = runtime.solve_puzzle("C_DYNAMIC")
	_expect(event.get("kind") == "choice", "核稿成功后应显示开头选择，不从头重播整场")

	_finish()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: R16.2 dialogue pacing and condition filtering")
		quit(0)
	else:
		push_error("FAIL: %d R16.2 dialogue assertions" % failures)
		quit(1)
