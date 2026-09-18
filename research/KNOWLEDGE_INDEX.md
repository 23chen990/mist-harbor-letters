# 《雾港来信》可复用知识索引

> 本文件只登记研究、工作经验、审查快照和制作记录的元数据，不复制正文，也不是剧情事实源。正式设定仍严格遵循 `AGENTS.md` 的权威顺序。

## 使用规则

- 先按 `scope` 查找已有资产；只有现有内容不覆盖任务、存在冲突、进入 `refresh_trigger` 所列节点，或用户明确要求最新研究时，才重新调研。
- `active` 只表示资产可供当前工作参考，不表示结论已被项目采用。
- `needs_revalidation` 可用于历史定位和问题线索，不得用于声称当前状态。
- `pending_confirmation` 、`working_only` 与 `working_context_only` 不得写入正式剧情、机制、商业策略或 `CURRENT_TRUTH.md`。
- 已被否定或失效的经验仍保留追溯，复用时必须保留其负向状态，不得摘成正向规则。
- 本索引的结构可用 `python3 tools/validate_workflow_metadata.py --root .` 只读校验。

## RES-20260830-01
- path: `research/COMPETITOR_INDEX.md`
- asset_type: research_index
- authority: non_authoritative_research
- lifecycle_status: active
- formal_use: advisory_only
- scope: 全球与中国市场竞品的来源导航、参考维度和不适合照搬项
- source_basis: 官方页面、开发者资料与采访；已验证只表示公开机制可核验
- as_of: 2026-08-30
- last_reviewed: 2026-08-30
- valid_against: 当前竞品索引与来源链接
- decision_refs: —
- reuse_conditions: 只用于选择调研对象和形成建议；不等于本项目已采用
- refresh_trigger: 链接失效、公开机制变化、新增核心机制或进入 Demo、商店页、Trailer、定价、发行节点
- unresolved_conflicts: 无
- tags: competitor, source-navigation, design, commercial

## PAT-20260830-01
- path: `research/DESIGN_PATTERNS.md`
- asset_type: design_pattern
- authority: non_authoritative_research
- lifecycle_status: active
- formal_use: advisory_only
- scope: 推理、信息释放、选择、写稿盘、对白和 Demo 体验的已验证设计模式
- source_basis: 竞品公开机制、开发资料与项目工作经验
- as_of: 2026-08-30
- last_reviewed: 2026-08-30
- valid_against: 当前模式表和其来源、失败方式、适用范围
- decision_refs: —
- reuse_conditions: 可用于评审维度和提案；没有关联已确认决策时不得当作正式机制
- refresh_trigger: 现有模式无法解释新问题、模式间冲突、新核心机制或玩家测试否定现有假设
- unresolved_conflicts: 无
- tags: patterns, inference, interaction, dialogue, demo

## COM-20260830-01
- path: `research/COMMERCIAL_STRATEGY.md`
- asset_type: commercial_hypothesis
- authority: non_authoritative_research
- lifecycle_status: active
- formal_use: advisory_only
- scope: Steam 买断前提下的 Demo Hook、差异化、商店表达、传播和验证假设
- source_basis: 当期竞品公开信息与项目商业评审假设
- as_of: 2026-08-30
- last_reviewed: 2026-08-30
- valid_against: 2026-08-30 商业研究快照
- decision_refs: —
- reuse_conditions: 只用于形成待验证商业建议；不得自动改写剧情或已确认机制
- refresh_trigger: 首次进入或重大改版 Demo、准备对外发布，进入商店页、Trailer、定价、发行节点，或市场与平台信息可能变化；日常技术试玩检查不单独触发重新研究
- unresolved_conflicts: 无
- tags: commercial, steam, positioning, hypothesis

## LES-20260830-01
- path: `drafts/WORKING_LESSONS.md`
- asset_type: working_lesson
- authority: working_only
- lifecycle_status: pending_confirmation
- formal_use: working_context_only
- scope: 用户反馈、自审结论、已验证经验及被否定尝试的追溯账本
- source_basis: 工作轮次、用户反馈和对应草案版本
- as_of: 2026-08-30
- last_reviewed: 2026-08-30
- valid_against: 当前经验簿的单条状态与对应草案
- decision_refs: —
- reuse_conditions: 必须逐条保留来源、状态和适用版本；B-001 与 B-008 不得摘成当前正向规则
- refresh_trigger: 同类反馈再次出现、用户确认长期规则、对应交互或草案已更换
- unresolved_conflicts: 无
- tags: lessons, feedback, rejected-attempts, working-memory

## WRS-20260830-01
- path: `drafts/对话诈术与信息差选择_竞品研究_20260830.md`
- asset_type: working_research
- authority: working_only
- lifecycle_status: active
- formal_use: working_context_only
- scope: 对话诈术、信息差与玩家主动操纵信息的专项竞品研究
- source_basis: 2026-08-30 专项研究与来源记录
- as_of: 2026-08-30
- last_reviewed: 2026-08-30
- valid_against: 对应专项文档当时的研究对象和问题
- decision_refs: —
- reuse_conditions: 仅在同类对白选择问题中作为提案依据；不构成本项目规则
- refresh_trigger: 对白核心交互变更、新玩家测试否定现有假设或新增直接竞品
- unresolved_conflicts: 无
- tags: dialogue, bluffing, information-gap, working-research

## WRS-20260830-02
- path: `drafts/序章与第一章_选择策略盘点_v1.md`
- asset_type: working_research
- authority: working_only
- lifecycle_status: needs_revalidation
- formal_use: working_context_only
- scope: 序章与第一章选择策略的特定版本盘点
- source_basis: v1 盘点时的场次、选项与信息结构
- as_of: 2026-08-30
- last_reviewed: 2026-08-30
- valid_against: 仅对应盘点时的序章和第一章工作版本
- decision_refs: —
- reuse_conditions: 只可当作历史问题清单；引用前必须与当前 v6 权威文件重新对照
- refresh_trigger: 再次审查序章或第一章选择结构
- unresolved_conflicts: 无
- tags: choice-audit, prologue, chapter-one, version-snapshot

## AUD-20260830-01
- path: `drafts/PROLOGUE_CH01_AUDIT_v2.md`
- asset_type: review_snapshot
- authority: working_only
- lifecycle_status: needs_revalidation
- formal_use: working_context_only
- scope: 序章和第一章当时版本的审查快照；v2 作为本组记录头部
- source_basis: 当时可用文档与实现的局部审查
- as_of: 2026-08-30
- last_reviewed: 2026-08-30
- valid_against: 仅对应该审查当时的输入版本
- decision_refs: —
- reuse_conditions: 只用于追溯历史问题；其“剧情树缺失”等状态已过期，不得当作当前结论
- refresh_trigger: 任何新的序章或第一章正式审查
- unresolved_conflicts: 文档内的部分文件存在性判断已与当前仓库状态不符
- tags: audit, prologue, chapter-one, stale-snapshot

## DRAFT-20260830-01
- path: `drafts/序章与第一章_工作草案_v14.md`
- asset_type: narrative_draft_series
- authority: working_only
- lifecycle_status: pending_confirmation
- formal_use: working_context_only
- scope: 序章与第一章工作草案 v1—v14 版本系列，v14 仅是系列 head
- source_basis: 连续工作草案与用户反馈；不是正式剧情母版
- as_of: 2026-08-30
- last_reviewed: 2026-08-30
- valid_against: v14 文件自述范围；旧版只供追溯
- decision_refs: —
- reuse_conditions: 必须与 v6 权威文件和已确认决策逐项核对；v1—v13 不得越过 v14 回流
- refresh_trigger: 用户确认新正式修订、新增工作草案或正式母版同步
- unresolved_conflicts: v7 与 v8—v14 对死亡口径的决策号引用不一致；不自动纠正
- tags: narrative-draft, version-series, pending-confirmation

## AUDIT-20260829-01
- path: `docs/WORKFLOW_AUDIT.md`
- asset_type: process_audit
- authority: process_record
- lifecycle_status: needs_revalidation
- formal_use: process_only
- scope: 2026-08-29 的仓库数据源、工具链、旧版残留和测试状态快照
- source_basis: 当日全仓库只读审计
- as_of: 2026-08-29
- last_reviewed: 2026-08-30
- valid_against: 只对应 2026-08-29 审计时的仓库状态
- decision_refs: —
- reuse_conditions: 可复用字段设计和历史风险线索；不得用它声称当前文件、行数、决策日志或测试状态
- refresh_trigger: 需要引用其任何“当前状态”结论时必须重新运行对应检查
- unresolved_conflicts: 文档仍声称剧情树未收录、DECISIONS 为空等已过期状态
- tags: workflow, audit, historical-snapshot, needs-revalidation

## LOG-20260830-01
- path: `docs/CHARACTER_VISUAL_REVIEW_LOG.md`
- asset_type: production_log
- authority: process_record
- lifecycle_status: active
- formal_use: process_only
- scope: 角色标准板审查、评分、文件哈希、候选与定稿的制作追溯
- source_basis: 本地视觉资产、审查记录和已登记决策
- as_of: 2026-08-30
- last_reviewed: 2026-08-30
- valid_against: 当前视觉评审日志中所列文件与哈希
- decision_refs: —
- reuse_conditions: 仅用于美术制作状态和审查追溯；其中视觉判断不是剧情事实
- refresh_trigger: 候选图、定稿状态、评分、角色风格基准或文件哈希变化
- unresolved_conflicts: 无
- tags: art, production, review-log, hashes
