extends SceneTree

const Driver = preload("res://tests/story_test_helpers.gd")
const GameStateScript = preload("res://scripts/game_state.gd")
const PUBLIC_DEATH_REPORT := "赵敬文死在春和后巷石埠附近，警方认定为失足落水身亡"
const OPENING_MATERIALS_AND_SLOT_REPLY := "材料给我看看。这趟跑完，明天还让我接着跑吗？"
const OPENING_EDITOR_DEADLINE := "在他桌上。十一点半截稿。明天的事，等稿子回来再说。"
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var driver := Driver.new(main, self, _expect)
	_expect(main.state.current_stage == "前序·退稿与派活", "Demo 没有从退稿与派活开场")
	_expect(GameStateScript.KNOWLEDGE_CATALOG.has(PUBLIC_DEATH_REPORT), "知识目录缺少有来源的公开死亡结论")
	_expect(driver.labels().contains("春和今晚的采访，你去。赵老死后，这条线一直没人接。"), "S00 没有以简短派活开场")
	_expect(driver.button("继续") == null, "编辑交代完采访后仍用继续替主控发言")
	_expect(not main.state.knows(PUBLIC_DEATH_REPORT), "未读死亡报道就提前知道警方结论")
	_expect(main.state.choice_history.is_empty(), "开场未点击就记录了主控回答")
	await create_timer(0.15).timeout
	_expect(main.state.current_stage == "前序·退稿与派活", "开场静置时自动推进")

	if await driver.press_response("他死前还在跑春和？"):
		_expect(main.state.current_stage == "前序·春和旧线", "第一句回答没有进入春和旧线")
		_expect(driver.labels().contains("跑了二十年。人也是在那儿没的。"), "玩家追问后没有得到死亡地点钩子")
		_expect(not driver.labels().contains("他死前还在跑春和？"), "已点击的回答又占一个继续拍")
		if await driver.press_response(OPENING_MATERIALS_AND_SLOT_REPLY):
			_expect(main.state.current_stage == "前序·领取材料", "第二句回答没有进入领取材料")
			_expect(driver.labels().contains(OPENING_EDITOR_DEADLINE), "S00 没有保留材料去处、截稿时间与未承诺下一篇稿位")
			_expect(driver.response_buttons().is_empty(), "领取材料又强造无意义的主控回应")
			await driver.press("继续")
			_expect(main.state.current_stage == "前序·自由探索", "五句开场后没有进入工作桌")
			_expect(main.state.choice_history.size() == 2, "五句开场应且仅记录两句主控发言")
			_expect(not main.state.knows(PUBLIC_DEATH_REPORT), "开场完成就提前获得警方结论")
			await driver.press("赵敬文死亡报道 / 旧戏院草图")
			_expect(main.state.knows(PUBLIC_DEATH_REPORT), "读死亡报道后没有取得有来源的警方结论")
	for removed: String in ["再给我半个钟头", "留几栏", "六号码头这篇，还等改稿吗"]:
		_expect(not "\n".join(driver.seen_text).contains(removed), "S00 仍显示已撤销往复：%s" % removed)
	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: DEC34 five-line opening and knowledge release")
		quit(0)
	else:
		push_error("FAIL: %d S00 assertions" % failures)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
