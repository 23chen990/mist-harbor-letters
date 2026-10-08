# 外部方法来源与适配边界

本文件只记录方法来源、适用范围和本项目的适配边界。任何链接、示例或外部结论都不能覆盖 `AGENTS.md` 与 v6 权威文件。

## choice-narrative-studio

- 来源：用户提供的 `/Users/kker/Downloads/skill-2.zip`，其中的 `choice-narrative-studio/SKILL.md` 与 `references/`。
- 可复用：玩家意图与行动链、删除优先的对白编辑、实际路径决策密度、状态/知情分离、逐屏演出契约、资源状态与验证状态分开。
- 本项目适配：把它作为叙事审计方法；项目 preset、示例人物、恋爱/周目假设、JSON 样例和浏览器预览不属于《雾港来信》事实。

## godot-dialogue-system

- 来源：[thedivergentai/GD-Agentic-Skills](https://github.com/thedivergentai/GD-Agentic-Skills/blob/main/skills/godot-dialogue-system/SKILL.md)。
- 可复用：数据驱动对白、有效去向 ID、条件选择、状态不放在 UI、跳过文本不重复副作用、信号/事件桥接、单一运行引擎。
- 本项目适配：审计现有工作簿→CSV→`story_repository.gd` / `game_state.gd` 链；不因为来源推荐 Resource/JSON/Ink/Yarn 就迁移格式。

## story-skills

- 来源：[story-maintenance](https://www.skills.sh/danjdewhurst/story-skills/story-maintenance) 与 [revision-continuity](https://www.skills.sh/danjdewhurst/story-skills/revision-continuity)。
- 可复用：连续性、时间线、问题/承诺、线索、人物知识和定向修订的 ledger 检查。
- 本项目适配：输出只读清单，读取 v6 文档、工作簿和运行数据；不把项目转换成 `story.md`，不把 CLI 检查结果当作者层真相。

## godot-gdscript-patterns

- 来源：[wshobson/agents 的 Godot GDScript patterns](https://www.skills.sh/wshobson/agents/godot-gdscript-patterns)。
- 可复用：单一状态所有者、Autoload/Resource 边界、信号、类型与数据校验、保存/场景切换/性能审查。
- 本项目适配：只在已批准的 Godot 实现任务中使用；保持生成 CSV 不手改，保持 v6 与 R16.2 入口隔离。

## generic-game-narrative

- 来源：[dialogue-systems](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/dialogue-systems) 与 [visual-novel](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/visual-novel)。
- 可复用：把节点、选择、条件、变量和演出当作不同层，比较 Ink/Yarn/自定义数据驱动方案。
- 本项目适配：仅作架构对照；不自动加入回看、自动播放、自由输入、存档或其他未确认机制。

## playtest-legibility

- 来源：[gating-intent-legibility](https://github.com/abagames/agentic-gamedev-skills/blob/main/.agents/skills/gating-intent-legibility/SKILL.md)。
- 可复用：用首次玩家视角检查目标、选项、风险和反馈是否可读；区分观察、推断和修改建议。
- 本项目适配：只有存在可运行构建与可复现路径，或已经建立录帧、确定性重放和状态指纹时，才报告测试结论；否则只写待验证假设。

## 不纳入本 skill 的来源

面向自由文本 LLM 互动小说、通用 Claude 编排团队、低采用率的泛游戏设计包和大型 Godot skill 集合不作为默认依赖。它们可能提供局部启发，但会重复当前项目的调度/审批体系，或引入与当前确定性调查流程不相容的机制。
