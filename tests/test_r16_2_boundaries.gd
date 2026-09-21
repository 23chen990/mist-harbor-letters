extends SceneTree

const RuntimeScript = preload("res://scripts/r16_2_runtime.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_partial_confession_boundary()
	_test_letter_and_source_boundaries()
	_test_article_permission_barriers()
	if failures == 0:
		print("PASS: R16.2 knowledge, source, and article permission boundaries")
		quit(0)
	else:
		push_error("FAIL: %d R16.2 boundary assertions" % failures)
		quit(1)


func _new_runtime():
	var runtime = RuntimeScript.new()
	_expect(runtime.load_runtime(), "runtime JSON 无法加载")
	return runtime


func _dialogue_text(runtime) -> String:
	var lines: Array[String] = []
	var event: Dictionary = runtime.enter_node(runtime.current_node_id)
	while runtime.pending_kind == "dialogue":
		lines.append(str(event.get("summary", "")))
		event = runtime.advance_dialogue()
	return "\n".join(lines)


func _test_partial_confession_boundary() -> void:
	var runtime = _new_runtime()
	runtime.state.apply_mutations("yutang_partial_confession=1")
	var text := _dialogue_text_at(runtime, "D12")
	_expect(text.contains("为什么，我现在不想说"), "U11B should expose only the partial confession")
	_expect(not text.contains("谢家来的人不会在散戏后谈婚期"), "U11B should not reveal the full private motive")
	_expect(not runtime.state.get_value("yutang_full_confession", false), "U11B should not grant full confession state")


func _test_letter_and_source_boundaries() -> void:
	var runtime = _new_runtime()
	runtime.state.apply_mutations("privacy_boundary_respected=1")
	_expect(not runtime.state.get_value("read_father_copy", false), "U13B should not grant the father-letter copy")
	var text := _dialogue_text_at(runtime, "D17")
	_expect(not text.contains("我见过原件"), "U17 should not leak the original letter without the relevant lead")


func _test_article_permission_barriers() -> void:
	var runtime = _new_runtime()
	runtime.state.apply_mutations("draft_main=FULL_NAMES; promise_yutang_offrecord=1; promise_liang_anonymous=1; chen_confession_reportable=1")
	var preview: Dictionary = runtime.article_builder.build_preview()
	var excluded: Array = preview.get("excluded", [])
	_expect(_contains(excluded, "玉棠 off-record"), "full names preset must preserve 玉棠 off-record barrier")
	_expect(_contains(excluded, "老梁实名"), "anonymous source promise must survive full names preset")

	runtime.load_runtime()
	runtime.state.apply_mutations("draft_main=FACTS_PRIVACY; anonymous_workers=1")
	preview = runtime.article_builder.build_preview()
	_expect(_contains(preview.get("included", []), "匿名工人/琴师生计原话"), "anonymous worker route should affect the privacy article")
	_expect(not _contains(preview.get("excluded", []), "工人直接引语"), "anonymous worker route should not be treated as protected-worker omission")

	runtime.load_runtime()
	runtime.state.apply_mutations("draft_main=FACTS_PRIVACY; protect_workers=1")
	preview = runtime.article_builder.build_preview()
	_expect(_contains(preview.get("excluded", []), "工人直接引语"), "protected worker route must exclude direct worker quotes")

	runtime.load_runtime()
	runtime.state.apply_mutations("draft_main=FULL_NAMES")
	var event: Dictionary = runtime.enter_node("D26")
	_expect(event.get("kind") == "error", "U25A path must not enter U26 without explicit consent request")


func _dialogue_text_at(runtime, node_id: String) -> String:
	var event: Dictionary = runtime.enter_node(node_id)
	var lines: Array[String] = []
	while runtime.pending_kind == "dialogue":
		lines.append(str(event.get("summary", "")))
		event = runtime.advance_dialogue()
	return "\n".join(lines)


func _contains(values: Array, needle: String) -> bool:
	for value: Variant in values:
		if needle in str(value):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
