# DEC34 独立 QA 结果

执行角色：独立 qa；未担任生产代码、剧情、工作簿或测试的 owner。
环境：Godot 4.7.2.stable.official.ed1daf0bf；工作目录 `/Users/kker/Documents/ChatGPT/解密`。

28 项测试串行执行：27 项通过，1 项失败。另对运行期间变更的说话人测试最终版复跑 1 次，通过。检查 stdout 中的 FAIL、FAILED、SCRIPT ERROR、ERROR；没有 exit 0 却出现失败标记的用例，亦无 WARNING。

## 行为验收

- S00 从首个画面到工作桌为两个主控回答按钮和一次继续；首次是“他死前还在跑春和？”，点击之前没有发言历史，点击后不重复播放。
- 四项材料与主动寻找回信保留；包括采访函作为第四项的路径，关闭结果后直接出现函件准备，没有旧自动推断独白。
- C04 两种披露各覆盖原件留下/收回，共四条；抄录和口述另测。回应、披露状态、原件持有与回退一致。
- C14 覆盖 4 种最后所见 × 3 种第一眼共 12 个组合，未看见时没有伪造回答；两句实际回答后才完成笔录。
- C10 “你也别过来。”由林玉棠说，不被主控按钮或发言历史接管；最终说话人测试还覆盖 C03 陈九生、C10 许济川与 C11 匿名发言人。
- 全流程通过真实可见按钮推进 S00 至 C22；测试要求的 17 句主控发言全部亲自点击。

## 每项执行结果

| 用例 | Exit | 结果/断言摘要 | 完整 stdout 日志 |
|---|---:|---|---|
| `tests/test_player_response_ui.gd` | 0 | PASS — PASS: player response UI | [日志](/private/tmp/fog_opening_qa/test_player_response_ui.gd.log) |
| `tests/test_manual_line_advance.gd` | 0 | PASS — PASS: manual line advance | [日志](/private/tmp/fog_opening_qa/test_manual_line_advance.gd.log) |
| `tests/test_s00_opening.gd` | 0 | PASS — PASS: DEC34 five-line opening and knowledge release | [日志](/private/tmp/fog_opening_qa/test_s00_opening.gd.log) |
| `tests/test_interview_disclosure.gd` | 0 | PASS — PASS: C04 disclosure/custody, three paper routes, and 12 C14 observation combinations via UI | [日志](/private/tmp/fog_opening_qa/test_interview_disclosure.gd.log) |
| `tests/test_prelude_transition_timing.gd` | 0 | PASS — PASS: DEC34 preparation timing, including letter as fourth check | [日志](/private/tmp/fog_opening_qa/test_prelude_transition_timing.gd.log) |
| `tests/test_prelude_free_exploration.gd` | 0 | PASS — PASS: DEC34 four newsroom checks go directly to letter preparation | [日志](/private/tmp/fog_opening_qa/test_prelude_free_exploration.gd.log) |
| `tests/test_reply_search_flow.gd` | 0 | PASS — PASS: letter-to-reply-search flow | [日志](/private/tmp/fog_opening_qa/test_reply_search_flow.gd.log) |
| `tests/test_choice_backtracking.gd` | 0 | PASS — PASS: exploration backtracking preserves earlier spoken history and restart resets all | [日志](/private/tmp/fog_opening_qa/test_choice_backtracking.gd.log) |
| `tests/test_chapter_switching.gd` | 0 | PASS — PASS: chapter switching test button | [日志](/private/tmp/fog_opening_qa/test_chapter_switching.gd.log) |
| `tests/test_continuous_yutang_scene.gd` | 0 | PASS — PASS: v6 continuous scene contract | [日志](/private/tmp/fog_opening_qa/test_continuous_yutang_scene.gd.log) |
| `tests/test_game_state.gd` | 0 | PASS — PASS: natural-language knowledge state | [日志](/private/tmp/fog_opening_qa/test_game_state.gd.log) |
| `tests/test_inner_monologue_layout.gd` | 0 | PASS — PASS: inner monologue lower dialogue layout | [日志](/private/tmp/fog_opening_qa/test_inner_monologue_layout.gd.log) |
| `tests/test_narration_speaker_ui.gd` | 0 | PASS — PASS: narration speaker UI | [日志](/private/tmp/fog_opening_qa/test_narration_speaker_ui.gd.log) |
| `tests/test_opening_demo_logic.gd` | 0 | PASS — PASS: DEC34 opening logic and oral-only interview UI | [日志](/private/tmp/fog_opening_qa/test_opening_demo_logic.gd.log) |
| `tests/test_rejected_manuscript_ui.gd` | 0 | PASS — PASS: rejected manuscript UI | [日志](/private/tmp/fog_opening_qa/test_rejected_manuscript_ui.gd.log) |
| `tests/test_reporter_public_death_conclusion.gd` | 0 | PASS — PASS: reporter public death conclusion is synchronized | [日志](/private/tmp/fog_opening_qa/test_reporter_public_death_conclusion.gd.log) |
| `tests/test_reporter_surname_formalization.gd` | 0 | PASS — PASS: reporter surname formalization is synchronized | [日志](/private/tmp/fog_opening_qa/test_reporter_surname_formalization.gd.log) |
| `tests/test_secret_release_content.gd` | 0 | PASS — PASS: v6 first-chapter secret release | [日志](/private/tmp/fog_opening_qa/test_secret_release_content.gd.log) |
| `tests/test_shen_yanzhou_portrait.gd` | 1 | FAIL — ERROR: 沈砚舟序章实机立绘资源尚未建立；ERROR: 沈砚舟说话时没有使用真实透明立绘；ERROR: 沈砚舟真实立绘已接入后仍显示技术占位文字；ERROR: FAIL: 3 Shen-Yanzhou portrait assertions | [日志](/private/tmp/fog_opening_qa/test_shen_yanzhou_portrait.gd.log) |
| `tests/test_story_content.gd` | 0 | PASS — PASS: v6 active story content | [日志](/private/tmp/fog_opening_qa/test_story_content.gd.log) |
| `tests/test_v27_story_content.gd` | 0 | PASS — PASS: legacy v2/v3 runtime data retired | [日志](/private/tmp/fog_opening_qa/test_v27_story_content.gd.log) |
| `tests/test_v343_story_content.gd` | 0 | PASS — PASS: v6 workbook content replaces v3.4.3 | [日志](/private/tmp/fog_opening_qa/test_v343_story_content.gd.log) |
| `tests/test_v6_workbook_migration.gd` | 0 | PASS — PASS: v6 workbook migration | [日志](/private/tmp/fog_opening_qa/test_v6_workbook_migration.gd.log) |
| `tests/test_workbook_sync.gd` | 0 | PASS — PASS: Excel workbook is the single story authoring source | [日志](/private/tmp/fog_opening_qa/test_workbook_sync.gd.log) |
| `tests/test_opening_revision.py` | 0 | PASS — Ran 6 tests in 0.002s；OK | [日志](/private/tmp/fog_opening_qa/test_opening_revision.py.log) |
| `tests/test_reporter_public_death_conclusion.py` | 0 | PASS — PASS: reporter public death conclusion is synchronized | [日志](/private/tmp/fog_opening_qa/test_reporter_public_death_conclusion.py.log) |
| `tests/test_workflow_metadata.py` | 0 | PASS — Ran 13 tests in 0.709s；OK | [日志](/private/tmp/fog_opening_qa/test_workflow_metadata.py.log) |
| `tests/test_full_flow.gd` | 0 | PASS — PASS: DEC34 real-button S00 and C01-C22 full flow | [日志](/private/tmp/fog_opening_qa/test_full_flow.gd.log) |

## 已知失败（未隐藏、未修改预期）

`tests/test_shen_yanzhou_portrait.gd`，exit 1，3 项断言失败：

1. 沈砚舟序章实机立绘资源尚未建立。
2. 沈砚舟说话时没有使用真实透明立绘。
3. 沈砚舟真实立绘已接入后仍显示技术占位文字。

分类：基线资源缺失/仍为占位实现，与本轮对白按钮和开场改稿无关。目标资源 `art/角色立绘/沈砚舟_序章_平静观察_半身.png` 尚不存在；不得将其报告为全部通过。

## 稳定性复核

全量运行前后，纳入哈希检查的生产代码、剧情文档、生成 CSV 与两份工作簿未变化。唯一发生变化的文件是由其他 owner 更新的 `tests/test_narration_speaker_ui.gd`；已使用最终磁盘版本重新执行。

- 复跑 exit：0。
- 复跑文件运行前后 SHA-256 一致：`3a2ce1730a5ad4bd4c7becdf9b659c7c94e15b3da013b10d7fada32b94bd16a6`。
- [最终说话人测试日志](/private/tmp/fog_opening_qa/test_narration_speaker_ui.final.log)。

## 命令与证据

- [全部实际执行命令](/private/tmp/fog_opening_qa/commands.txt)。
- [结构化逐项结果](/private/tmp/fog_opening_qa/results.json)。
- [复跑记录](/private/tmp/fog_opening_qa/narration_final_rerun.json)。
- [运行期间文件变化清单](/private/tmp/fog_opening_qa/source_changes.json)。

## 未验证项与资料边界

这是 headless UI 与内容/流程回归，没有替代真人对吸引力、节奏和画面观感的试玩。主控回答交互通过不等于市场效果或满意度已验证。
`content/秘密释放与AI资源审查.md` 仍包含旧父子/沈敬文/动态两问等历史口径；本次已以 v6 和 DEC34 建立预期，没有引用它恢复设定，也没有修改该文档。
