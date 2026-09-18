extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var state_script: Script = load("res://interaction_state.gd")
	_test_desk_materials_and_letter_form(state_script.new())
	_test_s00_and_reply_probe_do_not_certify_a_reply(state_script.new())
	_test_position_and_hotspot_state_still_work(state_script.new())
	_test_claims_are_gated_by_actual_knowledge(state_script.new())
	_test_dynamic_claims_require_their_actual_source(state_script.new())
	_test_c11_does_not_unlock_medical_boundary(state_script.new())
	_test_c14_only_records_actual_police_disclosure(state_script.new())
	_test_c14_records_actual_arrival_and_first_look(state_script.new())
	_test_c16_followups_are_evidence_gated(state_script.new())
	_test_prepolice_action_does_not_silently_grant_evidence(state_script)
	_test_rope_claim_requires_rope_observation(state_script.new())
	_test_selecting_a_claim_does_not_submit(state_script.new())
	_test_claim_can_only_be_changed_once(state_script.new())
	_test_submit_returns_one_primary_consequence(state_script.new())
	_test_checking_ledger_finishes_the_run(state_script.new())
	_test_old_two_stage_writing_api_is_removed(state_script.new())
	_finish()


func _test_desk_materials_and_letter_form(state) -> void:
	if not _has_methods(state, [&"start_assignment", &"read_desk_material", &"desk_ready", &"choose_letter_form"]):
		return
	state.start_assignment()
	for material_id: String in ["performance_plan", "old_report", "interview_letter"]:
		_expect(state.read_desk_material(material_id), "无法读取必需桌面材料：%s" % material_id)
	_expect(not state.desk_ready(), "只读三份材料就能离开 S01")
	_expect(state.read_desk_material("old_map"), "无法读取可选旧草图")
	_expect(not state.desk_ready(), "可选草图错误替代了死亡报道")
	_expect(state.read_desk_material("death_report"), "无法读取赵敬文死亡报道")
	_expect(state.desk_ready(), "四份必需材料读完仍不能离开 S01")
	_expect(state.choose_letter_form("original"), "无法选择携带留底原件")
	_expect(state.letter_form == "original", "函件形态没有保存")
	_expect(not state.choose_letter_form("copy"), "函件形态选定后仍能改选")


func _test_s00_and_reply_probe_do_not_certify_a_reply(state) -> void:
	if not _has_methods(state, [&"start_assignment", &"read_desk_material", &"available_probe_choices", &"choose_probe"]):
		return
	_expect(state.start_assignment(), "S00 无法接下春和采访")
	_expect(state.read_desk_material("death_report"), "无法读取赵敬文死亡报道")
	_expect(state.read_desk_material("interview_letter"), "无法读取采访函留底")
	_expect(state.available_probe_choices() == ["desk_gap", "no_reply", "reply_missing"], "回信试探没有提供三句实际台词")
	_expect(state.choose_probe("reply_missing"), "回信试探无法选择")
	_expect(state.spoken_probe == "reply_missing", "没有保存玩家实际说过的试探")
	_expect(not state.has_knowledge("reply_exists"), "试探反应被错误认证为回信存在")


func _test_position_and_hotspot_state_still_work(state) -> void:
	_expect(state.choose_position("台侧外围"), "首次选择位置失败")
	_expect(not state.choose_position("前场"), "位置锁定后仍能换区")
	var hotspots: Array = state.available_hotspots("中段")
	_expect(hotspots.has("景片下沿"), "台侧缺少景片高度异常热点")
	_expect(state.observe_hotspot("中段", "景片下沿"), "有效热点无法观察")
	_expect(state.has_evidence("scenery_height"), "观察没有保存对应 evidence")
	_expect(not state.observe_hotspot("中段", "陈九生与阿成"), "同一节拍仍能选择第二个热点")


func _test_claims_are_gated_by_actual_knowledge(state) -> void:
	if not _has_methods(state, [&"available_claims", &"record_rumor_scene"]):
		return
	_expect(state.available_claims().is_empty(), "没有取得现场基础事实就出现完整稿句")
	state.record_drug_scene()
	_expect(state.available_claims().is_empty(), "没有亲闻旧疾口径就出现基础稿句")
	state.record_rumor_scene()
	var claims: Array = state.available_claims()
	_expect(claims.has("confirmed_only"), "取得死亡、旧疾与药盒经过后没有基础稿句")
	_expect(not claims.has("contact"), "没有读桌面材料却出现赵敬文联系稿句")
	state.start_assignment()
	state.read_desk_material("death_report")
	_expect(not state.available_claims().has("contact"), "只读死亡报道就出现赵敬文联系稿句")
	state.read_desk_material("interview_letter")
	_expect(state.available_claims().has("contact"), "读过死亡报道与采访函后仍无赵敬文联系稿句")


func _test_dynamic_claims_require_their_actual_source(state) -> void:
	if not _has_methods(state, [&"available_claims", &"record_rumor_scene"]):
		return
	state.choose_position("前场")
	state.observe_hotspot("中段", "方仲山账桌")
	state.observe_hotspot("谢幕", "空账桌")
	state.record_drug_scene()
	state.record_rumor_scene()
	_expect(not state.available_claims().has("fang_absent"), "只见离桌/空桌、未主动追问却开放方仲山稿句")

	var medical_state = state.get_script().new()
	medical_state.choose_position("观众席侧边")
	medical_state.observe_hotspot("中段", "通道旁的许济川")
	_expect(not medical_state.has_evidence("medical_boundary"), "C06 的处置对话被误认为 C11 死因边界")
	medical_state.record_drug_scene()
	medical_state.record_rumor_scene()
	_expect(not medical_state.has_evidence("medical_boundary"), "C11 直接解锁了只应由 C16 主动追问取得的 medical_boundary")
	_expect(not medical_state.available_claims().has("medical_boundary"), "C11 直接开放了 C16 追问稿句")

	var appointment_state = state.get_script().new()
	appointment_state.record_drug_scene()
	appointment_state.record_rumor_scene()
	appointment_state.evidence["found_position"] = true
	_expect(not appointment_state.available_claims().has("appointment_pair"), "尚未约见侧厅却开放弱路线稿句")
	_expect(appointment_state.record_appointment(), "C04 侧厅约见没有保存")
	_expect(appointment_state.available_claims().has("appointment_pair"), "侧厅约见与倒地岔口没有开放 v19 弱路线稿句")
	appointment_state.evidence["route_check"] = true
	_expect(not appointment_state.available_claims().has("appointment_pair"), "已有更强复走路线材料仍显示弱路线稿句")


func _test_c11_does_not_unlock_medical_boundary(state) -> void:
	if not _has_methods(state, [&"record_rumor_scene", &"has_evidence"]):
		return
	state.record_drug_scene()
	state.record_rumor_scene()
	_expect(not state.has_evidence("medical_boundary"), "C11 被错误视为主动追问许济川")
	_expect(not state.has_knowledge("1917_truth"), "1917 被系统认证为查明事实")
	_expect(not state.has_knowledge("drug_contents"), "药盒内容被系统认证")
	_expect(not state.has_knowledge("cause_of_death"), "死因被系统认证")


func _test_c14_only_records_actual_police_disclosure(state) -> void:
	if not _has_methods(state, [&"choose_letter_form", &"decide_interview_letter", &"record_police_scope", &"decide_police_letter"]):
		return
	state.choose_letter_form("original")
	_expect(state.decide_interview_letter("keep"), "C04 无法收回留底原件")
	_expect(state.letter_control == "reporter", "收回留底后控制人错误")
	_expect(state.record_police_scope("old_report"), "C14 无法只说明二十年前旧报")
	_expect(state.police_scope == "old_report", "警方谈话范围没有保存实际选择")
	_expect(not state.decide_police_letter("submit"), "没向警方提采访函却能交出原件")
	_expect(state.letter_control == "reporter", "警方凭空取得未公开的留底原件")


func _test_c14_records_actual_arrival_and_first_look(state) -> void:
	if not _has_methods(state, [&"choose_route", &"observe_first_look", &"record_police_statement"]):
		return
	state.choose_route("留在侧厅")
	state.observe_first_look("周围的人")
	_expect(state.record_police_statement(), "C14 无法保存实际口供")
	_expect(state.police_arrival_recorded == "留在侧厅", "警方口供没有保存实际到场批次")
	_expect(state.police_first_look_recorded == "周围的人", "警方口供没有保存实际第一眼")


func _test_c16_followups_are_evidence_gated(state) -> void:
	if not _has_methods(state, [&"available_followups", &"choose_followup", &"record_rumor_scene"]):
		return
	state.record_drug_scene()
	state.record_rumor_scene()
	var base_followups: Array = state.available_followups()
	_expect(base_followups.has("yutang"), "亲见药盒经过后没有玉棠追问")
	_expect(base_followups.has("xu_general"), "听见死因传言边界后没有许济川追问")
	_expect(base_followups.has("fang"), "C02 亲闻方仲山要查绳后没有方仲山追问")
	_expect(not base_followups.has("chen"), "没有陈九生直接观察却开放追问")
	_expect(state.choose_followup("xu_general"), "无法主动追问许济川")
	_expect(state.has_evidence("medical_boundary"), "C16 追问许济川后没有取得死因边界")

	var fang_state = state.get_script().new()
	fang_state.choose_position("前场")
	fang_state.observe_hotspot("中段", "方仲山账桌")
	_expect(fang_state.has_evidence("fang_left"), "C06 亲见离桌没有保存依据")
	_expect(not fang_state._claim_is_supported("fang_absent"), "只看见离桌、未追问就支持方仲山稿句")
	_expect(fang_state.choose_followup("fang"), "有 C02 基线时无法追问方仲山")
	_expect(fang_state._claim_is_supported("fang_absent"), "亲见离桌并在 C16 追问后仍不支持方仲山稿句")


func _test_prepolice_action_does_not_silently_grant_evidence(state_script: Script) -> void:
	var cases: Array[Dictionary] = [
		{"action": "守药盒", "evidence": "drug_request"},
		{"action": "复走路线", "evidence": "route_check"},
		{"action": "上天桥", "evidence": "rope_change"},
	]
	for test_case: Dictionary in cases:
		var state = state_script.new()
		if not _has_methods(state, [&"choose_prepolice_action", &"record_prepolice_observation"]):
			continue
		var action := str(test_case.action)
		var evidence_id := str(test_case.evidence)
		_expect(state.choose_prepolice_action(action), "无法选择警方前行动：%s" % action)
		_expect(not state.has_evidence(evidence_id), "只选择%s就静默获得精确 evidence" % action)
		_expect(state.record_prepolice_observation(), "显示%s实际观察时未记录 evidence" % action)
		_expect(state.has_evidence(evidence_id), "显示%s实际观察后仍无 evidence" % action)
		_expect(not state.record_prepolice_observation(), "%s 的实际观察可重复记录" % action)


func _test_rope_claim_requires_rope_observation(state) -> void:
	if not _has_methods(state, [&"available_claims", &"record_rumor_scene", &"record_prepolice_observation"]):
		return
	state.record_drug_scene()
	state.record_rumor_scene()
	state.evidence["scenery_height"] = true
	_expect(not state.available_claims().has("rope"), "只看见景片高低就错误开放吊绳稿句")
	state.choose_prepolice_action("上天桥")
	_expect(not state.available_claims().has("rope"), "只选择上天桥、还没看见吊绳就开放稿句")
	state.record_prepolice_observation()
	_expect(state.available_claims().has("rope"), "亲见吊绳异常后没有开放对应完整稿句")


func _test_selecting_a_claim_does_not_submit(state) -> void:
	if not _has_methods(state, [&"available_claims", &"select_claim", &"submit_report", &"record_rumor_scene"]):
		return
	state.record_drug_scene()
	state.record_rumor_scene()
	_expect(state.select_claim("confirmed_only"), "完整稿句无法选中")
	_expect(state.selected_claim == "confirmed_only", "选中的完整稿句没有保存")
	_expect(not state.report_submitted, "选中稿句后自动交稿")
	_expect(state.final_consequence().is_empty(), "未交稿就生成报道后果")
	_expect(state.select_claim("drug_action"), "交稿前无法更换稿句")
	_expect(state.selected_claim == "drug_action", "交稿前更换的稿句没有保存")


func _test_claim_can_only_be_changed_once(state) -> void:
	state.record_drug_scene()
	state.record_rumor_scene()
	_expect(state.select_claim("confirmed_only"), "第一次选稿失败")
	_expect(state.select_claim("drug_action"), "允许的一次换稿失败")
	_expect(not state.select_claim("confirmed_only"), "换稿一次后仍能无限更换")
	_expect(state.selected_claim == "drug_action", "第二次换稿失败后破坏当前稿句")


func _test_submit_returns_one_primary_consequence(state) -> void:
	if not _has_methods(state, [&"select_claim", &"submit_report", &"record_rumor_scene"]):
		return
	state.record_drug_scene()
	state.record_rumor_scene()
	_expect(state.select_claim("drug_action"), "药盒完整稿句无法选中")
	_expect(state.submit_report(), "点击交稿后没有提交")
	_expect(state.report_submitted, "交稿状态没有保存")
	var consequence = state.final_consequence()
	_expect(consequence is String, "主要后果不是单一文本")
	_expect(not str(consequence).is_empty(), "交稿后没有主要后果")
	_expect(not state.select_claim("confirmed_only"), "交稿后仍能换稿句")


func _test_checking_ledger_finishes_the_run(state) -> void:
	if not _has_methods(state, [&"select_claim", &"submit_report", &"reveal_consequence", &"check_ledger", &"record_rumor_scene"]):
		return
	state.record_drug_scene()
	state.record_rumor_scene()
	state.select_claim("confirmed_only")
	state.submit_report()
	_expect(not state.run_finished, "查收发簿前已经结束")
	_expect(not state.check_ledger(), "主要后果尚未显示就能查收发簿")
	_expect(state.reveal_consequence(), "无法标记实际主要后果已显示")
	_expect(state.check_ledger(), "查收发簿无法结束本章")
	_expect(state.run_finished, "查收发簿后没有标记结束")


func _test_old_two_stage_writing_api_is_removed(state) -> void:
	_expect(not state.has_method(&"available_inference_choices"), "旧 judgment API 仍然存在")
	_expect(not state.has_method(&"choose_inference"), "旧 judgment 提交 API 仍然存在")
	_expect(not state.has_method(&"available_publication_choices"), "旧 publication API 仍然存在")
	_expect(not state.has_method(&"choose_publication"), "旧 publication 提交 API 仍然存在")
	var state_source := FileAccess.get_file_as_string("res://interaction_state.gd")
	var lab_source := FileAccess.get_file_as_string("res://interaction_lab.gd")
	_expect(state_source.contains("has_evidence(\"fang_left\") and has_evidence(\"fang_questioned\")"), "方仲山稿句没有同时要求亲见离桌与 C16 追问")
	_expect(not lab_source.contains("\"fang_absent\": \"演出期间"), "UI 仍保留不可达的 fang_absent 稿句")


func _has_methods(state, methods: Array[StringName]) -> bool:
	var all_present := true
	for method_name: StringName in methods:
		if not state.has_method(method_name):
			_expect(false, "缺少预期 API：%s" % method_name)
			all_present = false
	return all_present


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _finish() -> void:
	if failures == 0:
		print("PASS: interaction state")
		quit(0)
	else:
		push_error("FAIL: %d interaction-state assertions" % failures)
		quit(1)
