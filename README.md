# 《雾港来信》—— 正式工程 GitHub 基线

> **2026-09-22 正典回切**：R16.2 已按 `DEC-20260922-CANON-REVERT-V6` 撤销，当前正典恢复为 v6（林怀安遇害 + 玉棠用药嫌疑 + 白素秋二十年旧案 + 老记者调查中死亡）。R16.2 的剧情事实全部作废，整套资料归档在 `docs/r16_2/`，只作历史追溯与机制取材；保留资产清单见 `docs/CURRENT_TRUTH.md`。本文件以下内容为 v6 口径。
>
> 同日 `DEC-20260922-BRANCHING-UNFREEZE` 解除了全局分叉禁令，结构改为「菱形 + 场次池」。该决策只确立结构与边界，尚未落到数据与代码。

> 本仓库是《雾港来信》的**唯一工程基线**，后续开发以此为准。
> 内容取自本地正式工程的**当前磁盘状态**，**原样保存**：未改任何剧情、台词、设定、人物与机制；
> 旧版本（v5 修订稿、v4.1 工作簿备份等）**全部保留**，仅作历史追溯，不得从中恢复剧情口径（见 `AGENTS.md` 第 6 节）。

| 基线信息 | 值 |
| --- | --- |
| 基线 tag | `baseline-20260919` |
| 默认分支 | `main` |
| GitHub 仓库 | `https://github.com/23chen990/mist-harbor-letters` |
| 引擎 / 语言 | Godot 4.x、GDScript、2D Control UI |
| 唯一剧情编辑入口 | `outputs/01a037d8-c4f0-70d3-bc69-8c3819094801/雾港来信_剧情作者工作簿.xlsx` |
| 工作规范入口 | `AGENTS.md` |
| 仓库体积 | 约 357MB（含美术概念稿），首次 clone 较慢 |

### 权威文档读取顺序（改动剧情前必读）

1. `docs/CURRENT_TRUTH.md`
2. `docs/剧情修订稿_v6_人物与前史.md`
3. `docs/雾港来信_序章与第一章完整剧情信息树_v6.md`
4. `docs/DECISIONS.md`

工作簿、CSV 与代码只说明当前实现状态，**不能**自动推翻作者层设定。冲突时按上述顺序，两边都要改则报告冲突并等确认（见 `AGENTS.md` 第 1、4 节）。

### 刻意排除项（均可重建，不在基线内）

| 排除项 | 原因 |
| --- | --- |
| `.godot/` | Godot 导入缓存，打开项目即自动重建（约 219MB） |
| `.codex_spreadsheet_work/` | 表格处理临时工作区，全是 PNG 预览（约 414MB） |
| `.agents/` | 编辑器 / 代理运行时目录 |
| `.DS_Store`、`*.log`、`*.tmp` | OS 与临时文件 |
| `content/程序生成_请勿手改/*.上次同步.bak` | 同步器备份，可重新生成 |

---

# 《雾港来信》最小互动推理 MVP

使用 Godot 4.x、GDScript 和 2D Control UI 制作的点击式人物询问 Demo。

当前运行版是 v6 垂直切片：序章使用场景探索 UI 整理赵敬文工作桌，第一章按 C01—C22 推进到次日见报与《夜渡》章末。旧第二、三章运行数据已经停用，未迁移内容不会出现在 Demo 入口。

## 运行

1. 在 Godot 4.x 项目管理器中导入本目录的 project.godot。
2. 点击右上角“运行项目”按钮或按 F5。

## 剧情作者入口

- 唯一编辑入口：`outputs/01a037d8-c4f0-70d3-bc69-8c3819094801/雾港来信_剧情作者工作簿.xlsx`。
- 最简单的打开方式：双击项目根目录的 `打开剧情工作簿.command`。
- 修改“剧情剧本”页并保存后，双击 `同步剧情工作簿.command`，再运行游戏。
- `content/程序生成_请勿手改/剧情剧本.csv` 是游戏缓存，不要手动修改。
- 使用说明：`content/剧情表使用说明.md`。
- 新增行时“自动ID”可以留空；现有 ID 不要修改，改台词不会改变 ID。
- GDScript 只负责加载、条件解释、知识状态和界面，不再硬编码具体对白。

## 操作

- 鼠标：选择沈砚舟真正要说出口的话。
- 画面底部“测试：切换章节”：打开当前切片入口；目前只提供第一章，切换时会清空当前试玩进度。
- F10：打开或关闭剧情作者 Debug。
- Debug 用中文显示玩家知识、亲自问过的话题、可用话题、潜在矛盾、实际点击历史，并支持六个快速跳转。

## 核心交互

后台 Topic/Stage 继续负责条件与作者 Debug，但正式玩家看到的是连续戏剧场景。NPC 台词每次只显示当前一句；轮到沈砚舟说话时，右侧按钮显示他的实际回应，点击后才说出并接到对方下一句。单一必要回应同样需要亲自点击，只有真正的取舍才提供多选。“继续”只用于主动阅读 NPC 台词与必要演出，静置不会推进。场景动作、纯画面、写稿与报纸结果均由背景 UI 表现，不显示“场景”说话者、动作原文或技术占位。信件、报纸与工作夹等整页材料保持页面阅读。

报馆开场压为五句，通过退稿画面、编辑派活与赵老死在春和的消息进入调查；其中两句主控回应由玩家点选。序章的“春和”工作夹、二十年前旧报、采访函留底、赵敬文死亡报道与旧戏院草图组成四项工作桌检查，可以任意顺序查看。读信后仍须主动寻找回信；第四项关闭后直接显示三种函件准备，删除自动串联材料的独白。正式界面显示房间热点与物件查看层，只有实际查看才获得材料知识。

C04 携原件采访时，玩家选择透露旧报与草图，或先只谈采访函，林怀安分别回应，再独立选择原件交出或收回。抄录与无纸面路径保留各自载体；无纸面路径见林只口述，警方登记口述并安排之后去报馆核验。C14 的两次观察陈述仅提供玩家此前实际看见的内容，亲自点击后才写入笔录。

世界事实、玩家亲耳获得的知识和剧情状态彼此独立。陈九生知道玉棠的药已经被换回，并不等于玩家知道；第一章只通过他的震惊、扫视和后续怀疑呈现可观察反应，系统不会替玩家总结真相。

## 当前结构

- outputs/01a037d8-c4f0-70d3-bc69-8c3819094801/雾港来信_剧情作者工作簿.xlsx：唯一剧情编辑入口。
- content/程序生成_请勿手改/剧情剧本.csv：由同步器生成的运行数据。
- scripts/story_repository.gd：中文表格加载、校验和条件转换层。
- scripts/main.gd：通用表格运行器、Topic Hub、占位 UI 和作者 Debug。
- scripts/game_state.gd：严格分离世界事实、玩家知识与玩家主动判断。
- tools/xlsx_story_importer.gd：Godot 内置的 XLSX 读取、校验与 CSV 转换层。
- tools/同步剧情工作簿.gd：保存工作簿后的同步入口。
- tests/test_story_content.gd：表结构、稳定 ID、后台 Hub 与知识条件。
- tests/test_workbook_sync.gd：验证 Excel 唯一入口可生成完整运行数据。
- tests/test_secret_release_content.gd：检查 C04/C14 函件信息释放，并禁止核心秘密提前泄露。
- tests/test_continuous_yutang_scene.gd：检查 v6 对话节拍、纯画面节点和关键选择数量。
- tests/test_opening_demo_logic.gd：检查序章工作桌与第三项无纸面路线。
- tests/test_full_flow.gd：从序章完整跑通 C01—C22，并验证第三项路线与警方后续核验。
- tests/test_v343_story_content.gd：确认 v6 工作簿已经替换 v3.4.3 活动内容。
- tests/test_prelude_free_exploration.gd：验证四项材料可乱序查看、完成后直接准备，且未点击不会获得知识。
- tests/test_player_response_ui.gd：验证实际回答按钮、历史、回退、连续主控句与过期点击。
- tests/test_interview_disclosure.gd：验证原件两种透露路径、即时 NPC 回应及纸面去向。
- tests/test_choice_backtracking.gd：测试按钮完整撤销最近选择并重新开始。
- tests/test_chapter_switching.gd：验证章节选择层、章节入口和切换后的进度隔离。
- tests/test_investigation_prompt.gd：验证旧报查看页保留原件句与“尚待核实”开放状态，不替玩家总结调查方法或认证旧案真相。
- tests/test_writing_panel.gd：验证写稿页显示来源记录，并只提供已有材料支持的报道选项。
- tests/test_writing_evidence_conditions.gd：验证台侧亲见与来路记录分别只开放强、窄位置写法。
- tests/test_writing_copy_variants.gd：验证来源选择会形成药盒强/窄句，并保留陈九生或方仲山的主体。
- tests/test_publication_text_separation.gd：验证报纸正文不混入场景后果说明。
- tests/test_c22_hook_reachability.gd：验证 C22 编辑裁决、站位名单和章末收束在 Demo 中可达。
- tests/test_c22_branch_reachability.gd：验证疑点报道的编辑强反馈与暂不抄录分支。

## 测试

    godot --headless --path . --script res://tests/test_game_state.gd
    godot --headless --path . --script res://tests/test_story_content.gd
    godot --headless --path . --script res://tests/test_secret_release_content.gd
    godot --headless --path . --script res://tests/test_continuous_yutang_scene.gd
    godot --headless --path . --script res://tests/test_opening_demo_logic.gd
    godot --headless --path . --script res://tests/test_full_flow.gd
    godot --headless --path . --script res://tests/test_v343_story_content.gd
    godot --headless --path . --script res://tests/test_prelude_free_exploration.gd
    godot --headless --path . --script res://tests/test_choice_backtracking.gd
    godot --headless --path . --script res://tests/test_chapter_switching.gd
    godot --headless --path . --script res://tests/test_workbook_sync.gd
    godot --headless --path . --script res://tests/test_manual_line_advance.gd
    godot --headless --path . --script res://tests/test_player_response_ui.gd
    godot --headless --path . --script res://tests/test_interview_disclosure.gd
    godot --headless --path . --script res://tests/test_investigation_prompt.gd
    godot --headless --path . --script res://tests/test_writing_panel.gd
    godot --headless --path . --script res://tests/test_writing_evidence_conditions.gd
    godot --headless --path . --script res://tests/test_writing_copy_variants.gd
    godot --headless --path . --script res://tests/test_publication_text_separation.gd
    godot --headless --path . --script res://tests/test_c22_hook_reachability.gd
    godot --headless --path . --script res://tests/test_c22_branch_reachability.gd
    python3 tests/test_opening_revision.py

## 范围说明

当前范围是序章 + 第一章 C01—C22、玩家知识状态与作者维护工作流。正式美术资源尚未制作；Demo 使用程序化场景 UI、色块和立绘框验证流程，不把技术占位文字放进对话框。
