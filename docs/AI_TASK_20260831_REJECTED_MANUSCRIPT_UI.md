# AI 任务包｜P0001 退稿说明改为稿件 UI

> 文档性质：执行范围与调度记录，不是剧情事实源、机制事实源或商业结论。

## 1. 基本信息

- 任务 ID：`AI-TASK-20260831-REJECTED-MANUSCRIPT-UI`
- 任务标题：删除 P0001 退稿说明旁白并改用稿件 UI
- 创建时间：2026-08-31
- 调度员：主 Codex
- 用户原始命令：`还有我觉得这句话也没必要，直接ui表达展示个稿件不好被退稿的样子就行了`
- 执行档位：`formal`
- 当前状态：`COMPLETE`
- 目标版本 / 分支 / 提交：当前本地工作区

## 2. 唯一目标

- 要达成的结果：删除 P0001 中“沈砚舟的稿纸上……”两句说明旁白，以可见稿页、红笔删改与撤稿标记直接表达稿件被否。
- 完成定义：运行界面不再出现该说明文字；P0001 场景出现可识别的退稿稿件 UI；稿位被撤、红笔否掉强结论与原有句序/去向不变；工作簿、生成 CSV、权威文档和测试同步。
- 非目标：不新增编辑判词、证据方法论说明、人物动机、玩家知识、主角动词、美术图片资产、动画或新场次。

## 3. 权威与输入

### 权威依据

| 路径 / 决策 ID | 权威范围 | 本任务如何使用 | 读取状态 |
|---|---|---|---|
| `docs/CURRENT_TRUTH.md` | 当前事实与实现边界 | 保持 S00 职业处境和知识边界 | 已读取 |
| `docs/剧情修订稿_v6_人物与前史.md` | S00 目的与稿纸细节 | 保留稿件被否和红笔细节，不恢复方法论对白 | 已读取 |
| `docs/雾港来信_序章与第一章完整剧情信息树_v6.md` | S00 实际顺序与台词 | 只替换说明旁白的呈现方式 | 已读取 |
| `DEC-20260830-15` | S00 职业失意与大新闻动机 | 不改变六号码头撤稿、春和派活和版面问答 | 已读取 |
| `DEC-20260831-29` | 本轮已确认变更 | 删除说明旁白并改为稿件 UI | 本任务同步 |

### 实现与研究输入

| 路径 / 记录 ID | 类型 | 仅说明什么 | 是否可能过期 |
|---|---|---|---|
| P0001 现行工作簿/CSV | 实现现状 | 说明旁白当前写在 `NPC台词`，画面字段已有稿纸红笔要求 | 否 |
| `scripts/main.gd` | 实现现状 | 中央场景面板目前为空白占位，可承载 authored interaction UI | 否 |
| `PATTERN-20260830-12` | 研究建议 | 已由画面表达的内容不应重复说 | 否 |
| `research/COMMERCIAL_STRATEGY.md` | 研究建议 | 职业动作和输入—反馈应直接可见 | 否 |

- 禁止作为事实源的材料：截图中的红框、研究建议、旧实现、v5、备份和过期测试。
- 当前权威冲突：无。新决定只取代文字呈现，不取代 `DEC-20260830-15` 的剧情事实。

## 4. 正式修改审批门

- 是否影响正式剧情、人物、机制或商业策略：是（S00 玩家可见演出）；不改变事实或对白含义。
- 拟改变内容：删除 P0001 两句说明旁白，改为退稿稿件 UI。
- 影响范围：两份 v6 权威文档、`DECISIONS.md`、`CURRENT_TRUTH.md`、唯一作者工作簿、同步 CSV、Godot UI 和测试。
- 用户明确确认原文：`还有我觉得这句话也没必要，直接ui表达展示个稿件不好被退稿的样子就行了`
- 确认时间：2026-08-31
- `DECISIONS.md` 更新责任人：主 Codex
- `CURRENT_TRUTH.md` 是否需要同步：是
- 审批状态：已确认

### 变更影响检查

| 维度 | 是否受影响 | 处理 |
|---|---|---|
| 剧情事实、因果、场次与顺序 | 否 | 稿位被撤、春和派活、版面问答与去向不变 |
| 人物动机、关系、年龄、称谓与持有物 | 否 | 不修改 |
| 玩家知识与信息释放 | 否 | P0001 无对应 Knowledge 写入；只从说明改为可见画面 |
| 核心机制、六个主角动词与 Demo 结构 | 否 | 不新增交互动作或场次 |
| 权威文档 | 是 | 记录 UI 呈现并删除说明旁白 |
| 工作簿、同步链与生成物 | 是 | P0001 值修改后由同步器生成 CSV |
| 代码与测试 | 是 | authored tag 驱动的退稿稿件 UI 与回归测试 |
| 商业策略 | 否 | 研究只作呈现评审依据 |

## 5. 岗位与工作分解

- `narrative`：启用；确认只删重复说明，不改 S00 结构。
- `continuity`：启用；核对红笔细节、撤稿事实与玩家知识边界。
- `dialogue`：启用；删除无行动作用的说明句，不新增替代对白。
- `playtest`：启用；验证无需读说明即可看懂稿件被退。
- `commercial_reviewer`：启用；检查开场职业动作是否更直接可见。
- `programmer`：启用；负责通用演出标签和 Godot Control UI。
- `qa`：启用；独立验证工作簿、同步、UI、逐句节拍与回归。

## 6. 文件范围与唯一 owner

### 允许修改

| 文件 | 唯一 owner | 允许的改动 |
|---|---|---|
| `docs/DECISIONS.md`、`docs/CURRENT_TRUTH.md` | 主 Codex | 决策与当前状态同步 |
| 两份 v6 权威剧情文档 | narrative / 主 Codex | 删除说明旁白、改写为 UI 演出说明 |
| 唯一作者工作簿及其当前字节一致副本 | workbook owner / 主 Codex | 只改 P0001 的 `NPC台词`、`画面表现`、`演出/交互方式` |
| `scripts/main.gd` | programmer / 主 Codex | authored tag 驱动的稿件 UI |
| `tests/test_rejected_manuscript_ui.gd`、相关同步/开场测试 | programmer / 主 Codex | 新行为与过期断言同步 |
| 本任务包 | 主 Codex | 状态和验收记录 |

### 明确禁止修改

- 手工编辑 `content/程序生成_请勿手改/剧情剧本.csv`；只能运行同步器。
- P0001 以外的工作簿剧情行、台词、知识、状态和路由。
- 新增图片资源、编辑方法论判词、信誉进度条或解释性旁白。

### 回滚点

- 修改前记录两份工作簿 SHA-256；artifact-tool 在临时目录导入后定点导出；文档和代码使用补丁。

## 7. 研究复用计划

- 已读取：知识索引及三份 research 文档。
- 可复用：`PATTERN-20260830-12` 与商业策略中的可见职业动作/输入反馈原则。
- 是否需要新研究：否。用户已经确认具体呈现方向。

## 8. 验收计划

| 验收项 | 方法 / 命令 | 预期结果 | 结果 |
|---|---|---|---|
| 先失败测试 | `test_rejected_manuscript_ui.gd` | 修改前因旁白仍在、UI 缺失而失败 | PASS：修改前按预期出现 5 条失败，覆盖旧旁白、缺少标签/UI/“撤”章和 13 个旧节拍 |
| 工作簿同步 | 同步器 + `test_workbook_sync.gd` | 357 行、两份工作簿一致、P0001 新值生效 | PASS：同步 357 行；两份工作簿 SHA-256 均为 `8801f42fee56131237e83cd5cfaaa21bc57637a37e42d80cbbde0bd3ceb6683e`；同步测试通过 |
| UI 行为 | 新测试 + 可见截图 | 无说明旁白；稿件 UI 可识别 | PASS：层叠稿页、红色删改线与“撤”章可见；离开 P0001 后 UI 清除 |
| 逐句回归 | `test_manual_line_advance.gd`、`test_s00_opening.gd` | 新 P0001 节拍数与路径正确 | PASS：11 个手动节拍，逐击推进，最终进入自由探索 |
| 全量回归 | 全部 Godot tests | 本轮新增真实失败为零 | PASS（按基线）：18 项中 13 项通过；5 项既有旧序章测试失败，本轮无新增真实失败 |

- 必测正常路径：首句 → 稿件 UI 持续可见 → 逐句继续 → 自由探索。
- 必测负向 / 边界路径：不出现被删说明；UI 不写玩家知识；其他阶段不显示稿件 UI；物件页不受影响。
- 独立 QA 是否必须：是（主 Codex 以单独验收阶段执行）。
- 允许存在的已知失败：5 项既有 v5/旧宅/367 行过期测试，必须分开报告。

## 9. 停止与阻塞条件

- 必须暂停写入：需要发明新的编辑批注、改变原始观察事实、修改 P0001 以外剧情行或出现权威冲突。
- 当前阻塞：无。
- 不受阻塞、仍可继续的工作：测试、定点工作簿同步、UI 实现与验证。

## 10. 交付记录

- 实际修改文件：
  - 权威与决策：`docs/DECISIONS.md`、`docs/CURRENT_TRUTH.md`、`docs/剧情修订稿_v6_人物与前史.md`、`docs/雾港来信_序章与第一章完整剧情信息树_v6.md`。
  - 作者入口与生成物：两份当前工作簿、`content/程序生成_请勿手改/剧情剧本.csv`（仅由同步器生成）。
  - 实现与测试：`scripts/main.gd`、`tests/test_rejected_manuscript_ui.gd`、`tests/test_manual_line_advance.gd`、`tests/test_workbook_sync.gd`。
  - 调度记录：本任务包。
- 各岗位报告：
  - `narrative` / `dialogue`：被删文字只重复稿面，不承担新行动或必达对白；其余 P0001 句序保持。
  - `continuity`：六号码头撤稿、红笔否掉强结论、春和派活和玩家知识写入未变；未新增“证据不足”等判词。
  - `playtest` / `commercial_reviewer`：首拍不读说明也能从层叠稿页、密集红改和“撤”章看出退稿，职业受挫反馈更直接。
  - `programmer`：运行器按工作簿 `退稿稿件UI` 标签绘制 Control UI，不硬编码 P0001 阶段名；离场由画布清理自动移除。
  - `qa`：新增先红后绿测试，并完成定向、全量、工作流、Python 和项目加载验证。
- 合并后的结论：用户确认的说明句已从正式文档、作者工作簿和运行数据删除；退稿信息改由 UI 表达；P0001 从 13 个节拍缩为 11 个，仍逐击推进。
- 未解决冲突：无。本轮没有触及待确认事实；研究建议只用于评审呈现，没有升级为设定。
- 验证命令与结果：
  - `Godot --headless --path . --script res://tests/test_rejected_manuscript_ui.gd`：修改前 RED（5 条预期失败），修改后 PASS。
  - `Godot --headless --path . --script res://tools/同步剧情工作簿.gd`：PASS，357 行。
  - `test_workbook_sync.gd`、`test_manual_line_advance.gd`、`test_s00_opening.gd`、`test_v343_story_content.gd`、`test_prelude_free_exploration.gd`：PASS。
  - 全部 18 项 GDScript 测试逐项运行：13 PASS，5 个已知旧测试 FAIL。
  - `python3 tests/test_workflow_metadata.py`：13 tests OK；`python3 tests/test_reporter_public_death_conclusion.py`：PASS。
  - `python3 tools/validate_workflow_metadata.py --root .`：PASS；Godot headless editor 项目加载：exit 0。
- 失败分类：`test_chapter_switching.gd`、`test_choice_backtracking.gd`、`test_full_flow.gd`、`test_opening_demo_logic.gd` 仍引用已删除的旅行箱、父亲、书信夹等旧序章流程；`test_v27_story_content.gd` 仍期待旧 367 行和已撤的返港生活热点。均为本任务前已知过期测试，不是本轮实现回归。
- 最终状态：`COMPLETE`
