# R16.2 工程迁移方案

## 总原则

**复用旧工程能力，不复用旧剧情 schema。**

R16.2 不应该硬塞回旧 `剧情剧本.csv` 21 列模型，也不要把 66 个 Choice 和状态机直接硬编码到 `main.gd`。

## 推荐的新数据流

```text
source/R16.2 程序接入表.xlsx
        ↓ deterministic compiler
content/程序生成_请勿手改/r16_2_runtime.json
        ↓
R16.2 Runtime / State Store / UI
```

编译器可以使用：
- Python（推荐用于开发期）
- 或扩展 Godot XLSX 解析器

但运行时不要直接解析 Excel。

## runtime.json 建议结构

```json
{
  "meta": {},
  "nodes": {},
  "choices": {},
  "states": {},
  "snapshots": {},
  "puzzles": {},
  "article_rules": [],
  "endings": [],
  "chapters": [],
  "ui_interactions": {},
  "newspaper_spec": {},
  "notebook_spec": {},
  "montage_rules": []
}
```

## 现有代码复用建议

### `scripts/game_state.gd`
保留思想：
- world_truths
- player_knowledge
- snapshot

重构目标：
- 通用 `state: Dictionary`
- 状态类型校验 bool/enum/set/string/int
- rollback scope: story/global
- atomic mutation
- permissions/promises/knowledge/article lifecycle

### `scripts/story_repository.gd`
旧版：
- 按“对话阶段”分组 CSV

R16.2：
- 建议新增独立 repository/runtime，不要求立即删除旧类
- NodeID/ChoiceID 为主键
- 条件运行前校验
- unknown condition = error

### `scripts/main.gd`
保留：
- Control UI 基础
- 手动推进
- response button
- checkpoint
- debug shell

移出：
- 剧情专用硬编码
- 旧章节固定入口
- 旧 Topic/Stage 特例

建议分离：
- `story_runtime.gd`
- `condition_evaluator.gd`
- `state_store.gd`
- `article_builder.gd`
- `special_interaction_controller.gd`

文件名可调整，职责不要重新揉回 main.gd。

### `tools/xlsx_story_importer.gd`
不直接拿来读 R16.2。
它可以作为：
- XLSX XML 解析参考
- ID/数据校验参考

## 特殊交互实现边界

### U08 标题
最多：
1. 看两张完整卡
2. 选一张
3. 点送排

不要拼标题。

### U15-B 药物链
5 卡排序。
错了：
- 不扣体力
- 不看广告
- 只提示冲突相邻卡

### U27 核稿
3 句里选 1 句不可直接刊。
错误：
- 跳回对应采访记录
- 不直接公布答案

### U28
1. 三张稿件卡选一
2. 后台自动组稿
3. 显示完整报纸
4. 确认交排

不要给逐条编辑器。

## 报纸状态生命周期

必须严格保持：

`main_locked`
→ `auto_build`
→ `preview`
→ `typeset_confirmed`
→ `actual_published`
→ `delivered`
→ `read`

角色不能在 read 之前对报纸内容作反应。

## 回溯

- 普通选择：选择前 snapshot
- D15-B：SS_U15_CHAIN
- D65-C：SS_U28_PREVIEW
- U32：SS_U32_FINAL

story scope 恢复。
global scope 不恢复：
- seen branches
- unlocked endings
- scrapbook
- chapter completion

## 不要做

- 不要让代码解析玩家可见中文描述来决定逻辑
- 不要 eval 任意 DSL 字符串
- 按 `ConditionDSL` 映射成白名单操作
- unknown key / unknown enum 应在 dev build 直接报错
