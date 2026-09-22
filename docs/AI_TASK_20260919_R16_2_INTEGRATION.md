# AI 任务包：R16.2 第一阶段接入

> 文档性质：执行范围与调度记录，不是剧情事实源。R16.2 的详细台词与状态仍以交接包纳入仓库后的 source 文档/工作簿为准。

## 1. 基本信息

- 任务 ID：`TASK-R16.2-20260919-INTEGRATION`
- 任务标题：R16.2 canon switch、deterministic runtime compiler 与首条可运行路线
- 创建时间：2026-09-19（Asia/Shanghai）
- 调度员：主 Codex `/root`
- 用户原始命令：`你直接看交接包，里面包所有都说好了`；随后明确要求 `多开子代理执行`
- 执行档位：`formal`
- 当前状态：`COMPLETE`
- 目标版本 / 分支：R16.2 / `r16.2-integration`
- 集成提交：本任务分支当前 `HEAD`（交付时以 `git rev-parse HEAD` 输出为准）
- 回滚基线：`baseline-20260919` / `a920ebffff051bc005080bda536ceeda9966fe92`

## 2. 唯一目标

- 要达成的结果：把交接包中已经确认的 R16.2 作为当前开发口径，接入现有 Godot 4.7 工程；建立可重复的多 sheet → runtime JSON 编译链和通用运行时骨架，覆盖 D00→U32 至少一条路线所需的节点、选择、条件、状态、回溯、报纸状态与结局路由。
- 完成定义：权威文档切换记录完整；source 文件纳入仓库；编译器能验证并生成 `content/程序生成_请勿手改/r16_2_runtime.json`；运行时不在 `main.gd` 硬编码全篇对白；R16.2 静态校验、核心单元测试和 CI 元数据检查可重复执行；未完成的客户端 UI/美术/平台工作明确列出。
- 非目标：不重写人物动机或世界事实；不恢复 v5/v6 设定；不制作逐条报纸编辑器；不接入广告/平台发布；不删除旧资源或旧基线。

## 3. 权威与输入

### 权威依据

| 路径 / 决策 ID | 权威范围 | 本任务如何使用 | 读取状态 |
|---|---|---|---|
| `AGENTS.md` | 仓库调度、权威顺序与正式修改闭环 | 约束所有写入、生成物和冲突处理 | 已读取 |
| `docs/AI_TEAM_OPERATING_SYSTEM.md` | 档位、岗位、owner、QA 与审批流程 | 组织 formal 任务和交付 | 已读取 |
| `docs/DECISIONS.md`（迁移前） | 已确认旧决策与历史边界 | 识别需登记的 canon switch，不恢复旧事实 | 已读取 |
| `docs/CURRENT_TRUTH.md`（迁移前） | 旧 v6 当前真相 | 仅作为待降级的历史基线，不继续覆盖 R16.2 | 已读取 |
| 交接包 `02_R16_2_CANON_OVERRIDE.md` | R16.2 口径切换说明 | 作为本轮用户已确认的正式切换依据 | 已读取 |
| 交接包 `source/雾港来信_R16.2_程序接入表.xlsx` | 节点、选择、状态、DSL、验收运行规格 | 编译输入与静态校验来源 | 已读取 |
| 交接包 `source/雾港来信_R16.2_核心玩法与选择兑现版_全篇互动剧本.docx` | R16.2 正文与选择兑现 | 纳入仓库供作者查阅，运行数据以 XLSX 为结构源 | 已读取 |

### 实现与研究输入

| 路径 / 记录 ID | 类型 | 仅说明什么 | 是否可能过期 |
|---|---|---|---|
| 交接包 `01/03/04/05/06` | 实现方案、迁移地图与验收计划 | 实施范围、建议结构和测试目标 | 随 R16.2 变更需复核 |
| `scripts/game_state.gd`、`scripts/main.gd`、`prototypes/story_interaction_lab/` | 实现现状 | 可复用的状态、UI、节点图思想 | 是；不得覆盖权威口径 |
| `research/KNOWLEDGE_INDEX.md` 及三份研究 | 研究建议 | 试玩/互动/商业评审维度 | 是；仅 advisory |

- 禁止作为事实源的材料：v5、旧 v6 正文与信息树（除历史追溯）、旧生成 CSV、旧内容测试、研究建议、实现残留。
- 当前权威冲突：旧 `CURRENT_TRUTH.md`/AGENTS 权威顺序与交接包 R16.2 发生版本冲突；本任务的正式文档迁移负责解决，若源材料内部出现事实冲突则停止相应内容写入并标记待确认。

## 4. 正式修改审批门

- 是否影响正式剧情、人物、机制或商业策略：`是`
- 拟改变内容：将当前开发目标从旧 v6 切换为交接包 R16.2；将四章、U01–U32、轻量记者交互、报纸生命周期和四结局路由登记为当前开发口径。
- 影响范围：权威文档、数据编译入口、运行时状态/路由、测试分类和 CI。

### 变更影响检查

| 维度 | 是否受影响 | 证据 / 具体位置 | 需要同步或验证的文件 / 路径 | 状态 |
|---|---|---|---|---|
| 剧情事实、因果、场次与顺序 | 是 | R16.2 XLSX Nodes/Choices；交接包 canon override | `docs/r16_2/`、runtime JSON、静态校验 | 已确认范围内 |
| 人物动机、关系、年龄、称谓与持有物 | 是 | R16.2 DOCX/XLSX；不改写源内容 | `docs/r16_2/`、数据校验 | 已确认范围内 |
| 作者真相、角色私有知识、玩家知识与信息释放 | 是 | Knowledge_Permissions、StateDictionary、ConditionDSL | state store、条件 evaluator、QA | 已确认范围内 |
| 核心机制、六个主角动词与 Demo 结构 | 是 | UI_Interactions、RuntimeContract、Chapters | runtime、tests、README | 已确认范围内 |
| 权威文档、`DECISIONS.md` 与 `CURRENT_TRUTH.md` | 是 | canon switch 文件 | `AGENTS.md`、`docs/DECISIONS.md`、`docs/CURRENT_TRUTH.md` | 已确认范围内 |
| 工作簿作者入口、同步链与程序生成物 | 是 | 多 sheet XLSX 与旧 21 列导入器差异 | 新 compiler、生成 JSON（不手改） | 已确认范围内 |
| 代码、状态、存档、资源与迁移 | 是 | Engine migration plan | 新 runtime/state/compiler | 已确认范围内 |
| 测试、过期基线与回归范围 | 是 | Acceptance plan / legacy tests | 新 R16.2 tests、旧测试分类、CI | 已确认范围内 |
| Demo Hook、商店页、Trailer、定价与发行 | 仅评审 | 研究与包内商业边界 | 不在本轮写入商业策略 | 待验证，不改正式策略 |

- 用户明确确认原文或决策 ID：用户本轮确认“交接包里面包所有都说好了”，并要求直接执行；交接包 `02_R16_2_CANON_OVERRIDE.md` 记录该口径切换。
- 确认时间：2026-09-19 当前会话
- `DECISIONS.md` 更新责任人：主 Codex `/root`
- `CURRENT_TRUTH.md` 是否需要同步：`是`
- 审批状态：`已确认（范围限于交接包 R16.2 第一阶段）`

## 5. 岗位与工作分解

### 启用岗位

- `narrative`：启用；只读检查 R16.2 结构与禁止脑补边界。
- `continuity`：启用；核对时间线、知识边界和旧 v6 残留。
- `dialogue`：启用；抽查玩家可见对白与信息释放，不改源稿。
- `playtest`：启用；设计主线/负向路径和交互可理解性验收。
- `commercial_reviewer`：启用；复用现有研究评审轻量记者 Hook，提出待验证项，不改商业事实。
- `programmer`：启用；唯一实现 owner 为主 Codex。
- `qa`：启用；由主 Codex 在实现后以独立只读阶段执行，代理容量不足时保留未独立验证标记。

### 子任务

| 子任务 ID | 目标 | 岗位 / owner | 输入 | 输出 | 依赖 | 可否并行 | 状态 |
|---|---|---|---|---|---|---|---|
| R16-A | 入口/交接包审阅 | narrative/continuity | 交接包 docs/source | 事实与冲突报告 | 无 | 是 | 主 Codex完成；代理尝试因容量失败 |
| R16-B | 运行结构编译器与静态校验 | programmer | R16.2 XLSX | compiler + runtime JSON | R16-A | 否 | 已完成 |
| R16-C | 状态/条件/节点运行骨架 | programmer | RuntimeContract/ConditionDSL | GDScript runtime + tests | R16-B | 否 | 已完成 |
| R16-D | 交互/报纸/结局规格接入 | programmer/playtest | UI_Interactions 等 sheets | 数据结构、占位控制器、tests | R16-B/C | 否 | 已完成 |
| R16-E | 独立 QA 与旧测试分类 | qa | Acceptance plan | 命令、结果、失败分类 | R16-B/C/D | 否 | 已完成（主 Codex + 两个只读代理复核） |

## 6. 文件范围与唯一 owner

### 允许修改

| 文件 / 工作簿 | 唯一 owner | 允许的改动 | 合并 / 审查人 |
|---|---|---|---|
| `AGENTS.md`、`README.md`、`docs/CURRENT_TRUTH.md`、`docs/DECISIONS.md` | 主 Codex | R16.2 权威切换与状态说明 | continuity/narrative 只读审查 |
| `docs/r16_2/` | 主 Codex | 保存交接源与适配说明 | QA |
| `tools/r16_2_compile.py`、`tools/r16_2_validate.py` | 主 Codex | 确定性编译与静态校验 | programmer/qa |
| `scripts/r16_2_*.gd`、必要的 `scripts/game_state.gd` 适配 | 主 Codex | 通用运行层，不硬编码对白 | programmer/qa |
| `tests/test_r16_2_*.gd`、必要的 Python 测试 | 主 Codex | R16.2 行为与数据测试 | qa |
| `.github/workflows/ci.yml` | 主 Codex | Godot 4.7 与编译/校验门禁 | qa |
| `content/程序生成_请勿手改/r16_2_runtime.json` | 生成流程 owner | 仅由 compiler 生成，禁止手改 | qa |

### 只读

- 交接包原目录 `/Users/kker/Downloads/雾港来信_R16.2_Agent开发交接包/`（读取后复制来源，不在原目录写入）。
- 旧 v5/v6 文档、旧工作簿、旧生成 CSV、既有美术资源。

### 明确禁止修改

- `content/程序生成_请勿手改/` 中既有生成物（新 JSON 只能由脚本生成）。
- 交接包 source 原文件。
- 旧 v6 剧情正文以“兼容”为目的的任何回写。
- 未列入本任务的商业策略、平台发布、美术资产。

- 是否允许检查工具产生缓存、`user://` 数据或临时文件：`仅允许 /tmp/r16_2_*`；执行前后检查 git 状态并清理可清理临时物。

### 回滚点

- Git tag `baseline-20260919` / commit `a920ebffff051bc005080bda536ceeda9966fe92`。
- 恢复方法：切回基线或删除本任务分支；不删除用户已有文件。

## 7. 研究复用计划

- 已搜索：`research/KNOWLEDGE_INDEX.md`、`COMPETITOR_INDEX.md`、`DESIGN_PATTERNS.md`、`COMMERCIAL_STRATEGY.md`。
- 可直接复用：仅作为 playtest/commercial 评审维度；不写入正式事实。
- 需要复核：R16.2 已改变产品结构和商业方向，旧 Steam 买断假设不适用于本轮；如需更新市场/IAA 结论，另开研究任务。
- 是否需要新研究：`否`。
- 新研究触发条件：进入商店页、Trailer、定价、发行或用户明确要求最新市场资料。

## 8. 验收计划

| 验收项 | 方法 / 命令 | 预期结果 | 验收人 | 结果 |
|---|---|---|---|---|
| 包源哈希 | `sha256sum` 对照 manifest | 与包清单一致 | 主 Codex/qa | 通过（4 个 source 文件） |
| 编译/静态校验 | `python3 tools/r16_2_compile.py --check`；`python3 tools/r16_2_validate.py` | 无重复 ID、悬空引用、非法状态/条件 | 主 Codex/qa | 通过 |
| runtime 单元行为 | `python3 -m unittest discover -s tests -p 'test_r16_2_*.py'` | R16.2 条件/回溯/生命周期通过 | qa | 通过（8 项） |
| Godot headless | `godot --headless --path . --editor --quit` 与项目测试入口 | 启动无脚本解析错误 | qa | 通过（macOS Godot 4.7） |
| CI 元数据 | `python3 tools/validate_workflow_metadata.py --root .` | 通过 | qa | 通过（10 个知识资产） |
| 主线路由 | 编译数据 + runtime route smoke | D00→U32 可解析；交互节点暂停 | qa | 通过（Route A/B/C/D） |

- 必测正常路径：Route A/B/C/D（见交接包 `05_ACCEPTANCE_TEST_PLAN.md`）。
- 必测负向 / 边界路径：未知条件、重复 ID、悬空 NextNode/Snapshot、U15 错序、U27 无效句、U28 未确认发行、story/global 回溯隔离、off-record/匿名泄露。
- 独立 QA 是否必须：`是`（当前代理容量不足时明确标记为主 Codex独立阶段，不能伪装为外部独立代理）。
- 允许存在的已知失败：旧 v6 内容断言可失败，但必须分类为过期测试并不改 R16.2。

## 9. 停止与阻塞条件

- 必须暂停写入的条件：R16.2 source 内部事实冲突；无法确定权威字段含义；需要改变交接包锁定剧情/结局/交互上限；生成链会覆盖用户文件且无回滚。
- 当前阻塞：最初六个并行岗位请求返回“Selected model is at capacity”；随后容量恢复，`runtime_review_retry` 与 `handoff_acceptance_retry` 完成只读复核。其余岗位未生成独立报告，不阻塞已完成的主线验证。
- 解除阻塞所需的最小外部条件：代理容量恢复或用户接受主 Codex 以独立阶段完成审查。
- 不受阻塞、仍可继续：包源核对、权威文档切换、compiler/runtime/test 实现与本地验证。

## 10. 交付记录

### 实际修改文件

- 权威与流程：`AGENTS.md`、`README.md`、`docs/CURRENT_TRUTH.md`、`docs/DECISIONS.md`、`roles/*.md`、本任务包。
- 交接源：`docs/r16_2/source/`、`docs/r16_2/handoff/`、`docs/r16_2/legacy/`、`docs/r16_2/README.md`。
- 编译与校验：`tools/r16_2_compile.py`、`tools/r16_2_validate.py`、`content/程序生成_请勿手改/r16_2_runtime.json`。
- 运行层与入口：`scripts/r16_2_condition_evaluator.gd`、`scripts/r16_2_state_store.gd`、`scripts/r16_2_article_builder.gd`、`scripts/r16_2_runtime.gd`、`scripts/r16_2_main.gd`、`scenes/r16_2_main.tscn`、`project.godot`。
- 测试与 CI：`tests/test_r16_2_compiler.py`、`tests/test_r16_2_runtime.gd`、`tests/test_r16_2_acceptance.gd`、`.github/workflows/ci.yml`。

### 合并后的结论

- R16.2 已登记为当前开发口径；旧 v6 已明确降级为 legacy，未与 R16.2 拼接。
- XLSX → 确定性 JSON 编译链覆盖 36 Nodes、66 Choices、124 StateDictionary 项、66 Snapshots，并保留非索引规格表。
- Godot 运行层已覆盖 typed ConditionDSL、story/global snapshot、D27/U15 puzzles、U08 两步送排、D65-B/D65-C 自动组稿/预览确认、D66 生命周期与 E03→E04→E02→E01 路由。
- off-record、匿名来源和未授权私密动机在 ArticleBuilder 中有独立保护断点；四条路线 smoke 已通过。

### 未解决冲突与待确认事项

- 未发现 R16.2 DOCX/XLSX 内部事实冲突；没有新增待确认剧情事实。
- 完整客户端美术替换、移动端适配、IAA 接入、商店页/发行仍不在本阶段范围。
- 本机已用 macOS Godot 4.7 headless 实测；CI 使用 Linux Godot 4.7 下载任务，未在本机执行 Linux 二进制。
- 旧 v6 测试未作为 R16.2 门禁；若失败需按 legacy 归类，不回写 R16.2 事实。

### 验证命令与结果

- `sha256sum docs/r16_2/source/*`：四个源文件与包 manifest 一致。
- `python3 tools/r16_2_compile.py --check`：通过（66 choices / 36 nodes）。
- `python3 tools/r16_2_validate.py`：通过。
- `python3 -m unittest discover -s tests -p 'test_r16_2_*.py' -v`：8 项通过。
- `python3 tools/validate_workflow_metadata.py --root .`：通过（10 个知识资产）。
- 实现文件的 `git diff --check`：通过；纳入仓库的 handoff/legacy Markdown 保留交接包原有的 Markdown 末尾双空格（用于硬换行），因此对整次提交执行 `git diff --check HEAD^ HEAD` 会报告这些原始格式提示，未为清理提示改写交接资料。
- `Godot 4.7 --headless --editor --quit`：通过（仅提示嵌套 legacy project 被忽略）。
- `Godot 4.7 --headless --script res://tests/test_r16_2_runtime.gd`：通过。
- `Godot 4.7 --headless --script res://tests/test_r16_2_acceptance.gd`：通过（Route A/B/C/D、privacy barrier、puzzle retry、ending priority）。
- CI YAML 解析：通过；Godot headless job 已启用。
- 截图：本阶段采用 Godot headless 验收；dummy headless 渲染器不提供可保存的视口纹理，因此未把临时截图写入仓库，避免把测试产物混入基线。

### 失败分类

- 真实缺陷：初版 U27 动态句与卡片 ID协议冲突，已修复并加入回归测试。
- 真实缺陷：初版 GDScript 严格类型推断警告被 Godot 作为错误，已修复并通过 headless。
- 过期测试：旧 v6 内容测试不纳入本轮 R16.2 事实验收，未修改其剧情断言。
- 环境限制：并行代理服务短时容量不足；Linux Godot 二进制未在 macOS 本机执行，但 CI 配置已验证下载包结构。

- 最终状态：`COMPLETE`。
