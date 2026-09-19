extends SceneTree

const RuntimeScript = preload("res://scripts/r16_2_runtime.gd")
const ConditionEvaluatorScript = preload("res://scripts/r16_2_condition_evaluator.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_typed_condition_literals()
	var runtime = RuntimeScript.new()
	_expect(runtime.load_runtime(), "R16.2 runtime JSON 无法加载")
	if failures > 0:
		_finish()
		return
	var event: Dictionary = runtime.start()
	var guard := 0
	while guard < 160 and str(event.get("kind", "")) != "ending":
		guard += 1
		var kind := str(event.get("kind", ""))
		if kind == "error":
			_expect(false, "运行时错误：%s" % str(event.get("error", "")))
			break
		if runtime.pending_kind == "puzzle":
			if runtime.pending_puzzle_id == "P_U15_CHAIN":
				event = runtime.solve_puzzle(["A", "B", "C", "D", "E"])
			else:
				event = runtime.solve_puzzle(runtime.expected_invalid_card())
			continue
		if runtime.pending_kind == "draft_preview":
			event = runtime.confirm_typeset()
			continue
		var choices: Array[Dictionary] = runtime.available_choices()
		_expect(not choices.is_empty(), "节点 %s 没有可用选择" % runtime.current_node_id)
		if choices.is_empty():
			break
		var selected_choice_id := str(choices[0].get("choice_id", ""))
		if runtime.current_node_id == "D08":
			var selected_event: Dictionary = runtime.choose(selected_choice_id)
			_expect(str(selected_event.get("kind", "")) == "headline_selected", "U08 should require a send-to-typeset confirmation")
			event = runtime.confirm_headline()
		else:
			event = runtime.choose(selected_choice_id)
	_expect(guard < 160, "R16.2 canonical route exceeded step guard")
	_expect(str(event.get("kind", "")) == "ending", "R16.2 canonical route did not reach ending")
	_expect(str(event.get("ending_id", "")) in ["E01", "E02", "E03", "E04"], "ending id invalid")
	_expect(runtime.state.get_value("typeset_confirmed", false) == true, "确认交排没有写入 typeset_confirmed")
	_expect(runtime.state.get_value("actual_published", false) == true, "D66 没有写入 actual_published")
	_expect(runtime.state.get_value("article_delivered_yutang", false) == true, "发行后未写入 delivered 状态")
	_expect(runtime.state.get_value("article_read_yutang", false) == true, "发行后未写入 read 状态")
	_expect(runtime.state.get_value("medicine_chain_reconstructed", false) == true, "U15 药物链谜题未成功")
	_expect(runtime.state.get_value("proofcheck_done", false) == true, "U27 核稿谜题未成功")
	_test_global_survives_story_rollback(runtime)
	_finish()


func _test_typed_condition_literals() -> void:
	var evaluator = ConditionEvaluatorScript.new()
	evaluator.configure({
		"count": {"type": "int"},
		"flag": {"type": "bool"},
	})
	var values: Dictionary = {"count": 2, "flag": false}
	_expect(evaluator.evaluate("count=2", values), "typed int equality should compare numerically")
	_expect(not evaluator.evaluate("count=1", values), "typed int equality must not coerce 2 to true")
	_expect(evaluator.evaluate("flag=0", values), "bool 0 literal should compare as false")
	_expect(not evaluator.evaluate("flag=1", {"count": 2, "flag": false}), "bool 1 literal should compare as true only when flag is true")


func _test_global_survives_story_rollback(runtime: RefCounted) -> void:
	var snapshot_id := "SS_C_U01_A"
	var before: Variant = runtime.state.get_value("unlocked_endings", [])
	runtime.state.add_value("unlocked_endings", "E03")
	var result: Dictionary = runtime.rollback(snapshot_id)
	_expect(str(result.get("kind", "")) != "error", "选择快照无法回溯：%s" % str(result))
	_expect((runtime.state.get_value("unlocked_endings", []) as Array).has("E03"), "回溯错误清除了 global ending unlock")
	_expect(before is Array, "global 快照测试前置状态非法")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: R16.2 runtime canonical route, puzzles, publish lifecycle, and rollback scope")
		quit(0)
	else:
		push_error("FAIL: %d R16.2 runtime assertions" % failures)
		quit(1)
