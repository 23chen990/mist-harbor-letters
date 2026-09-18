# AI-TASK-20260908-OPENING

> 执行记录，不是额外剧情事实源。正式依据为 DEC-20260908-34 与同步后的 v6。

- 档位：formal；状态：CLOSED。
- 用户确认：在收到“大幅压缩编辑戏；桌面调查形成问题；尽快拿材料与林怀安交锋；主控回答由玩家点击，单一回应不强造多选”的方案后，于 2026-09-08 回复“好的，你改吧”。前几版被否决的三节点、性格姿态和主动挑春和方案不在授权内。
- 目标：缩短开场到主动采访的距离，使每次主控发言由玩家点击，材料透露有当场回应。
- 内容范围：S00 压缩、S01 四项必查和寻回函保留、S02 取消自动推断收束而直达函件准备、C04 原件路径的材料透露取舍。其他第一章场次只改变既有主控发言的交互承载。
- 禁止：新增世界真相、把赵之死认定谋杀、认证林是否回信、增加性格/道德分、改变命案因果、改写未授权的后续机制；禁止手改生成 CSV。
- 权威顺序：CURRENT_TRUTH → 人物与前史 v6 → 剧情树 v6 → DECISIONS，均已读取相关范围。
- 研究复用：KNOWLEDGE_INDEX、COMPETITOR_INDEX、DESIGN_PATTERNS（对白行动、玩家自己连接）、COMMERCIAL_STRATEGY（主要点继续的风险），仅作评估维度；不发布新的市场结论。

## 修改范围与 owner

| owner | 文件 / 责任 |
| --- | --- |
| 主调度 | DECISIONS、CURRENT_TRUTH、人物与前史 v6、剧情树 v6、README、剧情表使用说明、本任务记录；唯一作者工作簿及其已确认镜像；test_opening_revision.py；实机画面验证 |
| player_response_runner | scripts/main.gd；test_player_response_ui、test_manual_line_advance、test_narration_speaker_ui、test_rejected_manuscript_ui、test_shen_yanzhou_portrait |
| opening_continuity | narrative / continuity / dialogue 独立只读审校，无写入权 |
| opening_playtest | playtest / commercial_reviewer 独立只读评估，无写入权 |
| opening_flow_tests | tests/ 的内容与完整流程回归、story_test_helpers.gd、test_interview_disclosure.gd；排除上方两个 owner 的测试文件 |
| opening_playtest（独立 QA） | 实现结束后验证按钮、分支、回退、知识与完整流程，无修复写入权 |

## 影响与验证

- 取代范围必须记录在 DEC34：DEC15/29 的固定开场对白，DEC30 的自动收束，以及 DEC28/31 的主控也点继续；保留稿件 UI、逐句主动阅读、四项必查、DEC26 与 DEC33。
- 原件两种透露路径只改变当场披露、林的应对和续约措辞，不认证回函或旧案；原件是否交出仍独立决定。
- 测试先 RED 后 GREEN：主控按钮及未点击/重复点击/回退/首末拍边界；数据无重复 ID、无悬空路由；四查直达准备；C04 两种披露与三种携带路线；C01—C22 主流程。
- 运行命令：`/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/<测试名>.gd`；`python3 tests/test_opening_revision.py`；`python3 tools/validate_workflow_metadata.py --root .`。
- 同步命令：同一 Godot 二进制执行 `res://tools/同步剧情工作簿.gd`。
- 回滚快照：`/private/tmp/fog_opening_20260908_base`，包含文件 SHA-256 清单；不使用 git restore（现有仓库内容均未跟踪）。
- 允许测试生成 Godot 缓存与隔离临时存档；不改用户手工存档。新增数据应保留工作簿原有样式、归档页与入口路径。
- 已知未决：C08 新镜布、台下景片高度、时间代价、新赵案证据链继续待确认；不在本轮补齐。

## 交付记录

已完成本轮授权改动与独立验证。唯一全量失败为既有立绘资源问题，不影响本轮对白、选项与完整流程验收；未放宽该失败测试。

### 审校结论

- narrative / continuity：开场五句、撤销自动推断、C04 两种透露均在 DEC34 范围内；C14 侧台与第一眼回答只复述 C07/C09 实际观察，三种载体闭环成立，没有新增未解决的作者层冲突。
- dialogue：采纳“稿子拿回来再看”的指代澄清；笔录保留“颈侧停了一瞬”，删去把持续注视缩成“一眼”的措辞。C08/C11 仅把复杂动作与说话人分行，台词原文及匿名身份不变。
- playtest：五句具有派活、追问、死亡地点、取材料、去处与截稿约束的因果顺序；材料透露后的 NPC 当场回应能区分两条路径。
- commercial_reviewer：文本结构可更早展示用材料问话和控制透露范围；吸引力与继续游玩意愿仍待实际玩家反馈，不把自动测试视为商业验证。

### 验收中发现并修复的问题

- 8 行有直接引语的 NPC 台词仍标成“是否说出口=否”，导致正式开场缺少回答按钮；通过作者工作簿纠正，并增加内容回归。未把内心或材料标成发言。
- C14 从林身上取得原件时，入场效果把持有人改为警方，导致原条件行把自身隐藏而卡住。运行器保存本次入场命中的呈现行，并在回退时一起恢复；保留按表格顺序计算路由的行为，不修改剧情条件。
- 旧说话人解析把“林玉棠转向沈砚舟”的受话者识别成发言人，错误提供 NPC 句子的玩家按钮。已改为按明确台词标签及动作分句识别说话人，C03/C10 多姓名引导、C08 呼喊、C11 匿名议论均已回归通过。
- 工作簿导出后的 OOXML 保留脚本首次因复用 ZipInfo 对象报 Overlapped entries，在复制回作者入口前已中止；改为复制 ZipInfo 后完成。原入口未被损坏，未改动包条目逐字节验证一致。

### 已知范围外问题

- 沈砚舟独立 PNG 立绘资源缺失，运行器仍绘制既有占位框；相关测试在改前与改后均有 3 个失败断言。本次未制作美术，也未放宽断言来制造全绿。
- `content/秘密释放与AI资源审查.md` 是仍含旧人物关系与旧问题池的过期参考材料，本轮未据其恢复剧情。C08 新蒙镜布、台下景片高度、时间代价与新赵案证据链继续待确认。

### 最终验证

- 独立 QA：25 项 Godot 测试 + 3 项 Python 测试，27 / 28 项通过；仅既有立绘用例失败（3 条断言）。未发现 exit 0 中隐藏的 FAIL / ERROR，也无 WARNING。
- `python3 tools/validate_workflow_metadata.py --root .`：exit 0，10 个知识资产的工作流文件、路径与知识边界检查通过。
- 完整流程实际点击 17 句主控发言，经过 S00 与 C01—C22；林玉棠的“你也别过来”只作为 NPC 台词展示，不点击、不进入玩家历史。此前测试把它算入第 18 句的错误预期已纠正。
- C04 两种透露 × 原件交林/收回，另抄录、纯口述共 6 条携带/透露路线；C14 的 12 种观察组合、无观察不补话的负例均通过。
- QA 运行时生产代码、CSV 与工作簿哈希未变；说话人测试在批次中补完最后断言后，独立 QA 已对磁盘最终版单独重跑通过，前后哈希一致。
- 真实 Godot 窗口从开场点击到 C04 与 C10，8 张画面验证通过（0 个失败）；未用内部跳转替代该次操作。
- 工作簿 107 行、32 张工作表，入口与镜像字节一致。仅剧情页、4 张说明/元数据页及剧情表范围共 6 个 OOXML 包条目改变；其他条目逐字节保留。SHA-256：`db0613bebf607d4a813fd679d594426a7b235e65b3b06fe4d25e5f0e3b7fa059`。

标准 Godot 命令为 `/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/<文件名>.gd`；Python 使用 `python3 -B tests/<文件名>.py`。逐项命令、结果和日志保存在 [QA 报告](/Users/kker/Documents/ChatGPT/解密/outputs/试玩验证/2026-09-08/qa/QA_REPORT.md)、[命令清单](/Users/kker/Documents/ChatGPT/解密/outputs/试玩验证/2026-09-08/qa/commands.txt) 和 [结果 JSON](/Users/kker/Documents/ChatGPT/解密/outputs/试玩验证/2026-09-08/qa/results.json)。

另生成 `outputs/试玩验证/2026-09-08/` 下的 8 张实机图、真实按钮操作记录与 QA 日志；这些是验证证据，不是剧情事实源。Godot 导入缓存由引擎生成，不计作手工剧情改动。

### 修改文件

- [README.md](/Users/kker/Documents/ChatGPT/解密/README.md)
- [content/剧情表使用说明.md](/Users/kker/Documents/ChatGPT/解密/content/剧情表使用说明.md)
- [content/程序生成_请勿手改/剧情剧本.csv](/Users/kker/Documents/ChatGPT/解密/content/程序生成_请勿手改/剧情剧本.csv)
- [docs/AI_TASK_20260908_OPENING.md](/Users/kker/Documents/ChatGPT/解密/docs/AI_TASK_20260908_OPENING.md)
- [docs/CURRENT_TRUTH.md](/Users/kker/Documents/ChatGPT/解密/docs/CURRENT_TRUTH.md)
- [docs/DECISIONS.md](/Users/kker/Documents/ChatGPT/解密/docs/DECISIONS.md)
- [docs/剧情修订稿_v6_人物与前史.md](/Users/kker/Documents/ChatGPT/解密/docs/剧情修订稿_v6_人物与前史.md)
- [docs/雾港来信_序章与第一章完整剧情信息树_v6.md](/Users/kker/Documents/ChatGPT/解密/docs/雾港来信_序章与第一章完整剧情信息树_v6.md)
- [outputs/01a037d8-c4f0-70d3-bc69-8c3819094801/雾港来信_剧情作者工作簿.xlsx](/Users/kker/Documents/ChatGPT/解密/outputs/01a037d8-c4f0-70d3-bc69-8c3819094801/雾港来信_剧情作者工作簿.xlsx)
- [outputs/雾港来信_剧情作者工作簿_v4.1.xlsx](/Users/kker/Documents/ChatGPT/解密/outputs/雾港来信_剧情作者工作簿_v4.1.xlsx)
- [scripts/main.gd](/Users/kker/Documents/ChatGPT/解密/scripts/main.gd)
- [tests/story_test_helpers.gd](/Users/kker/Documents/ChatGPT/解密/tests/story_test_helpers.gd)
- [tests/test_choice_backtracking.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_choice_backtracking.gd)
- [tests/test_continuous_yutang_scene.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_continuous_yutang_scene.gd)
- [tests/test_full_flow.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_full_flow.gd)
- [tests/test_inner_monologue_layout.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_inner_monologue_layout.gd)
- [tests/test_interview_disclosure.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_interview_disclosure.gd)
- [tests/test_manual_line_advance.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_manual_line_advance.gd)
- [tests/test_narration_speaker_ui.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_narration_speaker_ui.gd)
- [tests/test_opening_demo_logic.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_opening_demo_logic.gd)
- [tests/test_opening_revision.py](/Users/kker/Documents/ChatGPT/解密/tests/test_opening_revision.py)
- [tests/test_player_response_ui.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_player_response_ui.gd)
- [tests/test_prelude_free_exploration.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_prelude_free_exploration.gd)
- [tests/test_prelude_transition_timing.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_prelude_transition_timing.gd)
- [tests/test_rejected_manuscript_ui.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_rejected_manuscript_ui.gd)
- [tests/test_s00_opening.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_s00_opening.gd)
- [tests/test_secret_release_content.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_secret_release_content.gd)
- [tests/test_shen_yanzhou_portrait.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_shen_yanzhou_portrait.gd)
- [tests/test_story_content.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_story_content.gd)
- [tests/test_v343_story_content.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_v343_story_content.gd)
- [tests/test_v6_workbook_migration.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_v6_workbook_migration.gd)
- [tests/test_workbook_sync.gd](/Users/kker/Documents/ChatGPT/解密/tests/test_workbook_sync.gd)
