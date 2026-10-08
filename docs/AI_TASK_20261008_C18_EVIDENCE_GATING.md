# 《雾港来信》C18 证据门槛回写与验证

> 文档性质：执行范围、审查与验证记录，不是剧情事实源。外部 skill 和岗位结论只提供方法；剧情事实以 v6 权威文件为准。

## 范围与模式

- 任务 ID：`AI-TASK-20261008-C18-EVIDENCE-GATING`
- 首轮修改：2026-10-03；续作验证：2026-10-08。
- 用户命令：“用这个skills改下剧本吧”；随后“继续”。
- 模式：已批准实现；档位：`standard`；状态：`CLOSED`。
- 唯一目标：让 C18 判断的作者入口条件与玩家实际记录一致，消除作者数据和运行器重复条件的分歧。
- 完成定义：工作簿与生成 CSV 只改五条出现条件和对应设计备注；支持记录不足时不显示相应判断；取得记录后可继续写稿、见报与 C22；独立 QA 验证。
- 允许修改：两份当前工作簿的五条条件与备注、同步生成 CSV、`scripts/main.gd` 的重复条件覆盖、相关测试和变更记录。
- 明确不改：两份 v6 作者文档中的事实、台词、场次、人物动机、写稿结果；精选 Demo 路线、第二章场次、赵敬文案证据路径与其余未定事项。
- 文件 owner：`/root`。审查代理与 QA 无仓库写权限；隔离副本中的测试缓存和临时脚本允许写入。
- 回滚参考：修改前 Git `b1408fb`；工作簿原始 SHA-256 `4bd59a935f174de306dc013ad8b5b5b4805905591a340d6ab1fc9d4a0d80fa2f`。
- 用户授权范围按当前明确的 C18 条件回写执行；不据此把其他提案升级为已确认。决策记录为 `DEC-20261003-SKILL-EVIDENCE-GATING`，`CURRENT_TRUTH.md` 已同步实现摘要。

## 依据与证据

| 材料 | 本次用途 |
|---|---|
| `AGENTS.md` | v6 权威链、正式变更、生成物与独立 QA 边界 |
| `docs/CURRENT_TRUTH.md` | 当前切片与知识边界 |
| `docs/剧情修订稿_v6_人物与前史.md` 11.3.5 | 位置强/窄措辞、药盒固定记录与吊绳可达性 |
| `docs/雾港来信_序章与第一章完整剧情信息树_v6.md` C07—C12、C18 | 每个判断能用的实际现场记录与人物主体 |
| `docs/DECISIONS.md` | 已确认的第一章可玩性、记者调查闭环与本次条件回写 |
| `research/KNOWLEDGE_INDEX.md` 及竞品三份知识库 | 仅复用来源、措辞强度与可理解性检查方法，不采纳新设定 |
| `mist-harbor-narrative-workflow` | 玩家行动链、实际知情、数据契约、连续性与验证方法 |
| `mist-harbor-orchestrator` | 范围锁、单文件 owner、只读审查与独立验收 |

没有新调研或新增商业决策。未使用 R16.2 剧情事实。

## 修改与行为

| 稳定 ID | 现在要求的记录 | 玩家能写的内容 |
|---|---|---|
| `C18_011` | C07 台侧 + C09 倒地位置 | 原有强位置句 |
| `C18_011B` | 非台侧 + C08 侧厅未见人 + C12 来路 | 原有场务转述窄位置句 |
| `C18_012` | C10 药盒原始经过 | 原有药盒判断，强/窄稿句仍由所选来源决定 |
| `C18_013` | C12 实际取得吊绳异常记录 | 原有吊绳待查句 |
| `C18_014` | C07 前场或乐池的具体人物记录 | 原有方仲山或陈九生离岗句 |

C10 是当前第一章固定过场，正常路径仍取得药盒记录。仅选择天桥路线、未观察异常吊绳时不出现吊绳判断。只有 C06 中段前场记录时不能写成谢幕前后的离岗事实。没有疑点支持记录时，“只报道已经确认的事实”仍可用。

原有位置强/窄和离岗筛选从 `scripts/main.gd` 特判移入作者数据；运行器统一读取 `出现条件`。未改来源选择、派生稿句或报道后果。

### 修改文件

- `outputs/01a037d8-c4f0-70d3-bc69-8c3819094801/雾港来信_剧情作者工作簿.xlsx`：唯一入口，五条出现条件和设计备注。
- `outputs/雾港来信_剧情作者工作簿_v4.1.xlsx`：与唯一入口保持字节一致的镜像。
- `content/程序生成_请勿手改/剧情剧本.csv`：由 `tools/同步剧情工作簿.gd` 生成，147 条活动数据；无手工编辑。
- `scripts/main.gd`：删除 C18 位置/离岗的重复条件覆盖。
- `tests/test_writing_evidence_conditions.gd`：增加药盒与吊绳无记录/有记录，以及确认事实保底路径的断言。
- `docs/DECISIONS.md`、`docs/CURRENT_TRUTH.md`：决策与实现摘要。
- `docs/AI_TASK_20260923_DEMO_INFO_FLOW.md`、`docs/DEMO_ROUTE_PROPOSAL_20260923.md`：补上本项完成状态，保留其他历史待决项。
- `README.md`：说明证据条件测试的新覆盖范围。
- 本文件：范围、审查、验证与限制。

此前已创建的 `.agents/skills/mist-harbor-narrative-workflow/` 本轮仅作为方法输入，没有继续修改。

## 岗位审查

- `programmer`（`/root`）：唯一写入 owner；保留通用条件解释器，只删重复特判。
- `narrative`（独立只读审查）：五条条件符合已有强/窄措辞与记录要求，没有新增事实、台词或分支结构。
- `continuity`（独立只读审查）：C10 固定记录、C07 谢幕主体与 C12 绳结点击来源一致；未发现可证实的 v6 连续性冲突。旧任务“尚未回写”状态已加续作注记。
- `playtest`（独立只读审查）：给出正常与负向路径矩阵；静态结论不代表首次玩家理解通过，自动重放由 QA 验证。
- `commercial_reviewer`（独立只读审查）：本次没有商业策略变更；材料来源与措辞强度的表达符合现行定位假设，但没有转化或留存数据。
- `qa`（独立代理）：在 `/tmp/mist-harbor-qa.w7ToNz` 隔离副本内验证，`user://` 使用独立目录；8 项指定回归与补充负向/正向路径全部通过，没有修改根仓库文件。

## 验证

环境：Godot `4.7.2.stable.official.ed1daf0bf`；XLSX 同步使用仓库已有 Godot 导入器。

| 检查 | 命令或方法 | 结果 |
|---|---|---|
| 官方工作簿同步 | `godot --headless --path . --script res://tools/同步剧情工作簿.gd` | PASS；147 条 |
| 修改前缺陷复现 | 隔离副本还原 `b1408fb` 的 `main.gd`/CSV，运行更新后的 `test_writing_evidence_conditions.gd` | 预期 FAIL；无 C10 记录的药盒、无绳结记录的天桥判断各失败一项，无解析/环境错误 |
| 当前条件验证 | 同一隔离副本换入当前 `main.gd`/CSV，再运行相同测试 | PASS |
| 元数据 | `python3 tools/validate_workflow_metadata.py --root .` | PASS；10 个知识资产 |
| 文本差异格式 | `git diff --check` | PASS |
| 独立 C18/C21/C22 与完整流程回归 | QA 隔离副本执行下列 8 项测试及补充负向/正向路径 | PASS；8/8 |
| 工作簿改动范围与镜像 | 与 Git 基线逐表比较值/公式；镜像与生成物哈希 | PASS；仅五条条件与五条备注，共 10 个值单元格变化；所有工作表名、顺序、其他值和公式未变 |
| Godot 生成字节一致性 | 在 QA 副本中调用仓库 importer，逐字节比较生成 CSV | PASS；70611 bytes，与当前 CSV 完全一致 |

独立 QA 命令在隔离副本目录执行：

```sh
godot --headless --path . --script res://tests/test_writing_panel.gd
godot --headless --path . --script res://tests/test_writing_evidence_conditions.gd
godot --headless --path . --script res://tests/test_writing_copy_variants.gd
godot --headless --path . --script res://tests/test_publication_text_separation.gd
godot --headless --path . --script res://tests/test_c22_hook_reachability.gd
godot --headless --path . --script res://tests/test_c22_branch_reachability.gd
godot --headless --path . --script res://tests/test_full_flow.gd
godot --headless --path . --script res://tests/test_workbook_sync.gd
```

补充路径全部通过：药盒无 C10 记录/有记录，天桥路线无异常记录/有记录，C06 中段记录不支持离岗，C07 前场/乐池分别支持对应人物，台侧无倒地观察/有观察，来路缺记录或缺侧厅原话/两者齐全。没有放宽既有断言，没有为通过测试改变剧情事实。

作者入口与镜像当前 SHA-256：`23ae3da1a4a5fbcda49ce44b618419dbf2a20e430dd25c0062c49bf73e18ec26`。

生成 CSV SHA-256：`79f9552dfc9881acce121a60ba79fc6cdcde585d7c9b84d620cbb738b8c4e143`。

## 未解决项与限制

- 本次五条条件回写范围内未发现权威冲突。
- C07 台侧但 C09 未看倒地位置时仍无强/窄位置句，这是此前运行层已存在的限制；v6 窄句明确限定非台侧路线，本次未新增替代措辞或把部分记录补成完整事实。
- 药盒强/窄稿句、离岗主体稿句仍由现有运行器按来源派生；其工作簿文案回写尚未完成，不把条件同步描述为整套 C18 文案同步。
- 精选 Demo 路线、谁知情 UI、第二章正式场次与赵敬文案新证据路径仍按各自原有状态处理。
- 自动流程与按钮验证不等于首次玩家盲测。可理解性、节奏和商业转化未验证。
- 工作簿已比较所有工作表值与公式；未做全量样式、绘图对象和格式比对。
- 沈砚舟立绘资源缺失属于已登记的范围外历史问题，本次不修复，也不将它计为本次回归通过。
