class_name InteractionPrototypeState
extends RefCounted

const POSITION_HOTSPOTS := {
	"观众席侧边": {
		"中段": ["台上的林怀安", "通道旁的许济川"],
		"谢幕": ["林怀安谢幕", "前场出口"],
	},
	"前场": {
		"中段": ["方仲山账桌", "景片下沿"],
		"谢幕": ["空账桌", "舞台出口"],
	},
	"台侧外围": {
		"中段": ["陈九生与阿成", "景片下沿"],
		"谢幕": ["林怀安路线", "铁梯方向"],
	},
	"乐池外围": {
		"中段": ["通道旁的许济川", "侧台帘口"],
		"谢幕": ["陈九生站位", "台上谢幕"],
	},
}

const EVIDENCE_BY_HOTSPOT := {
	"台上的林怀安": "chest_pause",
	"通道旁的许济川": "treatment_instruction",
	"方仲山账桌": "fang_left",
	"景片下沿": "scenery_height",
	"陈九生与阿成": "chen_asked_yutang",
	"侧台帘口": "chen_asked_yutang",
	"林怀安谢幕": "lin_stable",
	"台上谢幕": "lin_stable",
	"前场出口": "fang_absent",
	"空账桌": "fang_absent",
	"舞台出口": "lin_route",
	"林怀安路线": "lin_route",
	"铁梯方向": "ladder_shadow",
	"陈九生站位": "chen_absent",
}

const FIRST_LOOKS := {
	"跟过去": ["许济川的手", "近旁地面"],
	"留在侧厅": ["倒下的位置", "周围的人"],
}

const EVIDENCE_BY_FIRST_LOOK := {
	"许济川的手": "neck_pause",
	"近旁地面": "found_position",
	"倒下的位置": "found_position",
	"周围的人": "crowd_arrival",
}

const DYNAMIC_CLAIM_ORDER := [
	"route_pair",
	"route_check",
	"appointment_pair",
	"neck_pause",
	"rope",
	"fang_absent",
	"drug_request",
	"drug_action",
	"chen_absent",
	"chen_return",
	"chen_asked_yutang",
	"medical_boundary",
]

const REQUIRED_DESK_MATERIALS := ["performance_plan", "old_report", "interview_letter", "death_report"]

var assignment_started := false
var knowledge: Dictionary = {}
var spoken_probe := ""
var letter_form := ""
var letter_control := ""
var police_scope := ""
var police_arrival_recorded := ""
var police_first_look_recorded := ""
var followup := ""
var appointment_set := false
var position := ""
var observed_beats: Dictionary = {}
var route := ""
var first_look := ""
var waiting_observation := ""
var prepolice_action := ""
var prepolice_observed := false
var missed_followup := false
var rope_reported := false
var rope_preserved := false
var evidence: Dictionary = {}
var selected_claim := ""
var claim_changes := 0
var submitted_claim := ""
var report_submitted := false
var consequence_revealed := false
var run_finished := false


func start_assignment() -> bool:
	if assignment_started:
		return false
	assignment_started = true
	return true


func read_desk_material(material_id: String) -> bool:
	if not assignment_started or material_id not in REQUIRED_DESK_MATERIALS + ["old_map"]:
		return false
	if has_knowledge(material_id):
		return false
	knowledge[material_id] = true
	return true


func desk_ready() -> bool:
	for material_id: String in REQUIRED_DESK_MATERIALS:
		if not has_knowledge(material_id):
			return false
	return true


func choose_letter_form(value: String) -> bool:
	if not letter_form.is_empty() or value not in ["original", "copy"]:
		return false
	letter_form = value
	letter_control = "reporter" if value == "original" else "archive"
	return true


func decide_interview_letter(value: String) -> bool:
	if letter_form != "original" or letter_control != "reporter" or value not in ["leave", "keep"]:
		return false
	if value == "leave":
		letter_control = "lin"
	return true


func record_appointment() -> bool:
	if appointment_set:
		return false
	appointment_set = true
	return true


func record_police_scope(value: String) -> bool:
	if not police_scope.is_empty() or value not in ["performance", "old_report", "contact"]:
		return false
	police_scope = value
	return true


func police_finds_letter() -> bool:
	if letter_form != "original" or letter_control != "lin":
		return false
	letter_control = "police"
	police_scope = "contact"
	return true


func decide_police_letter(value: String) -> bool:
	if police_scope != "contact" or letter_form != "original" or letter_control != "reporter" or value not in ["submit", "retain"]:
		return false
	if value == "submit":
		letter_control = "police"
	return true


func record_police_statement() -> bool:
	if route.is_empty() or first_look.is_empty() or not police_arrival_recorded.is_empty():
		return false
	police_arrival_recorded = route
	police_first_look_recorded = first_look
	return true


func has_knowledge(knowledge_id: String) -> bool:
	return bool(knowledge.get(knowledge_id, false))


func available_probe_choices() -> Array:
	if not spoken_probe.is_empty():
		return []
	if not has_knowledge("death_report") or not has_knowledge("interview_letter"):
		return []
	return ["desk_gap", "no_reply", "reply_missing"]


func choose_probe(value: String) -> bool:
	if value not in available_probe_choices():
		return false
	spoken_probe = value
	return true


func choose_position(value: String) -> bool:
	if not position.is_empty() or not POSITION_HOTSPOTS.has(value):
		return false
	position = value
	return true


func available_hotspots(beat: String) -> Array:
	if position.is_empty() or observed_beats.has(beat):
		return []
	return Array(POSITION_HOTSPOTS[position].get(beat, [])).duplicate()


func observe_hotspot(beat: String, hotspot: String) -> bool:
	if hotspot not in available_hotspots(beat):
		return false
	observed_beats[beat] = hotspot
	var evidence_id := str(EVIDENCE_BY_HOTSPOT.get(hotspot, ""))
	if not evidence_id.is_empty():
		evidence[evidence_id] = true
	return true


func choose_route(value: String) -> bool:
	if not route.is_empty() or not FIRST_LOOKS.has(value):
		return false
	route = value
	return true


func available_first_looks() -> Array:
	if route.is_empty() or not first_look.is_empty():
		return []
	return Array(FIRST_LOOKS[route]).duplicate()


func observe_first_look(value: String) -> bool:
	if value not in available_first_looks():
		return false
	first_look = value
	var evidence_id := str(EVIDENCE_BY_FIRST_LOOK.get(value, ""))
	if not evidence_id.is_empty():
		evidence[evidence_id] = true
	return true


func record_waiting_observation(value: String) -> bool:
	if route != "留在侧厅" or not waiting_observation.is_empty() or value not in ["凉茶", "蒙镜布"]:
		return false
	waiting_observation = value
	evidence["cool_tea" if value == "凉茶" else "new_mirror_cloth"] = true
	return true


func record_waiting_scene() -> bool:
	if route != "留在侧厅" or not waiting_observation.is_empty():
		return false
	waiting_observation = "凉茶与蒙镜布"
	evidence["cool_tea"] = true
	evidence["new_mirror_cloth"] = true
	return true


func record_drug_scene() -> void:
	evidence["death_confirmed"] = true
	evidence["drug_action"] = true


func record_rumor_scene() -> void:
	evidence["old_illness_heard"] = true


func record_old_illness_exchange() -> void:
	record_rumor_scene()


func available_followups() -> Array:
	if not followup.is_empty() or prepolice_action == "上天桥":
		return []
	var choices: Array[String] = ["yutang"]
	if has_evidence("neck_pause"):
		choices.append("xu_neck")
	else:
		choices.append("xu_general")
	if has_evidence("chen_absent") or has_evidence("crowd_arrival") or has_evidence("chen_asked_yutang"):
		choices.append("chen")
	choices.append("fang")
	return choices


func choose_followup(value: String) -> bool:
	if value not in available_followups():
		return false
	followup = value
	match value:
		"xu_neck", "xu_general":
			evidence["medical_boundary"] = true
		"fang":
			evidence["fang_questioned"] = true
		"yutang":
			evidence["yutang_answer"] = true
		"chen":
			evidence["chen_answer"] = true
	return true


func choose_prepolice_action(value: String) -> bool:
	if not prepolice_action.is_empty() or value not in ["守药盒", "复走路线", "上天桥"]:
		return false
	prepolice_action = value
	return true


func record_prepolice_observation() -> bool:
	if prepolice_action.is_empty() or prepolice_observed:
		return false
	prepolice_observed = true
	match prepolice_action:
		"守药盒":
			evidence["drug_request"] = true
		"复走路线":
			evidence["route_check"] = true
		"上天桥":
			evidence["rope_change"] = true
			missed_followup = true
	return true


func report_rope_to_police(should_report: bool) -> void:
	rope_reported = should_report and has_evidence("rope_change")
	rope_preserved = rope_reported


func has_evidence(evidence_id: String) -> bool:
	return bool(evidence.get(evidence_id, false))


func available_claims() -> Array:
	if report_submitted or not _has_report_basis():
		return []
	var claims: Array[String] = ["confirmed_only"]
	if has_knowledge("death_report") and has_knowledge("interview_letter"):
		claims.append("contact")
	var dynamic_count := 0
	for claim_id: String in DYNAMIC_CLAIM_ORDER:
		if _claim_is_supported(claim_id):
			claims.append(claim_id)
			dynamic_count += 1
			if dynamic_count >= 3:
				break
	return claims


func select_claim(value: String) -> bool:
	if report_submitted or value not in available_claims():
		return false
	if not selected_claim.is_empty():
		if value == selected_claim or claim_changes >= 1:
			return false
		claim_changes += 1
	selected_claim = value
	return true


func submit_report() -> bool:
	if report_submitted or selected_claim.is_empty() or selected_claim not in available_claims():
		return false
	report_submitted = true
	submitted_claim = selected_claim
	return true


func final_consequence() -> String:
	if not report_submitted:
		return ""
	match submitted_claim:
		"confirmed_only":
			return "报道被排在本埠短讯的一栏，标题只有一行。"
		"contact":
			return "其他报馆赶到春和；方仲山问起赵敬文那一段从何而来。"
		"route_pair", "route_check":
			return "顾承钧带警员重走侧台，并逐字核对沈砚舟写下的位置来源。"
		"neck_pause", "medical_boundary":
			return "许济川只在警员在场时回应，单独采访入口关闭。"
		"rope":
			return "铁梯与绳排仍贴着封条。" if rope_preserved else "次日绳排已经调平，原来的收束位置不复存在。"
		"fang_absent":
			return "方仲山问沈砚舟：你写我离开过。什么时候看见的？"
		"drug_request", "drug_action":
			return "玉棠当面问沈砚舟：你看见我把药盒往袖里收了？"
		"chen_absent", "chen_return", "chen_asked_yutang":
			return "陈九生要求沈砚舟说清看见他的具体时刻，并提前收紧自己的说法。"
	return "报道见报后，春和开始重新核对当晚的说法。"


func check_ledger() -> bool:
	if not report_submitted or not consequence_revealed or run_finished:
		return false
	run_finished = true
	return true


func reveal_consequence() -> bool:
	if not report_submitted or consequence_revealed:
		return false
	consequence_revealed = true
	return true


func _has_report_basis() -> bool:
	return has_evidence("death_confirmed") and has_evidence("old_illness_heard") and has_evidence("drug_action")


func _claim_is_supported(claim_id: String) -> bool:
	match claim_id:
		"route_pair":
			return has_evidence("lin_route") and has_evidence("found_position")
		"route_check":
			return has_evidence("route_check")
		"appointment_pair":
			return appointment_set and has_evidence("found_position") and not has_evidence("lin_route") and not has_evidence("route_check")
		"neck_pause":
			return has_evidence("neck_pause")
		"rope":
			return has_evidence("rope_change")
		"fang_absent":
			return has_evidence("fang_left") and has_evidence("fang_questioned")
		"drug_request":
			return has_evidence("drug_request")
		"drug_action":
			return has_evidence("drug_action")
		"chen_absent":
			return has_evidence("chen_absent")
		"chen_return":
			return has_evidence("crowd_arrival")
		"chen_asked_yutang":
			return has_evidence("chen_asked_yutang")
		"medical_boundary":
			return has_evidence("medical_boundary")
	return false
