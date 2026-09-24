# AI 任务包：第一章 Steam Demo「信息流」重构

> 文档性质：正式任务包。它记录本轮已获用户确认的目标、范围与验证，不替代 v6 剧情正典。

## 1. 基本信息

- 任务 ID：`AI-TASK-20260923-DEMO-INFO-FLOW`
- 任务标题：第一章 Steam Demo 的记者调查与信息流主轴
- 创建时间：2026-09-23
- 调度员：`/root`
- 用户原始命令：确认把 Demo 核心卖点改为“决定一条报道如何成为公众事实”，并补充“主角作为记者也在一边调查真相”。
- 执行档位：`formal`
- 当前状态：`REVIEW`
- 目标版本 / 分支 / 提交：当前工作树；不覆盖其他代理已有改动

## 2. 唯一目标

- 要达成的结果：把 Steam Demo 从“第一章线性缩短版”重构为一条独立精选路线：玩家作为记者选择一处现有说法进行核对，调查取得有来源的记录，决定谁知道什么，写下一句有依据的报道，并在见报与编辑反馈中看到后果。
- 完成定义：
  1. Demo 开场数分钟内出现一个玩家可理解、可操作的调查问题；
  2. 开场的旧报待核问题贯穿材料、采访与现场路线核对；尸体出现后生成独立的“今夜现场发生了什么 / 哪句能写”问题，两条问题在写稿与公开范围汇合，但不得互相认证或把 1937 证据回填为 1917 真相；
  3. Demo 内完成一次“问题 → 观察/材料 → 信息公开范围 → 写稿 → 后果”的闭环；
  4. 玩家能看到自己的材料经过谁的手、谁因此知道什么，以及一句报道如何进入公共版本；
  5. C21/C22 的报纸、编辑裁决和站位名单钩子可达；
  6. 完整第一章作者层顺序与 v6 正典不被 Demo 精选路线静默改写。
- 非目标：
  - 不认证 1917 真相、赵敬文案新证据路径或第二章正式场次；
  - 不恢复“戏班换角”独立教学页；
  - 不新增第七个主角动词、立场数值或全局树状分支；
  - 不手改 `content/程序生成_请勿手改/` 生成物；
  - 不把竞品研究直接写成剧情事实。

## 3. 权威与输入

### 权威依据

| 路径 / 决策 ID | 权威范围 | 本任务如何使用 | 读取状态 |
|---|---|---|---|
| `docs/CURRENT_TRUTH.md` | v6 当前事实、六个主角动词、运行现状 | 约束“决定谁知道什么”、玩家知识和运行入口 | 已读取 |
| `docs/剧情修订稿_v6_人物与前史.md` | 人物、主题、核心机制、信息流动 | 约束记者调查、来源边界与作者真相 | 已读取 |
| `docs/雾港来信_序章与第一章完整剧情信息树_v6.md` | 序章与第一章实际场次 | 选择可复用场次，不补写缺口 | 已读取 |
| `docs/DECISIONS.md` | 已确认交互与第一章可玩性 | 继承 `DEC-20260908-34`、`DEC-20260922-CH1-PLAYABILITY`、`DEC-20260922-CANON-REVERT-V6` 等边界 | 已读取 |
| 用户本轮确认（2026-09-23） | Demo 产品方向授权 | 允许进入正式修改闭环 | 已确认 |

### 实现与研究输入

| 路径 / 记录 ID | 类型 | 仅说明什么 | 是否可能过期 |
|---|---|---|---|
| `research/KNOWLEDGE_INDEX.md` | 研究索引 | 竞品、设计模式、商业策略的复用边界 | 是 |
| `research/COMPETITOR_INDEX.md` | 研究索引 | Golden Idol、Obra Dinn、Papers Please 等公开机制来源 | 是 |
| `research/DESIGN_PATTERNS.md` | 设计研究 | Demo 核心循环、证据与写稿盘的建议 | 是 |
| `research/COMMERCIAL_STRATEGY.md` | 商业假设 | Demo 内完成观察→材料→写稿→后果的验证目标 | 是 |
| `scripts/main.gd` | 实现现状 | C18 `写稿` 的呈现方式与 C22 终止路由 | 是 |
| `content/程序生成_请勿手改/剧情剧本.csv` | 生成实现现状 | 当前 147 条运行行与 C18/C21/C22 状态 | 是 |

- 禁止作为事实源的材料：岗位报告、竞品建议、聊天未确认提案、v5、备份、R16.2 剧情正文、旧测试与当前代码旧实现。
- 当前权威冲突：无；`DEC-20260922-CANON-REVERT-V6` 继续有效。

## 4. 正式修改审批门

- 是否影响正式剧情、人物、机制或商业策略：`是`
- 拟改变内容：Steam Demo 的产品定位与独立精选路线；把记者调查与“决定谁知道什么”作为可见体验主轴；使既有 C18 写稿与 C21/C22 后果在 Demo 中实际可玩、可达。
- 影响范围：Demo 路线、信息释放、写稿 UI、证据持有/公开范围可视化、C22 路由、工作簿与同步运行数据、测试。

### 变更影响检查

| 维度 | 是否受影响 | 证据 / 具体位置 | 需要同步或验证的文件 / 路径 | 状态 |
|---|---|---|---|---|
| 剧情事实、因果、场次与顺序 | 是 / 待确认 | Demo 独立路线需要重排现有场次；完整章正典顺序保留 | v6 剧情树、工作簿 Demo 流程 | 由 narrative/continuity 审查 |
| 人物动机、关系、年龄、称谓与持有物 | 待确认 | 只复用已确认材料持有状态 | v6 人物与前史、函件分支 | 不得新增 |
| 作者真相、角色私有知识、玩家知识与信息释放 | 是 | “谁知道什么”成为可见状态，但不认证作者真相 | CURRENT_TRUTH、状态与测试 | 由 continuity/qa 审查 |
| 核心机制、六个主角动词与 Demo 结构 | 是 | 使用现有六个动词，不新增第七个 | DECISIONS、CURRENT_TRUTH、运行器 | 已获用户方向确认，细节待岗位审查 |
| 权威文档、`DECISIONS.md` 与 `CURRENT_TRUTH.md` | 是 | 需要登记本轮方向 | 两份权威文档 | `/root` owner |
| 工作簿作者入口、同步链与程序生成物 | 是 | Demo 精选路线需有正式数据入口 | 工作簿、同步器、CSV | 生成流程负责 |
| 代码、状态、存档、资源与迁移 | 是 | C18/C22 已有实现缺口 | `scripts/main.gd`、状态与 UI | programmer owner |
| 测试、过期基线与回归范围 | 是 | 需覆盖 Demo 路线与玩家知识边界 | `tests/`、同步检查 | 独立 qa owner |
| Demo Hook、商店页、Trailer、定价与发行 | 是 | 产品定位改变；商店/Trailer 只记录为后续同步项 | `research/COMMERCIAL_STRATEGY.md`（建议）与发行素材 | 商业评审 |

- 用户明确确认原文或决策 ID：用户 2026-09-23 回复“好的，并且我觉得作为记者也在一边调查真相”，承接上一条“把 Demo 核心卖点改成决定一条报道如何成为公众事实，并围绕信息流重排”的确认。
- 确认时间：2026-09-23
- `DECISIONS.md` 更新责任人：`/root`
- `CURRENT_TRUTH.md` 是否需要同步：`是`
- 审批状态：`已确认`

## 5. 岗位与工作分解

### 启用岗位

- `narrative`：启用；设计独立 Demo 的问题、冲突、调查与闭环
- `continuity`：启用；核对事实、来源与玩家知识边界
- `dialogue`：启用；审查记者调查主轴下的对话目的与信息释放
- `playtest`：启用；复现当前路径并制定信息流可理解性验收
- `commercial_reviewer`：启用；评估差异化、购买理由、商店与 Trailer 表达
- `programmer`：启用；实现已确认路线、C18 写稿反馈和 C22 可达性
- `qa`：启用；独立验证数据同步、玩家知识、负向路径与回归

### 子任务

| 子任务 ID | 目标 | 岗位 / owner | 输入 | 输出 | 依赖 | 可否并行 | 状态 |
|---|---|---|---|---|---|---|---|
| D01 | 设计同一“待核说法”贯穿 Demo 的场次结构 | narrative | v6 剧情树、当前决策 | 逐段结构报告 | 无 | 是 | DONE（保留两条并行问题） |
| D02 | 核对证据持有、公开范围、玩家知识边界 | continuity | v6 作者文档、CURRENT_TRUTH | 连续性报告 | 无 | 是 | DONE（1917 与 1937 不互证） |
| D03 | 审查对话是否服务记者调查与信息流 | dialogue | S00–C22 当前文本 | 对白审查报告 | D01 可并行 | 是 | READY |
| D04 | 评估竞品对齐、购买理由、Trailer/截图钩子 | commercial_reviewer | 竞品研究、商业策略 | 商业评审报告 | 无 | 是 | DONE |
| D05 | 复现当前玩家路径并定义体验验收 | playtest | Godot v6 运行版、CSV | 试玩报告 | 无 | 是 | DONE |
| D06 | 分层实现 C18/C22 与信息流 UI 的最小范围 | programmer | `main.gd`、状态、生成数据 | 程序实施清单 | D01/D02 | 是 | DONE（C18/C22 最小闭环） |
| D07 | 建立回归与负向路径验收 | qa | 测试套件、任务目标 | QA 报告 | D06 | 否 | DONE（仍有数据层待确认项） |

## 6. 文件范围与唯一 owner

### 允许修改

| 文件 / 工作簿 | 唯一 owner | 允许的改动 | 合并 / 审查人 |
|---|---|---|---|
| `docs/DECISIONS.md` | `/root` | 登记本轮已确认 Demo 方向 | continuity / narrative 审查 |
| `docs/CURRENT_TRUTH.md` | `/root` | 同步已确认的 Demo 目标与实现状态 | continuity / qa 审查 |
| `docs/雾港来信_序章与第一章完整剧情信息树_v6.md` | `/root`（待 D01/D02 后） | 仅在确认具体路线后同步 Demo 精选路线标记 | narrative / continuity |
| `outputs/01a037d8-c4f0-70d3-bc69-8c3819094801/雾港来信_剧情作者工作簿.xlsx` | `/root`（待路线确认后） | 仅通过既有同步流程写入已确认 Demo 数据 | narrative / programmer |
| `outputs/雾港来信_剧情作者工作簿_v4.1.xlsx` | `/root`（待路线确认后） | 与入口工作簿同步 | qa |
| `scripts/main.gd` 与相关 v6 状态/UI脚本 | `/root`（实现合并） | 修复 C22 路由、旧报调查提示、C18 来源面板与两步写稿、证据条件收窄 | qa |
| `tests/` 相关测试 | `/root`（实现合并） | 覆盖旧报提示、来源选择、位置证据强弱、C22 分支 | qa / programmer |

### 只读

- `research/` 全部研究文件（除非另行确认新增研究记录）
- `docs/r16_2/` 全部历史资料
- `content/程序生成_请勿手改/`（由同步器生成，不手改）
- 用户已有的其他未列文件与代理既有改动

### 明确禁止修改

- 不得恢复“戏班换角”独立教学页。
- 不得新增第七个主角动词、全局立场数值或未经确认的真相判断。
- 不得补写 4.4.3 赵敬文案证据路径、第二章以后场次、第二个死人或其他“仍未定”内容。
- 不得把 NPC 证词、研究建议或实现残留升级为作者层事实。
- `content/程序生成_请勿手改/` 禁止手工编辑。

- 是否允许检查工具产生缓存、`user://` 数据或临时文件：`是，仅限仓库既有测试/导入路径；生成物必须可回溯并在交付中列出`

### 回滚点

- Git 当前工作树与代理已有改动不作回滚点；正式新增内容先用独立任务包和局部 diff 记录。
- 若路线细节仍有冲突，停止对应文件写入，仅保留报告和待确认项。

## 7. 研究复用计划

- 已搜索的研究索引 / 文件：`research/KNOWLEDGE_INDEX.md`、`research/COMPETITOR_INDEX.md`、`research/DESIGN_PATTERNS.md`、`research/COMMERCIAL_STRATEGY.md`。
- 可直接复用的记录：竞品首案交付核心动作、材料→判断→后果、Demo 内完成一次闭环的研究建议；均保持“建议”属性。
- 需要复核的记录及原因：本次 Demo 主结构发生重大变化，商业研究 `COM-20260830-01` 的 Demo 假设需由 commercial_reviewer 重新对齐。
- 是否需要新研究：否；已有来源覆盖当前问题，除非岗位发现冲突或链接失效。
- 新研究触发条件：出现新核心机制、现有竞品证据不足、或用户要求最新市场数据。
- 研究输出位置：岗位报告与本任务包；未经另行确认不写入长期研究结论。

## 8. 验收计划

| 验收项 | 方法 / 命令 | 预期结果 | 验收人 | 结果 |
|---|---|---|---|---|
| 权威文档与元数据结构 | `python3 tools/validate_workflow_metadata.py --root .` | 通过 | `/root` | PASS |
| 剧情图与生成数据 | `python3 tools/validate_story_data.py --root .`（如存在）及现有同步检查 | 无重复 ID、无失效去向、无玩家知识越界 | qa | 未执行 |
| 现有 v6 回归 | Godot headless 跑 README 测试集（21 项） | 已知测试分类清晰，新增行为通过 | qa | PASS（21/21） |
| Demo 正常路径 | `tests/test_full_flow.gd` + C22 reachability | 从调查目标到 C22 完整可达 | playtest / qa | PASS |
| Demo 负向路径 | `tests/test_writing_evidence_conditions.gd`、`tests/test_writing_copy_variants.gd`、既有回退/三路线测试 | 不提前写入知识；强弱位置、药盒来源和离岗主体按记录收窄 | qa | PASS |
| C18/C21/C22 | 写稿、C22 hook 与 C22 branch tests | 玩家句子、来源依据、编辑反馈、名单钩子实际可见 | programmer / qa | PASS |
| 工作簿同步 | `tests/test_workbook_sync.gd` | CSV 由入口工作簿生成，入口与镜像一致 | qa | PASS |

- 必测正常路径：S00 → 调查目标 → S01/S02 → C04 → 一次有目的观察 → C08–C11 → 一条有来源写稿 → C21 → C22。
- 必测负向 / 边界路径：跳过调查目标、三种函件准备、公开范围不同、弱证据收窄措辞、C22 回退/重进、章节结束后不可重复推进。
- 独立 QA 是否必须：`是`
- 允许存在的已知失败：缺失沈砚舟立绘资源的既有测试失败须单独报告，不得用本任务掩盖。

## 9. 停止与阻塞条件

- 必须暂停写入的条件：岗位发现 v6 权威冲突；具体“待核说法”无法由现有材料确定；需要新增事实/主角动词；工作簿与生成链无法建立回滚；C22 结尾与现有已确认分支冲突。
- 当前阻塞：无运行阻塞；C18 生成数据中的位置强弱条件、药盒强/窄文案与离岗主体仍保留历史入口口径，运行层已按 v6 证据筛选和稿面派生文本收窄，未手改生成 CSV 或工作簿。C21 长稿件正文使用可滚动出版卡，见报后果单独呈现。
- 解除阻塞所需的最小用户决定或外部条件：若 D01/D02 对“目标说法”或公开范围出现冲突，集中提交一个具体选项供确认。
- 不受阻塞、仍可继续的工作：文档记录、实现缺口审计、测试设计、现有 C22/C18 问题复现。

## 10. 交付记录

- 实际修改文件（本轮）：`docs/AI_TASK_20260923_DEMO_INFO_FLOW.md`、`docs/DEMO_ROUTE_PROPOSAL_20260923.md`（待确认提案）、`docs/DECISIONS.md`、`docs/CURRENT_TRUTH.md`、`README.md`、`scripts/main.gd`、`tests/test_investigation_prompt.gd`、`tests/test_writing_panel.gd`、`tests/test_writing_evidence_conditions.gd`、`tests/test_writing_copy_variants.gd`、`tests/test_publication_text_separation.gd`、`tests/test_c22_hook_reachability.gd`、`tests/test_c22_branch_reachability.gd`。
- 各岗位报告：narrative / continuity / commercial_reviewer / playtest / programmer / 独立 qa 已回报；独立 qa 初审提出药盒强弱、离岗主体与稿面可见性缺口，修复后由只读复核与 21 项回归重新验证；dialogue 未改作者台词，本轮不单独变更对白。
- 合并后的结论：开场旧报页已显出待核问题；C18 已完成“判断→来源→派生稿句→写稿”交互，C19 显示稿面第二段，C21 显示实际稿件正文且不混入场景后果；C22 编辑反馈与名单后果可达；完整第一章顺序未改。
- 未解决冲突：生成工作簿的 C18_011/C18_011B 条件及 C18 药盒/离岗画面表现仍保留历史入口口径，运行层按 v6 证据和主体派生文本覆盖显示；完整独立精选 Demo 路线、谁知情 UI 和第二章场次仍未正式编排。
- 待确认事项：是否采用 `docs/DEMO_ROUTE_PROPOSAL_20260923.md` 的五段精选路线；是否把运行层已验证的 C18 条件、药盒强/窄句与离岗主体句回写入口工作簿并重新生成 CSV；这会影响正式剧情数据，当前不静默写入。
- 验证命令与结果：`python3 tools/validate_workflow_metadata.py --root .` PASS；README Godot 测试集 21/21 PASS；`git diff --check` PASS；`tests/test_writing_evidence_conditions.gd`、`tests/test_writing_copy_variants.gd`、`tests/test_publication_text_separation.gd`、`tests/test_c22_branch_reachability.gd` PASS。
- 失败分类：初始 C18/C22/调查提示红测均在实现前按预期失败，修复后通过；未隐藏既有立绘资源缺失类历史问题。
- 最终状态：`REVIEW`
