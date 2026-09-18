extends SceneTree

const StoryRepositoryScript = preload("res://scripts/story_repository.gd")
const GameStateScript = preload("res://scripts/game_state.gd")

var failures := 0


func _init() -> void:
	var story = StoryRepositoryScript.new()
	_expect(story.load_story("res://content/程序生成_请勿手改/剧情剧本.csv"), "v6 剧情表加载失败")
	_check_manual_dialogue_beats(story)
	_check_visual_nodes(story)
	_check_v6_choice_counts(story)
	_finish()


func _check_manual_dialogue_beats(story: RefCounted) -> void:
	var main_script = load("res://scripts/main.gd").new()
	main_script.story = story
	var state = GameStateScript.new()
	state.apply_result("letter_preparation=left_home")
	var rows: Array[Dictionary] = story.available_presentations("第一章·纪念演出采访", state)
	var beats: Array[Dictionary] = main_script._presentation_beats(rows)
	_expect(beats.size() == 10, "C04 公共采访应保留十句并把函件内容移入后继分支")
	for beat: Dictionary in beats:
		if bool(beat.get("dialogue_visible", true)):
			_expect(str(beat.get("text", "")).begins_with("「"), "C04 对话框混入场景说明：%s" % beat.get("text", ""))
	main_script.free()


func _check_visual_nodes(story: RefCounted) -> void:
	var state = GameStateScript.new()
	state.apply_result("report_focus=confirmed")
	for stage: String in ["第一章·第一眼", "第一章·现场收束", "第一章·次日见报", "第一章·第一章结尾"]:
		var presentations: Array[Dictionary] = story.available_presentations(stage, state)
		_expect(not presentations.is_empty(), "v6 纯画面阶段缺少内容：%s" % stage)


func _check_v6_choice_counts(story: RefCounted) -> void:
	var state = GameStateScript.new()
	state.apply_result("c05_intro=true; c05_observation_count=0")
	var expected_counts := {
		"第一章·开锣前": 4,
		"第一章·演出中段": 4,
		"第一章·谢幕前后": 4,
		"第一章·第一眼": 3,
		"第一章·警方到场前": 3,
		"第一章·现场收束": 4,
		"第一章·是否写入赵敬文": 2,
	}
	for stage: String in expected_counts:
		var choices: Array[Dictionary] = story.available_choices(stage, state)
		_expect(choices.size() == int(expected_counts[stage]), "%s 的 v6 选择数不正确：%d" % [stage, choices.size()])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: v6 continuous scene contract")
		quit(0)
	else:
		push_error("FAIL: %d v6 continuous-scene assertions" % failures)
		quit(1)
