# GitHub 旧工程审计｜baseline-20260919

## 基线状态

仓库：https://github.com/23chen990/mist-harbor-letters  
默认分支：`main`  
tag：`baseline-20260919`  
commit：`a920ebffff051bc005080bda536ceeda9966fe92`

通过 GitHub compare 已确认：

- `main` 与 `baseline-20260919` **identical**
- ahead = 0
- behind = 0
- total commits difference = 0

所以当前 GitHub 就是用户截图里所说的“旧 Agent 正式基线”，没有基线之后的额外开发需要合并。

最新 commit：
`ci: 增加元数据/结构校验门禁（AGENTS.md §8）`

## 旧 Agent 已经做好的工程能力

### 1. 单一工作簿 → CSV 运行数据
当前作者入口：
`outputs/01a037d8-c4f0-70d3-bc69-8c3819094801/雾港来信_剧情作者工作簿.xlsx`

同步链：
`tools/xlsx_story_importer.gd`
→ `content/程序生成_请勿手改/剧情剧本.csv`
→ `scripts/story_repository.gd`

优点：
- 有稳定 ID 校验
- 有 CSV 生成前校验
- generated 目录明确禁止手改

限制：
- 只读取 `剧情剧本` sheet
- 固定 21 列
- 不能直接消费 R16.2 的 Nodes/Choices/StateDictionary 等多 sheet 结构

结论：
**同步/验证思想可复用，旧 schema 不可直接复用。**

### 2. 世界事实 / 玩家知识分离
`scripts/game_state.gd` 已经有：
- `world_truths`
- `player_knowledge`
- technical/narrative values
- choice history
- `create_snapshot()`
- `restore_snapshot()`

这是很好的基础。

R16.2 应在此思想上扩展：
- typed state
- story/global rollback scope
- enum/set
- article lifecycle
- permissions/promises
- global scrapbook/endings

不要推倒重写成简单 bool 堆。

### 3. 选择前 checkpoint / 返回上一选择
`scripts/main.gd` 已有：
- `_store_choice_checkpoint()`
- `return_to_previous_choice()`
- `state.create_snapshot()/restore_snapshot()`

这个机制值得保留。

但 R16.2 必须补：
- story/global 分层
- U15 puzzle snapshot
- U28 preview snapshot
- U32 shared final snapshot

### 4. 手动推进与玩家实际回应 UI
旧 Agent 已处理：
- NPC 一句一句显示
- 玩家自己的话用按钮实际点击
- 单一必要回应也可以让玩家主动点击
- 静置不自动推进
- 不把技术占位文字显示给玩家

这与 R16.2 的沉浸目标一致，应复用。

### 5. 场景探索 / 热点 / 材料查看
`main.gd` 已存在：
- scene exploration
- clue inspection
- 工作桌热点
- 物件查看层

R16.2 可以复用 UI 能力，但不要把旧序章内容保留下来。

### 6. Debug 与测试基础
已有：
- 作者 Debug
- choice history
- 知识/状态显示
- chapter test selector
- 大量 GDScript tests
- Python workflow tests

工程质量基础很好。

### 7. 独立 story_interaction_lab 原型
`prototypes/story_interaction_lab/` 已经有：
- JSON node graph
- choices / next / next_rules
- conditions
- evidence
- report claim selection
- consequence
- 独立 state

这个原型的**节点图/条件/choice runner 思想**比旧 21 列 Topic/Stage 更接近 R16.2。

可以参考甚至抽取通用代码，但：
- 原型正文是旧 v6
- interaction_state 有大量旧剧情专用字段
- 不得把旧剧情逻辑升级为 R16.2 真相

## 旧工程当前剧情范围

README 明确写的是：

- v6 垂直切片
- 序章 + 第一章
- C01–C22
- 当前入口只提供第一章
- 第二、三章旧数据停用

所以 Agent 不应误以为仓库已经有“完整游戏”只差换文本。

## CI 状态

当前 `.github/workflows/ci.yml`：
- 已开启 metadata/structure 校验
- Godot headless 回归仍是注释模板
- 模板写的是 Godot 4.3

而 `project.godot` 实际：
`config/features=PackedStringArray("4.7")`

R16.2 接入时应把 CI headless 版本统一到 **Godot 4.7** 后再启用运行时回归。

## 旧测试怎么处理

### 建议保留/迁移
- `test_game_state.gd`
- `test_choice_backtracking.gd`
- `test_manual_line_advance.gd`
- `test_player_response_ui.gd`
- `test_chapter_switching.gd`
- 工作流/元数据测试思想

### 需要改写为 R16.2
- `test_full_flow.gd`
- `test_story_content.gd`
- `test_workbook_sync.gd`
- opening / prelude / secret release / continuous scene 等内容断言
- v6 migration / v343 等历史内容测试

旧内容测试失败时：
**先判断是否“旧剧情断言已过期”，不能为了过旧测试把 R16.2 改回旧故事。**
