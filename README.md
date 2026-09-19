# 《雾港来信》R16.2 工程

> 当前开发口径已切换到交接包 R16.2。旧 v6 垂直切片与旧数据仍保留在基线中，用于历史追溯和回滚，不得与 R16.2 拼接。

| 项目 | 当前值 |
| --- | --- |
| Git 基线 tag | `baseline-20260919` |
| R16.2 集成分支 | `r16.2-integration` |
| 基线 commit | `a920ebffff051bc005080bda536ceeda9966fe92` |
| 引擎 | Godot 4.7 / GDScript / 2D Control |
| 当前权威摘要 | `docs/CURRENT_TRUTH.md` |
| R16.2 正文与程序源 | `docs/r16_2/source/` |
| 运行时生成物 | `content/程序生成_请勿手改/r16_2_runtime.json` |

## 权威读取顺序

1. `docs/CURRENT_TRUTH.md`
2. `docs/r16_2/source/雾港来信_R16.2_核心玩法与选择兑现版_全篇互动剧本.docx`
3. `docs/r16_2/source/雾港来信_R16.2_程序接入表.xlsx`
4. `docs/DECISIONS.md`
5. `docs/r16_2/legacy/` 与根目录 v6 文件只作历史追溯

详见 [`AGENTS.md`](AGENTS.md)。

## R16.2 核心循环

`采访/观察 → 判断信息 → 轻推理闭环 → 决定报道方向 → 自动生成报纸 → 发行 → 人物/世界后果`

章节为 CH1《纸封》、CH2《棕瓶》、CH3《谁欠谁》、CH4《见报》，覆盖 D00、U01–U32 与 U15-B/D65-B/D65-C 辅助节点。

玩家只处理四种特殊交互：U08 两张完整标题卡二选一后点“送排”、U15-B 五卡排序、U27 单题核稿、U28 三稿件卡三选一后看整版清样。没有自由拼标题、拖拽排版、逐条来源管理、好感/道德/职业分或情绪场广告。

## 数据入口与编译

R16.2 XLSX 是作者/接入源，运行时不直接解析 Excel：

```text
docs/r16_2/source/雾港来信_R16.2_程序接入表.xlsx
        ↓ python3 tools/r16_2_compile.py
content/程序生成_请勿手改/r16_2_runtime.json
        ↓ Godot R16.2 runtime
```

编译并校验：

```bash
python3 tools/r16_2_compile.py
python3 tools/r16_2_compile.py --check
python3 tools/r16_2_validate.py
```

不要手工编辑 `content/程序生成_请勿手改/`。

## 运行与测试

若本机安装 Godot 4.7，可先导入项目并运行默认场景；R16.2 的 headless 数据测试不依赖编辑器：

```bash
python3 -m unittest discover -s tests -p 'test_r16_2_*.py'
python3 tools/validate_workflow_metadata.py --root .
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_r16_2_runtime.gd
godot --headless --path . --script res://tests/test_r16_2_acceptance.gd
```

旧 v6 Godot 测试仍保留，但其剧情断言标记为 legacy；失败时必须区分过期测试与真实实现缺陷，不能为了旧断言改回 v6。

## 状态与报纸边界

story state 与 global exploration 分层；回溯只恢复 story state。报纸生命周期为：

`draft → main_locked → auto_build → preview → typeset_confirmed → actual_published → delivered/read`

`确认交排` 不等于发行，发行不等于人物已读。结局路由固定为 `E03 → E04 → E02 → E01 fallback`。

## 当前阶段限制

本分支第一阶段优先完成权威切换、确定性编译器、状态/条件/节点运行骨架和可验证主线路由。完整客户端美术替换、移动端适配、IAA 接入、商店页和发行不在本轮自动完成，除非另有明确任务。
