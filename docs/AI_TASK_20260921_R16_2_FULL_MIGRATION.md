# R16.2 完整正文与当前入口迁移

> **已过期（2026-09-22）**：本文件是 R16.2 时期的历史任务记录，只作追溯。R16.2 已按 `DEC-20260922-CANON-REVERT-V6` 撤销，当前正典是 v6。本文件中的剧情事实、节点编号、路径指向与"当前口径"表述均已失效，不得据此执行。文中提到的 `docs/r16_2/legacy/` 目录已删除（其内容与 `docs/` 根目录下的 v6 正本重复），R16.2 资料现存于 `docs/r16_2/` 的 `source/`、`handoff/`、`archived/` 三个子目录。

> 这是执行记录，不是剧情事实源。正文与路由仍以 `docs/r16_2/source/` 中的 DOCX/XLSX 为准。

- 任务：`TASK-R16.2-20260921-FULL-MIGRATION`
- 用户要求：把此前已经敲定、但当前默认入口尚未迁回的内容都接上。
- 范围：完整正文逐句播放、条件过滤、当前入口的阅读记录/采访本、R16.2 路由与旧引擎兼容边界。
- 不做：把旧 v6 事实混入 R16.2；改写作者 DOCX/XLSX；新增剧情或结局；把制作说明显示给玩家。

## 实现

- `tools/r16_2_compile.py` 现在以 XLSX 编译节点/选择/状态，以 DOCX 编译玩家可见正文；两份源文件的 SHA-256 都写入生成物，运行时仍只读取 JSON。
- 普通 scene/prologue 节点生成 `dialogue_beats`。编译器会拆分说话人和句子，保留条件前缀供白名单条件评估器过滤，并排除选择表、制作说明、谜题答案和自动组稿指令。
- `scripts/r16_2_runtime.gd` 优先消费完整 `dialogue_beats`，没有正文时才回退到接入表摘要；记录已读原话，选择、谜题、回溯和报纸生命周期保持原有状态机。
- `scripts/r16_2_main.gd` 增加说话人分层、章节进度、采访本回看和完整正文逐句推进；原有选择、标题送排、排序、核稿、预览和回到上一次选择仍由 R16.2 runtime 驱动。
- `scripts/r16_2_condition_evaluator.gd` 修复布尔状态与 `0/1` 比较，并兼容 DOCX 条件对白中的中文“且/或”，避免 D66/D67 等路线台词被静默过滤。
- `.github/workflows/ci.yml` 已把逐句对白测试与知识/权限边界测试纳入 Godot 4.7 headless 门禁，并在必入文件检查中锁定对应测试文件。

## 当前覆盖

- 33 个普通场景/冷开场节点均有正文逐句数据；D15-B、D65-B、D65-C 继续使用专用交互，不把排序答案或后台制作指令当对白。
- R16.2 的 36 Nodes、66 Choices、U08/U15-B/U27/U28 四项交互、四条结局路线和报纸生命周期保持由 XLSX 驱动。
- 旧 `scripts/main.gd` 与 `scenes/main.tscn` 仍保留为 legacy 回滚材料；默认入口继续是 `scenes/r16_2_main.tscn`，没有混入旧 v6 剧情事实。

## 验证

```sh
python3 tools/r16_2_compile.py --check
python3 tools/r16_2_validate.py
python3 -m unittest discover -s tests -p 'test_r16_2_*.py' -v
/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_r16_2_dialogue.gd
/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_r16_2_layout.gd
/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_r16_2_ui.gd
/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_r16_2_runtime.gd
/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_r16_2_acceptance.gd
/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_r16_2_boundaries.gd
```

以上命令在本轮通过；新增边界回归覆盖 U11 部分承认、U13/U17 知识隔离、U23 工人隐私、U25A 不获得新授权，以及全名稿仍执行 off-record/匿名屏障。排除 UI/布局/立绘用例后，22 个非 UI Godot 测试全部通过。Godot 运行测试覆盖逐句对白、条件过滤、实际按钮、四路线、谜题重试、回溯和发行后状态。
