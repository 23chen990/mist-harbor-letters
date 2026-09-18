# AI 任务包｜序章 4/4 收束与末句同屏选项

> 文档性质：执行范围与调度记录，不是剧情事实源、机制事实源或商业结论。

## 1. 基本信息

- 任务 ID：`AI-TASK-20260831-PRELUDE-TRANSITION-TIMING`
- 用户确认：`图1点完所有，就应该展示主控的对话。还有，说完最后一句话的时候就应该右边展示选项，而不是点击下一步再展示`
- 执行档位：`formal`
- 当前状态：`COMPLETE`

## 2. 唯一目标与验收

- 四项工作桌热点全部完成后，不显示“去春和戏院”按钮，直接进入 `前序·证据收束` 并显示沈砚舟第一条收束对白。
- `前序·决定见面` 仍逐句推进：“先去春和。”之后由玩家主动点出最后一句“末版十一点半。”；最后一句出现时，右侧同时显示 `前序·准备出发` 的三个函件处理选项，不再显示额外“继续”。
- 选择任一同屏选项后，原有状态写入与 `前序·出发` 去向不变。

## 3. 权威、影响与边界

- 权威依据：`docs/CURRENT_TRUTH.md`、两份 v6 权威文档、`DEC-20260831-28` 与本轮用户明确确认。
- 已确认影响：Demo 交互时点、P0013/P0018 演出说明、通用对话运行器与测试。
- 不改变：四项线索内容、P0016—P0018 台词、三个函件选项文本/条件/结果、玩家知识与剧情事实。
- 禁止：手工修改生成 CSV、自动播放对白、跳过沈砚舟收束台词、把自动离场记录成玩家说出口的话。
- 当前权威冲突：无。v6 已存在 P0016—P0018 收束链；本轮只移除两个多余点击。

## 4. 岗位与 owner

- `dialogue` / `continuity`：只读核对句序、知识与选项结果。
- `playtest`：验证交互反馈连续，无空房间与空选项页。
- `programmer`：`scripts/main.gd` 与行为测试唯一 owner。
- `qa`：定向与全量回归，只验证不修稿。
- 主 Codex：决策、CURRENT_TRUTH、v6 剧情树、工作簿与任务包 owner。

## 5. 允许修改

- `docs/DECISIONS.md`、`docs/CURRENT_TRUTH.md`、v6 序章剧情树、README/剧情表使用说明、本任务包。
- 两份当前剧情作者工作簿中 P0013/P0018 的演出说明及直接相关备注；由同步器生成 CSV。
- `scripts/main.gd`、`tests/test_prelude_transition_timing.gd`、直接过期的序章流程测试。

## 6. 验证计划

- 新测试先 RED：当前 4/4 停在房间按钮；P0018 最后一句仍显示“继续”且没有三个选项。
- GREEN：4/4 自动进入 P0016；P0018 末句与三个右侧选项同屏；选择后状态/去向正确。
- 回归：逐句推进、序章自由探索、工作簿同步、S00、第一章核心内容、完整 Godot 测试、工作流元数据、项目加载。
- 已知基线：5 项旧序章/v2.7 测试可能继续失败，必须与本轮真实回归分开。

## 7. 交付记录

- 实际修改文件：`docs/DECISIONS.md`、`docs/CURRENT_TRUTH.md`、v6 序章剧情树、`README.md`、`content/剧情表使用说明.md`、两份当前剧情作者工作簿、同步生成的 `content/程序生成_请勿手改/剧情剧本.csv`、`scripts/main.gd`、`tests/test_prelude_transition_timing.gd`、`tests/test_prelude_free_exploration.gd`、`tests/test_workbook_sync.gd` 与本任务包。
- 定向验证：序章时点、自由探索、逐句推进、工作簿同步、S00、回函搜寻与剧情内容共 7 项全部通过。
- 全量 GDScript：19 项中 14 项通过；`test_chapter_switching.gd`、`test_choice_backtracking.gd`、`test_full_flow.gd`、`test_opening_demo_logic.gd`、`test_v27_story_content.gd` 继续因已废止的 v5／父亲旧宅／旧流程假设失败，与修改前基线一致，不是本轮回归。
- 其余验证：13 项工作流 Python 单测、赵敬文公开死亡口径检查、工作流元数据校验与 Godot 项目加载均通过。
- 未解决冲突：本轮正式范围内无；工作簿其他作者工作表仍有已登记的旧口径，未在本任务中扩写清理。
- 最终状态：`COMPLETE`
