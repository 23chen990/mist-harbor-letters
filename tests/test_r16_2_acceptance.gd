extends SceneTree

const RuntimeScript = preload("res://scripts/r16_2_runtime.gd")

var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_route("A", {
		"C_U01_B": true,
		"C_U07_A": true,
		"C_U08_A": true,
		"C_U15_A": true,
		"C_U17_B": true,
		"C_U18_A": true,
		"C_U21_B": true,
		"C_U22_A": true,
		"C_U23_A": true,
		"C_U25_A": true,
		"C_U27_A": true,
		"C_U28_A": true,
		"C_U30_B": true,
		"C_U31_B": true,
		"C_U32_B": true,
	})
	_run_route("B", {
		"C_U01_A": true,
		"C_U07_B": true,
		"C_U08_B": true,
		"C_U11_A": true,
		"C_U13_B": true,
		"C_U15_B": true,
		"C_U18_B": true,
		"C_U21_A": true,
		"C_U23_B": true,
		"C_U25_B": true,
		"C_U26_B": true,
		"C_U27_B": true,
		"C_U28_B": true,
		"C_U30_B": true,
		"C_U31_A": true,
		"C_U32_A": true,
	})
	_run_route("C", {
		"C_U24_A": true,
		"C_U25_A": true,
		"C_U27_A": true,
		"C_U28_C": true,
		"C_U30_B": true,
		"C_U31_B": true,
		"C_U32_A": true,
	}, true)
	_run_route("D", {
		"C_U07_A": true,
		"C_U08_A": true,
		"C_U24_A": true,
		"C_U25_A": true,
		"C_U27_A": true,
		"C_U28_A": true,
		"C_U30_A": true,
		"C_U31_B": true,
		"C_U32_B": true,
	})
	if failures == 0:
		print("PASS: R16.2 routes A/B/C/D, privacy barrier, puzzle retry, and ending priority")
		quit(0)
	else:
		push_error("FAIL: %d R16.2 acceptance assertions" % failures)
		quit(1)


func _run_route(label: String, preferred: Dictionary, exercise_wrong_u27: bool = false) -> void:
	var runtime = RuntimeScript.new()
	_expect(runtime.load_runtime(), "%s: runtime JSON 无法加载" % label)
	if not runtime.errors.is_empty():
		return
	var event: Dictionary = runtime.start()
	var guard: int = 0
	var preview_checked: bool = false
	var u15_wrong_checked: bool = false
	var u27_wrong_checked: bool = false
	while guard < 2000 and str(event.get("kind", "")) != "ending":
		guard += 1
		var kind := str(event.get("kind", ""))
		var text := str(event.get("summary", ""))
		for marker: String in ["【若", " / ", "=>", "EXPOSED", "PROTECTED", "CORRECTION", "后台自动"]:
			_expect(not text.contains(marker), "%s: %s leaked authoring text: %s" % [label, runtime.current_node_id, marker])
		if kind == "error":
			_expect(false, "%s: runtime error %s" % [label, str(event.get("error", ""))])
			return
		if runtime.pending_kind == "dialogue":
			event = runtime.advance_dialogue()
			continue
		if runtime.pending_kind == "choice_feedback":
			event = runtime.advance_choice_feedback()
			continue
		if runtime.pending_kind == "puzzle":
			if runtime.pending_puzzle_id == "P_U15_CHAIN":
				if not u15_wrong_checked:
					var wrong_u15: Dictionary = runtime.solve_puzzle(["A", "C", "B", "D", "E"])
					_expect(str(wrong_u15.get("kind", "")) == "puzzle_wrong", "%s: U15 wrong order should retry" % label)
					u15_wrong_checked = true
				event = runtime.solve_puzzle(["A", "B", "C", "D", "E"])
			else:
				if exercise_wrong_u27 and not u27_wrong_checked:
					var wrong_u27: Dictionary = runtime.solve_puzzle("A")
					_expect(str(wrong_u27.get("kind", "")) == "puzzle_wrong", "%s: U27 invalid card should retry" % label)
					u27_wrong_checked = true
					event = runtime.solve_puzzle(runtime.expected_invalid_card())
				else:
					event = runtime.solve_puzzle(runtime.expected_invalid_card())
			continue
		if runtime.pending_kind == "draft_preview":
			preview_checked = true
			_expect(not bool(runtime.state.get_value("actual_published", false)), "%s: preview published too early" % label)
			_expect(str(runtime.article_preview.get("lifecycle", "")) == "preview", "%s: preview lifecycle missing" % label)
			if label == "B":
				var excluded: Array = runtime.article_preview.get("excluded", [])
				_expect(_contains_text(excluded, "off-record"), "B: off-record material leaked into preview")
				excluded = runtime.article_preview.get("excluded", [])
				_expect(_contains_text(excluded, "未授权"), "B: private motive protection missing")
			event = runtime.confirm_typeset()
			continue
		if runtime.pending_kind == "headline_confirm":
			event = runtime.confirm_headline()
			continue
		var choices: Array[Dictionary] = runtime.available_choices()
		_expect(not choices.is_empty(), "%s: node %s has no available choice" % [label, runtime.current_node_id])
		if choices.is_empty():
			return
		var choice_id := _preferred_choice(choices, preferred)
		event = runtime.choose(choice_id)
	_expect(guard < 2000, "%s: route exceeded step guard" % label)
	_expect(str(event.get("kind", "")) == "ending", "%s: route did not reach ending" % label)
	var expected_ending: String = str({"A": "E01", "B": "E02", "C": "E03", "D": "E04"}.get(label, ""))
	_expect(str(event.get("ending_id", "")) == expected_ending, "%s: expected %s, got %s" % [label, expected_ending, str(event.get("ending_id", ""))])
	_expect(preview_checked, "%s: never reached D65-C preview" % label)
	_expect(runtime.state.get_value("typeset_confirmed", false) == true, "%s: typeset confirmation missing" % label)
	_expect(runtime.state.get_value("actual_published", false) == true, "%s: publication flag missing" % label)
	_expect(runtime.state.get_value("article_read_yutang", false) == true, "%s: read flag missing" % label)
	_expect(runtime.state.mutation_errors.is_empty(), "%s: condition/mutation errors leaked: %s" % [label, str(runtime.state.mutation_errors)])


func _preferred_choice(choices: Array[Dictionary], preferred: Dictionary) -> String:
	for row: Dictionary in choices:
		var choice_id := str(row.get("choice_id", ""))
		if preferred.has(choice_id):
			return choice_id
	return str(choices[0].get("choice_id", ""))


func _contains_text(values: Array, needle: String) -> bool:
	for value: Variant in values:
		if needle in str(value):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
