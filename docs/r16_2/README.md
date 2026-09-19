# R16.2 仓库内交接资料

`source/` 保存交接包中原样纳入仓库的四个作者源文件，`handoff/` 保存执行说明与验收计划，`legacy/` 保存被降级为历史资料的旧 v6 文档副本。

## 角色边界

- DOCX 是正文、对白与体验验收参考。
- XLSX 是节点、选择、状态、条件 DSL、快照、报纸和结局的程序接入源。
- `tools/r16_2_compile.py` 只读 XLSX，生成 `content/程序生成_请勿手改/r16_2_runtime.json`。
- JSON 是运行时输入，不可手工编辑；修改必须回到 XLSX 后重新编译。
- 本目录中的 handoff 文档说明执行范围，不覆盖 `AGENTS.md`、`CURRENT_TRUTH.md` 或 `DECISIONS.md` 的权威规则。

## 源文件校验

文件 SHA-256 应与 `handoff/07_PACKAGE_MANIFEST.json` 一致。编译与校验命令：

```bash
python3 tools/r16_2_compile.py --check
python3 tools/r16_2_validate.py
```

任何源文件之间的正式事实冲突都必须停止受影响写入并提交待确认项，不能通过编译器“选一个”静默解决。
