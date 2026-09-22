# R16.2 验收与测试计划

## P0 数据层

必须自动检查：

- NodeID 唯一
- ChoiceID 唯一
- NextNode 全存在
- Snapshot 全存在
- StateKey 全存在
- enum 值合法
- Condition DSL token 合法
- Ending condition 合法
- AutoArticleRules 条件合法

## P1 路线 smoke

至少跑：

### Route A：曝光路线
纸封头版 → 更激进调查 → FULL_NAMES → 非 correction only

### Route B：隐私保护
早期谨慎 → FACTS_PRIVACY → 守 off-record

### Route C：只更正
任意前史 → CORRECTION_ONLY → E03

### Route D：署名更正
早期纸封误导 → signed correction → 非 CORRECTION_ONLY → E04

## P2 知识/权限泄露测试

必须证明：

- U11 未承诺保密路线不会自动拿到完整动机
- U13 不看抄件路线不会提前拥有抄件内容
- U17 不会因为全局探索而偷渡旧信知识
- U23 工人隐私选择影响最终稿
- U25A 跳过 U26 不会自动获得新授权
- off-record 绝不会进 AutoArticleRules 输出
- anonymous 来源不会被实名

## P3 回溯

- 选择前 snapshot 正确
- 回到上一选择可重选
- story state 恢复
- global endings / scrapbook 不丢
- U32 共用 final snapshot

## P4 报纸

- U28 选择不等于实际发行
- D65-C 显示完整成品预览
- confirm 后才 typeset_confirmed
- D66 才 actual_published
-人物 read flag 后才出现读报反应

## P5 四种特殊交互

- U08 不超过 2–3 个操作
- U15 卡牌乱序，不泄露正确顺序
- U27 只有一个 invalid 选择
- U28 无逐条来源管理器

## P6 人物延迟回声

覆盖：
- U09 → U15/U29
- U10 → U31
- U12 → U13/U14
- U18 → U22/article/montage
- U20 → U31
- U21/U22/U23 → article/U29
- U29 → U30
- U31 → U32

## P7 结局

固定优先级：
1. E03
2. E04
3. E02
4. E01 fallback

U32 PIER/PRESS 只改变收尾演出，不增加第五个结局。

## P8 CI

先确认 Godot 4.7 headless。
然后把核心测试加入 GitHub Actions。

所有旧剧情测试：
- 明确标 legacy / rewritten
- 不允许为了旧断言修改 R16.2 新事实
