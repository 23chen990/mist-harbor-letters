extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")

const INVITATION := "林怀安主动邀请沈砚舟来到戏院"
const YUTANG_DENIAL := "林玉棠声称晚饭后没有再见父亲"
const CHEN_WITNESS := "陈九生无意透露晚饭后林玉棠还和父亲单独谈过"
const LIN_ALIVE := "林怀安谢幕时仍然活着"

var failures := 0


func _init() -> void:
	_test_world_truth_is_not_player_knowledge()
	_test_natural_language_conditions_need_real_knowledge()
	_test_deduction_is_not_created_by_conflicting_facts()
	_test_natural_language_results_and_history()
	_test_v16_state_expressions()
	_test_v27_unset_and_decrement_expressions()
	_test_v27_collection_membership_expression()
	_test_reset_clears_only_run_state()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _has_api(state: RefCounted, method_name: StringName) -> bool:
	var found := state.has_method(method_name)
	_expect(found, "缺少状态接口：%s" % method_name)
	return found


func _test_world_truth_is_not_player_knowledge() -> void:
	var state = GameStateScript.new()
	if not _has_api(state, &"knows"):
		return
	_expect(state.world_truths.has(LIN_ALIVE), "世界真相表中缺少林怀安存活事实")
	_expect(not state.knows(LIN_ALIVE), "世界真相被错误地自动写入玩家知识")


func _test_natural_language_conditions_need_real_knowledge() -> void:
	var state = GameStateScript.new()
	if not _has_api(state, &"condition_met") or not _has_api(state, &"learn"):
		return
	var contradiction := "已知“%s” 且 已知“%s”" % [YUTANG_DENIAL, CHEN_WITNESS]
	_expect(not state.condition_met(contradiction), "尚未听取证词时就开放了质问")
	state.learn(YUTANG_DENIAL)
	_expect(not state.condition_met(contradiction), "只有玉棠证词时就开放了质问")
	state.learn(CHEN_WITNESS)
	_expect(state.condition_met(contradiction), "亲耳听取两份冲突证词后仍未开放质问")


func _test_deduction_is_not_created_by_conflicting_facts() -> void:
	var state = GameStateScript.new()
	if not _has_api(state, &"has_deduction"):
		return
	state.learn(YUTANG_DENIAL)
	state.learn(CHEN_WITNESS)
	_expect(not state.has_deduction("玩家主动指出林玉棠证词矛盾"), "两条冲突信息自动变成了玩家判断")
	state.apply_result("形成判断“玩家主动指出林玉棠证词矛盾”")
	_expect(state.has_deduction("玩家主动指出林玉棠证词矛盾"), "玩家点击质问后没有记录主动判断")


func _test_natural_language_results_and_history() -> void:
	var state = GameStateScript.new()
	if not _has_api(state, &"apply_result") or not _has_api(state, &"record_choice"):
		return
	state.record_choice("你父亲为什么邀请我？", "提问", "auto-001")
	state.apply_result("记住“%s”；记录先谈对象为“林玉棠”；提高林玉棠压力" % INVITATION)
	_expect(state.knows(INVITATION), "自然语言结果没有写入玩家知识")
	_expect(state.first_interview_target == "林玉棠", "自然语言结果没有保存先谈对象")
	_expect(state.yutang_pressure_level == 1, "自然语言结果没有调整压力")
	_expect(state.choice_history.size() == 1, "玩家真正点击的选项没有记录")
	_expect(state.choice_history[0].get("玩家台词", "") == "你父亲为什么邀请我？", "选择历史没有保存人话台词")


func _test_reset_clears_only_run_state() -> void:
	var state = GameStateScript.new()
	if not _has_api(state, &"learn"):
		return
	state.learn(YUTANG_DENIAL)
	state.current_stage = "林玉棠·第二次谈话"
	state.demo_finished = true
	state.reset()
	_expect(not state.knows(YUTANG_DENIAL), "重新开始后仍保留玩家知识")
	_expect(state.current_stage == "前序·退稿与派活" and not state.demo_finished, "重新开始没有恢复编辑部退稿序章")
	_expect(state.world_truths.has(LIN_ALIVE), "重新开始不应删除世界真相")


func _test_v16_state_expressions() -> void:
	var state = GameStateScript.new()
	state.apply_result("letter_preparation=copied; evidence.letter_copy.exists=true; lin_questions_asked=0")
	_expect(state.condition_met("letter_preparation=copied or letter_preparation=original_carried"), "无法判断信件誊抄路线")
	_expect(not state.condition_met("letter_preparation=original_carried"), "错误命中未选择的原信随身路线")
	state.apply_result("lin_questions_asked +=1; lin_q_reply=asked")
	_expect(state.condition_met("lin_questions_asked<2 and lin_q_reply=asked"), "无法判断动态问题池状态")
	state.apply_result("lin_questions_asked +=1")
	_expect(state.condition_met("lin_questions_asked>=2"), "追问计数没有正确累加")
	state.apply_result("chen_belief_yutang_medicine_not_cause=true; chen_suspicion.external_actor=activated")
	_expect(state.condition_met("chen_suspicion.external_actor=activated"), "陈九生的外部介入怀疑没有写入")


func _test_v27_unset_and_decrement_expressions() -> void:
	var state = GameStateScript.new()
	_expect(state.condition_met("claims.to_police.letter_cooperation is unset"), "v2.7 无法判断尚未写入的状态")
	state.apply_result("claims.to_police.letter_cooperation=shown; police_credibility=1")
	_expect(not state.condition_met("claims.to_police.letter_cooperation is unset"), "已有口供状态仍被判断为未设置")
	state.apply_result("police_credibility -=2")
	_expect(state.condition_met("police_credibility=-1"), "v2.7 警方可信度减值没有正确执行")


func _test_v27_collection_membership_expression() -> void:
	var state = GameStateScript.new()
	state.apply_result("choices += C2_CHECK_THEATRE_REAR_LANE")
	_expect(state.condition_met("choices includes C2_CHECK_THEATRE_REAR_LANE"), "v2.7 无法判断玩家已经做过的选择")
	_expect(not state.condition_met("choices includes C2_CHECK_OTHER_PLACE"), "v2.7 错误命中玩家没有做过的选择")


func _finish() -> void:
	if failures == 0:
		print("PASS: natural-language knowledge state")
		quit(0)
	else:
		push_error("FAIL: %d state assertions" % failures)
		quit(1)
