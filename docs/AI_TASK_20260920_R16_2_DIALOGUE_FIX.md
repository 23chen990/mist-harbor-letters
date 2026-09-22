# R16.2 逐句对白与选择界面修复

> 执行与验收记录，不是剧情事实源。ZIP 的完整开发工作尚未完成。

- 任务：`TASK-R16.2-20260920-DIALOGUE-FIX`
- 档位：standard；状态：VERIFIED
- 用户要求：台词逐句点击，修复文字挤压、选项显示与条件代码漏出，解决 Godot 项目管理器“缺失项目”。
- 岗位：主 Codex 为 programmer / dialogue 范围审查及文件 owner；`dialogue_qa` 为只读独立 QA / playtest。
- 目标：在当前接入表驱动的运行版本中，逐句显示符合状态的对白；读完才出现选项；选择界面不能重新显示原始摘要或条件代码；实际按钮可继续流程。
- 非目标：重写剧情、改变选择结果、迁移全篇 DOCX 演出、美术替换、移动端、IAA 或发行。
- 审批门：本次修复遵循用户已明确要求的呈现方式与 R16.2 已确认状态规则，无新增正式剧情或核心机制，不需要修改 DECISIONS/CURRENT_TRUTH。
- 回滚基线：`1b4c31c`；保留此前未提交的同任务布局修复。

## 依据与边界

1. `docs/CURRENT_TRUTH.md`：正文、状态权威边界，四个交互与玩家信息限制。
2. `docs/r16_2/source/雾港来信_R16.2_核心玩法与选择兑现版_全篇互动剧本.docx`：抽查 U01/U02、U09、U15-B、U27、U31/U32。
3. `docs/r16_2/source/雾港来信_R16.2_程序接入表.xlsx`：Nodes、Choices、MicroPuzzles、RuntimeContract、StateDictionary。
4. D68 的 CORRECTION/PROTECTED/EXPOSED 明确来自 `yutang_departure_tone` 枚举，依据 Nodes/D68.OnEnter 及该 state 的 UsedBy=U31 dialogue。
5. `docs/DECISIONS.md` 的 R16.2 切换决策。research 三份索引只用于检查思路，不作剧情事实。

主 owner 仅修改下面列出的脚本、测试、启动器和本记录。作者 DOCX/XLSX、编译器与生成 JSON 均只读；无权威冲突。测试允许产生临时 Godot 缓存，结束前清理本轮生成的未跟踪 UID/import 文件。独立 QA 使用独立临时工程，不切换用户窗口。

## 修改文件

- `scripts/r16_2_runtime.gd`：逐句状态、条件过滤；选择只在可选阶段开放；所有交互事件保留最后已显示文本；普通选择显示即时反馈；D68 条件别名；跳过特殊节点制作说明与答案；核稿成功不重播；回退直接恢复选择。
- `scripts/r16_2_main.gd`：修复容器宽度；中文系统字体回退；逐句推进与反馈按钮；避免 raw summary 回退；选项可辨识样式；立即移除旧按钮；排序卡数组类型、按钮累加、提交和重新排列修复；隐藏内部卡片 ID。
- `tests/test_r16_2_dialogue.gd`：分句、等待选择、选择画面不恢复原文、即时反馈、回退、D68 三路线、特殊节点与核稿接续回归。
- `tests/test_r16_2_layout.gd`：正文宽度及开场逐句 UI。
- `tests/test_r16_2_ui.gd`：通过实际按钮 pressed 信号检查 U01→U02、U09 选择和 U15-B 排序提交。
- `tests/test_r16_2_runtime.gd`、`tests/test_r16_2_acceptance.gd`：路线消费新的对白/反馈阶段；四路线检查玩家文本不出现条件/制作标记。
- `试玩雾港来信.command`：从所在目录显式启动 R16.2 主工程，避免进入 legacy 交互试验场。

## Godot 项目管理器

- 工程路径：`/Users/kker/Documents/ChatGPT/解密/project.godot`。
- 已备份用户项目列表到 `/tmp/godot_projects.cfg.before_r162_fix`。
- 关闭本轮已知旧管理器后，以 `Godot --project-manager` 启动新管理器。该项目显示为“雾港来信 R16.2”，版本 4.7，编辑和运行可用，“移除缺失项目”禁用。
- 无需修改或删除用户项目列表。此前 `--editor-pid 0` 会在当前项目目录启动游戏，不能用它代替 `--project-manager`。

## 验证

Godot 可执行文件：`/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot`（4.7.2）。下列命令均在仓库根目录执行。

```sh
/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_r16_2_dialogue.gd
/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_r16_2_layout.gd
/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_r16_2_ui.gd
/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_r16_2_runtime.gd
/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_r16_2_acceptance.gd
python3 tools/r16_2_compile.py --check
python3 tools/r16_2_validate.py
python3 -m unittest discover -s tests -p 'test_r16_2_compiler.py' -v
python3 tools/validate_workflow_metadata.py --root .
zsh -n 试玩雾港来信.command
git diff --check
```

- 上列命令全部通过：五项 Godot 检查、编译一致性、静态数据校验、8 个 Python 编译器测试、工作流元数据、启动器语法和 diff 空白检查。
- 独立 QA 在临时工程中通过 322 项断言：逐句/条件 242、实际按钮 UI 24、后期反馈 40、回退 16。字体调整后另对 UI/layout 定向复验通过。QA 没有操作桌面，界面截图由主 Codex 用实际 Godot 渲染另行检查。
- 本轮先复现了真实实现缺陷：选择事件恢复整段摘要、条件代码漏出、排序卡 PackedStringArray 赋给 Array[String] 时报错，以及按钮累加。测试失败后修复。
- 原路线测试的 160/180 步上限未计入新对白点击，调整到 400；结局、状态与发布生命周期断言保留，不以删断言掩盖失败。
- 未运行的 legacy v6 测试不作 R16.2 验收依据。

## 未完成与实际限制

- ZIP 并非全部完成。此前交付的是第一阶段编译器、状态/路线骨架与占位界面。迁移包四个 authority source 文件已核对与仓库相同，但文件纳入仓库不等于所有制作规格已实现。
- 当前 `PlayerTextSummary` 只是摘要，不能称为完整 DOCX 台词。例如 DOCX U02 有 7 段，接入表摘要只有 3 段。本次逐句显示的是现有摘要中的对白单元；完整正文、选择情境提示与后续演出仍需正式接入。
- U31/U32 的四项 ImmediateFeedback 是带 if/else 或路线标签的制作指令，本次保留原来的直接续接，禁止把指令当对白。它们的完整作者演出仍未接入。U28 的后台组稿直接进入预览。
- D15-B 目前是点击按顺序选卡的占位交互；完整拖动演出、只退回冲突相邻卡和对应采访回看仍待实现。程序不会预先显示完整答案或内部卡 ID。
- 冷开场、完整美术/音效、整版报纸表现、移动端、IAA、发行未通过本次验收，也不宣称完成。

## 交付证据

- Godot 实际渲染截图（不是界面设计图）：
  - [U01 第一句](/Users/kker/.codex/visualizations/2026/09/20/01a0bdd0-2414-74c1-bcea-a71e4de531d2/r162-fix/u01-first-line.png)
  - [U01 读完后的选择](/Users/kker/.codex/visualizations/2026/09/20/01a0bdd0-2414-74c1-bcea-a71e4de531d2/r162-fix/u01-choices.png)
  - [U09 条件过滤后的选择](/Users/kker/.codex/visualizations/2026/09/20/01a0bdd0-2414-74c1-bcea-a71e4de531d2/r162-fix/u09-choices.png)
  - [恢复正常的 Godot 项目管理器](/Users/kker/.codex/visualizations/2026/09/20/01a0bdd0-2414-74c1-bcea-a71e4de531d2/r162-fix/godot-project-manager.png)
- 独立 QA 脚本和日志：`/var/folders/f2/s76hhpss3llc2_zw9g63x7380000gn/T/r162_independent_qa_3pl9z78x/`，包含 `qa_dialogue.gd`、`qa_ui.gd`、`qa_feedback.gd`、`qa_rollback.gd` 与各自 `_final.log`。
- 独立验收复现示例：`/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path /var/folders/f2/s76hhpss3llc2_zw9g63x7380000gn/T/r162_independent_qa_3pl9z78x --script res://qa_dialogue.gd`。
- 无本次修复的未解决权威冲突；上述未接入内容继续列为实际限制。
- 新启动器已实际启动独立试玩进程，日志为 `/tmp/r162_latest_playtest.log`，加载的是仓库根目录的 R16.2 工程。
