# 仓库文件修改地图

## 必改

### `AGENTS.md`
把 R16.2 加入正式权威顺序。
旧 v6 降历史资料。

### `docs/CURRENT_TRUTH.md`
重写为 R16.2 当前真相，或归档旧文件并建立 `CURRENT_TRUTH_R16_2.md`。

### `docs/DECISIONS.md`
登记 R16.2 canon switch / product switch / runtime migration。

### `README.md`
更新：
- 当前运行内容
- 新作者/程序数据入口
- 四章节
- 新测试命令
- Godot 4.7
- 旧切片历史状态

### `.github/workflows/ci.yml`
当前 headless 模板是 4.3，而项目 features 是 4.7。
改为 Godot 4.7 并逐步启用运行时测试。

### 内容编译/运行层
新增或扩展：
- R16.2 compiler
- runtime
- condition DSL mapper
- typed state
- auto article builder

### tests
新增 R16.2 测试并分类旧测试。

## 建议保留复用

- `scripts/game_state.gd`：知识分离和 snapshot 思想
- `scripts/main.gd`：手动推进/Control UI/checkpoint/debug
- `story_repository.gd`：校验风格
- `prototypes/story_interaction_lab/`：JSON node/choice 模型参考
- 现有视觉/Debug 工具

## 不要直接复用为剧情事实

- `content/程序生成_请勿手改/剧情剧本.csv`
- 旧 21 列剧情工作簿内容
- v6 / v343 内容测试
- story_interaction_lab 的旧 story_flow.json
- 旧 CURRENT_TRUTH 的赵敬文/林怀安事实链

## 资源

现有 art / production 资源先不删除。
只有经过 R16.2 人物年龄、服装、场景、报馆名审核后才转正式。
旧资源可以继续做占位图。
