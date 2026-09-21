# R16.2 非 UI 试玩验收记录

本记录只覆盖运行逻辑、信息边界和报纸状态机。界面视觉、布局、立绘和移动端触控暂不在本轮范围内。

## 当前基线

- 分支：`r16.2-integration`
- 提交：`3de650256f1cff36e5fda4e7754618f4ba37ea6a`
- PR：[#1](https://github.com/23chen990/mist-harbor-letters/pull/1)
- 引擎：Godot 4.7 headless

## 已验证路径

| 路线 | 主要稿件 | 预期结局 | 结果 |
| --- | --- | --- | --- |
| A | `FULL_NAMES` | E01 | 通过 |
| B | `FACTS_PRIVACY` + off-record | E02 | 通过 |
| C | `CORRECTION_ONLY` | E03 | 通过 |
| D | signed correction + 非 correction-only | E04 | 通过 |

每条路径均验证：逐句对白结束后才出现选择、条件台词不泄漏作者标记、谜题错误可重试、D65-C 仍是预览、确认交排后才进入发行生命周期、回溯不清除 global unlock。

## 知识与权限边界

- U11B 不写入完整动机。
- U13B 不写入父亲信抄件内容。
- U17 没有对应线索时不显示旧信原件信息。
- U23 的匿名工人与保护工人路线分别影响自动组稿。
- U25A 不进入 U26，也不产生新的授权状态。
- `FULL_NAMES` 仍执行玉棠 off-record 与老梁匿名屏障。

## 重现命令

```sh
python3 tools/validate_workflow_metadata.py --root .
python3 tools/r16_2_compile.py --check
python3 tools/r16_2_validate.py
python3 -m unittest discover -s tests -p 'test_r16_2_*.py' -q

GODOT=/private/tmp/fog_harbor_godot/Godot.app/Contents/MacOS/Godot
$GODOT --headless --path . --script res://tests/test_r16_2_runtime.gd
$GODOT --headless --path . --script res://tests/test_r16_2_dialogue.gd
$GODOT --headless --path . --script res://tests/test_r16_2_boundaries.gd
$GODOT --headless --path . --script res://tests/test_r16_2_acceptance.gd
```

上述命令在本地通过；同等测试已纳入 PR 的 GitHub Actions。合并后再进行真人试玩和移动端体验记录。
