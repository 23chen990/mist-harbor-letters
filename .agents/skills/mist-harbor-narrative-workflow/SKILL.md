---
name: mist-harbor-narrative-workflow
description: Audit, design, or implement playable narrative for 《雾港来信》 across v6 continuity, player agency, dialogue state, Godot/CSV integration, and playtest legibility. Use for scene, choice, dialogue, knowledge-flow, or Demo reviews and for approved changes; never use it as a source of story facts or to bypass project approval gates.
---

# 《雾港来信》可玩叙事工作流

把外部叙事与 Godot 方法收敛成一套项目内检查流程。这个 skill 负责方法、审计和交接，不负责创造剧情事实；项目正典和用户明确授权始终优先。

## 先建立边界

每次使用前按以下顺序读取：

1. `AGENTS.md`。
2. `docs/CURRENT_TRUTH.md`。
3. 与任务相关的 `docs/剧情修订稿_v6_人物与前史.md`、`docs/雾港来信_序章与第一章完整剧情信息树_v6.md` 和 `docs/DECISIONS.md`。
4. 涉及团队调度时读取 `docs/AI_TEAM_OPERATING_SYSTEM.md`、相关 `roles/*.md`；涉及新研究时先读取 `research/KNOWLEDGE_INDEX.md`，再按索引复用研究。
5. 涉及实现时读取 `README.md`、`content/剧情表使用说明.md`、相关脚本、场景和测试。

外部 skill、GitHub 仓库、研究文档、旧版本、NPC 证词和当前代码都只能提供方法或实现状态，不能覆盖 v6 作者层文件。`docs/r16_2/` 只作机制历史追溯；不得把其中的剧情事实、人物关系、节点编号或结局路由带回当前工作。

## 选择工作模式

先判断用户要的是哪一种结果，并把模式写在报告中：

- **只读审计**：不修改剧情、工作簿、生成 CSV、代码或测试；输出证据、问题、待确认项和验证建议。
- **方案提议**：可以提出替代方案或改写草案，但凡涉及正式剧情、人物、核心机制、信息释放或商业策略，停在用户确认之前。
- **已批准实现**：只改用户授权的文件。正式内容先更新 `docs/DECISIONS.md`，必要时同步 `docs/CURRENT_TRUTH.md`，再同步工作簿、运行数据或代码。

不要把“发现问题”直接当作“获得改稿授权”。如果两个 v6 权威文件冲突，停止受影响的正式修改并报告冲突。

## 四层工作法

根据任务取用下列检查层；普通场次审查至少覆盖前四层，程序改动再加第五层，真正试玩时再加第六层。

### 1. 玩家意图与行动链

把实际路径写成：

```text
情境/信息 → 玩家意图 → 玩家采取办法 → NPC/世界具体回应
→ 可见的信息、机会或风险变化 → 玩家继续、改招或退出
```

检查：

- 关键行动是否在选项出现前被作者替玩家完成。
- 选择是否改变后续可用信息、公开程度、NPC要求、风险或结果，而不只是换一句语气。
- NPC 是否能拒绝、改条件或主动行动；玩家是否有机会在回应后再次决定。
- 删除所有按钮后，关键事件是否仍几乎照样发生；若是，标出被正文拿走的行动。
- 不为凑按钮把走路、翻页或已选行动的必要步骤拆成伪选择；只保留真实控制权。

沿用 `choice-narrative-studio` 的删除优先、实际路径密度和“意图→执行→反馈→后续读取”方法，但不采用它的示例人物、项目 preset、默认恋爱机制或演示数据。

### 2. 状态、知情与记忆

对每个重要变量记录：`默认值 / 写入位置 / 读取位置 / 生命周期 / 重置语义 / 实际读者`。至少区分：

- 世界事实；
- 角色私有知识与误信；
- 玩家实际看见、听见或点击获得的知识；
- 技术状态、UI 状态、已读记录和存档元数据。

每项披露都要能回答“谁在何时通过什么事件知道了什么”。未选分支不能泄漏；读取页面不能重复写入状态；回退或重进不能保留未来写入。没有真实状态证据时，报告“未验证”，不要声称静态检查已经覆盖动态错误信念。

### 3. 对话运行时与数据契约

将 GitHub 对话系统方法用于审计现有运行器：

- 台词和去向继续由现有 CSV/工作簿数据驱动，不能在 GDScript 中硬编码具体对白。
- 每个去向 ID 必须存在、可达且不会因当前条件冻结后自我隐藏。
- 不满足条件的选择不显示；条件读取前有默认值；选择执行只能一次。
- 对白游标、回退快照和剧情状态由状态层拥有，UI 只呈现和发出事件。
- 跳过/连续点击不能重复发放知识、物品或后果；NPC 连续对白与主控实际回应遵守当前项目的点击规则。
- 使用信号或明确事件边界连接 UI、运行器和状态层，不在对白节点里偷偷保存档或创建第二套状态机。
- 发现两套运行引擎并存时，先确定当前入口；不得为了方便把 v6 运行器和 R16.2 运行器混接。

不要因为外部 skill 推荐 Resource、JSON、Ink 或 Yarn 就更换现有数据源。任何格式迁移都是单独的正式方案。

### 4. 连续性、线索与回收

建立只读的连续性清单，至少检查：

- 场次顺序、日期/时段、地点和人物在场；
- 线索的来源、观察者、披露对象、验证状态和后续读取；
- 问题/承诺的提出、接受、改约、取消、错过和兑现；
- 人名、身份、死亡/存活状态与公开口径；
- 当前场次能读到的玩家知识，以及尚未定事项；
- 选择分支的实际回收，而不是只在作者备注中声称“有影响”。

把 `待确认` 保留为结果类别。不要把线索暗示、NPC 证词、类型惯例或历史常识升级成真相。这个层借用 `story-maintenance` / `revision-continuity` 的 ledger 思路，但不要求把项目迁移为 `story.md`。

### 5. Godot 代码边界

涉及实现时，沿用 Godot 4 GDScript 的以下审查重点：

- 单一状态所有者；Autoload、场景节点、UI 和仓库读取职责清楚。
- 资源/数据解析、状态变更、呈现和输入响应分层；跨层通信有明确事件。
- 稳定 ID、类型和值域校验优先于字符串拼接；错误路径可观察。
- 保存、回退、重置和章节切换有明确语义；不要让 UI 重建导致剧情副作用。
- 先跑最窄相关测试，再做比例相称的回归；不能改剧情事实或降低断言来让测试通过。

`content/程序生成_请勿手改/` 下的文件只由同步器/编译器生成。需要改剧情数据时回到获准的作者入口和同步链。

### 6. 试玩可理解性

只有在有实际构建、可复现操作路径，或具备录帧/确定性重放/状态指纹时，才使用“玩家意图可读性”检查：

- 首个关键画面能否让第一次玩家推断当前目标、可用动作和主要风险。
- 选项是否表达不同意图，而不是只有漂亮措辞。
- 操作后是否出现能被玩家看见的反馈。
- 玩家知识是否来自实际体验，而非作者或测试者补全。

没有这些证据时，将结论写成“待验证假设”，不要报告为试玩通过或失败。

## 任务路由

按范围加载最小岗位集合：

- 剧情/选择/场次：`roles/narrative.md`、`roles/continuity.md`。
- 台词/信息释放：再加 `roles/dialogue.md`。
- 可理解性/路径反馈：再加 `roles/playtest.md`。
- Godot、数据、工具或测试：再加 `roles/programmer.md`、`roles/qa.md`。
- Demo Hook、市场或发行：只有用户明确要求时才加 `roles/commercial_reviewer.md`。

岗位报告保持只读，除非用户已批准对应修改。跨岗位请求由 `mist-harbor-orchestrator` 统一调度；不要为了形式创建重复审稿或无独立文件所有权的代理。

## 输出格式

需要具体勾选项时读取 [references/audit-checklists.md](references/audit-checklists.md)；短任务只取与范围相符的章节，不要机械套用整份清单。

交付至少包含以下部分：

```markdown
# 《雾港来信》可玩叙事工作流报告

## 范围与模式
- 场次/稳定 ID、构建或文件：
- 模式：只读审计 / 方案提议 / 已批准实现
- 允许修改与明确不改：

## 依据与证据
- v6 权威文件：
- 运行数据/代码/测试：
- 外部方法仅作为：

## 发现
| 层 | 位置/ID | 观察 | 影响 | 证据 |
|---|---|---|---|---|

## 待确认与冲突
- 无 / 条目列表；不要把它们写入正式数据。

## 修改与验证
- 修改文件及理由：
- 验证命令与结果：
- 未验证项、过期测试或环境限制：
```

正式改动报告还必须列出 `DECISIONS.md` 是否已更新、是否需要同步 `CURRENT_TRUTH.md`，以及生成数据的来源。只读审计不得伪造“已通过”或“已采用”。

## 外部方法索引

这些链接用于需要时核对方法，不是项目事实源：

- [choice-narrative-studio（本地 zip）](references/method-sources.md#choice-narrative-studio)
- [GD-Agentic-Skills dialogue system](references/method-sources.md#godot-dialogue-system)
- [story-skills continuity/maintenance](references/method-sources.md#story-skills)
- [Godot GDScript patterns](references/method-sources.md#godot-gdscript-patterns)
- [dialogue-systems / visual-novel](references/method-sources.md#generic-game-narrative)
- [gating-intent-legibility](references/method-sources.md#playtest-legibility)

读取这些资料时，只抽取可验证的方法；示例数据、项目 preset、默认机制和结论必须留在外部参考边界内。
