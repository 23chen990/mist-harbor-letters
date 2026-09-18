# 《雾港来信》设计模式库

> 本文件把经验证的竞品经验整理为可复用建议，不是正式剧情或机制事实源。状态为“已采用”仍只表示项目决定采用该模式；具体正式改动必须进入 `docs/DECISIONS.md` 并同步相应权威文件。

## 状态定义

- 草案：待验证或仅有初步来源。
- 已验证：有足够竞品证据或测试证据，但尚未决定用于本项目。
- 已采用：用户已明确确认采用；必须附对应决策编号。

## 模式模板

### PATTERN-YYYYMMDD-NN｜模式名称

- 状态：草案 / 已验证 / 已采用
- 对应决策：无 / `DEC-YYYYMMDD-NN`
- 问题：
- 常见失败方式：
- 已验证竞品做法：
- 为什么有效：
- 适合本项目的改造方式：
- 不适用条件：
- 参考竞品：
- 来源：
- 最后验证时间：

## 已收录模式

### PATTERN-20260830-01｜发现 → 推断 → 证明理解

- 状态：已验证
- 对应决策：无
- 问题：玩家看完了线索和剧情，却没有用行动证明自己理解了什么，侦探感只存在于题材包装。
- 常见失败方式：点击完所有热点后自动解锁下一段；NPC 或系统替玩家总结；直到结尾才第一次要求组合材料。
- 已验证竞品做法：Jon Ingold 将侦探游戏的短循环概括为发现具体信息、形成推断、再用一个不被任务日志直接写出的行动证明理解；Golden Idol 的开发目标也明确是让玩家通过玩法而非叙事包装感到自己在推理。
- 为什么有效：游戏与玩家轮流完成一半工作；信息不是奖励终点，而是下一次行动的输入。
- 适合本项目的改造方式：写稿与公开选择本身应承担“证明理解”。只有当操作语法具有明显学习门槛时，才需要用普通旧事做低风险演练；当前短选择题版本没有拖放、拼句或关系词，不应为教学单独保留一页无后果材料。
- 不适用条件：1917 那一夜不得被系统用作者答案认证；“证明理解”不等于所有推断必须判对错。
- 参考竞品：Overboard!、The Case of the Golden Idol。
- 来源：[GDC｜The Burden of Proof](https://gdcvault.com/play/1027684/The-Burden-of-Proof-Narrative)、[Golden Idol 设计访谈](https://www.gamedeveloper.com/design/case-of-the-golden-idol)
- 最后验证时间：2026-08-30

### PATTERN-20260830-02｜有限选择要给信息品类，不给具体答案

- 状态：已验证
- 对应决策：无
- 问题：位置、时间或调查对象不可兼得时，玩家若不知道各选项通常产出什么，取舍会变成盲抽。
- 常见失败方式：四个位置只有名字；某个位置第一次就是空的；关键线索藏在最反直觉选项后且没有前置信号。
- 已验证竞品做法：Overboard! 让地点、时间和人物行为稳定关联，角色还会独立行动并记住信息；Unheard 允许玩家在同一空间中选择跟随不同人物与对话线，但核心信息品类始终是路线、身份和关系。
- 为什么有效：玩家不能预知答案，却能预知自己在押哪类信息；错过内容会被体验为选择代价，而不是抽奖惩罚。
- 适合本项目的改造方式：观众席、前场、台侧、乐池分别稳定对应身体状态、调度缺席、空间路线、人物关系；具体观察仍不可预知。
- 不适用条件：不得把位置标签写成“真线索/假线索”，也不得显示凶手指向。
- 参考竞品：Overboard!、Unheard。
- 来源：[inkle｜Overboard!](https://www.inklestudios.com/overboard/)、[Unheard Steam 官方说明](https://store.steampowered.com/app/942970/Unheard/)
- 最后验证时间：2026-08-30

### PATTERN-20260830-03｜证据不足时收窄主张，不删除调查方向

- 状态：已验证
- 对应决策：无
- 问题：玩家有部分有效材料，但系统只允许“完整正确答案”或“什么也不能说”，使有限观察退化为开关。
- 常见失败方式：少一张卡就整条判断消失；系统自动补足没看见的材料；把证据强弱等同于对错。
- 已验证竞品做法：GDC 的“证明负担”讨论允许玩家从证据与推测中组合、修正和逐步收紧方案；Papers, Please 通过把具体文件字段与规则并置，让玩家指出自己实际看见的不一致，而不是先选择抽象罪名。
- 为什么有效：玩家表达的是“我现在能支持到哪里”，既保留推理自由，也维持来源纪律。
- 适合本项目的改造方式：C18 同一疑点保留弱、中、强措辞；只有亲眼记录与原件能提高句子强度，不能提高作者认证度。
- 不适用条件：不得允许弱材料直接写成强因果；不得为 1917 提供事实判定。
- 参考竞品：Overboard!（GDC 机制讨论）、Papers, Please。
- 来源：[GDC｜The Burden of Proof](https://gdcvault.com/play/1027684/The-Burden-of-Proof-Narrative)、[Papers, Please 开发日志](https://dukope.com/devlogs/papers-please/tig-00/)
- 最后验证时间：2026-08-30

### PATTERN-20260830-04｜笔记工具负责整理，不替作者判答案

- 状态：已验证
- 对应决策：无
- 问题：信息量大时玩家需要外部记忆，但一旦笔记本自动高亮正确组合，就会替玩家完成理解。
- 常见失败方式：组合后出现对勾；自动把 NPC 证词升级为事实；按作者答案给人物理解打分。
- 已验证竞品做法：Obra Dinn 的船册被设计为整理大量信息的载体；Her Story 用搜索结果让玩家自行形成观看路径，不提供一条固定线性播放顺序。
- 为什么有效：工具降低记忆负担，但保留推理和解释负担。
- 适合本项目的改造方式：采访本保存原件、速记与后续提供者字段；允许玩家并组和写自己的话，但不对人物理解作正误回应。
- 不适用条件：1937 两案的终局因果仍需按已确认机制判定；“不判人物理解”不能被误用为所有案情都不验证。
- 参考竞品：Return of the Obra Dinn、Her Story。
- 来源：[Lucas Pope｜Obra Dinn 船册设计](https://dukope.com/devlogs/obra-dinn/tig-37/)、[Her Story 官方介绍](https://www.herstorygame.com/about/)
- 最后验证时间：2026-08-30

### PATTERN-20260830-05｜时间限制应表现为机会成本

- 状态：已验证
- 对应决策：无
- 问题：故事反复说时间紧，但玩家可以看完全部内容，时间只剩气氛。
- 常见失败方式：墙钟不改变任何可用行动；倒计时只制造焦虑却没有信息取舍；错过内容可立即无成本回放。
- 已验证竞品做法：Overboard! 的时间持续推进，人物独立行动；Pentiment 的调查明确不允许一次追完所有线索，玩家在别人的时间表上行动并承担后果。
- 为什么有效：玩家获得一个信息的同时，知道自己放弃了另一个机会，材料因此带有个人路径。
- 适合本项目的改造方式：章间继续不用时钟；单场可以让高成本行动消耗一次观察机会，例如第一章上天桥后错过等待笔录时观察某人。
- 不适用条件：不得增加倒计时 UI、数字期限或每章交稿时钟。
- 参考竞品：Overboard!、Pentiment。
- 来源：[inkle｜Overboard!](https://www.inklestudios.com/overboard/)、[Pentiment 导演访谈](https://www.mmorpg.com/interviews/the-rpg-files-building-obsidians-pentiment-interview-with-game-director-josh-sawyer-2000126821)
- 最后验证时间：2026-08-30

### PATTERN-20260830-06｜反馈应呈现后果，不呈现道德分数

- 状态：已验证
- 对应决策：无
- 问题：涉及公开、指控与牺牲的选择若只显示好坏、立场点数或结局标签，会把人物变成评分资源。
- 常见失败方式：善恶值；“正确选择”弹窗；预告全部代价；完美路线同时救所有人。
- 已验证竞品做法：Papers, Please 把文件判定变成具体人物和家庭后果；Pentiment 的公开定位强调调查决定会持续影响社区与后代。
- 为什么有效：玩家面对的是自己造成的局面，而不是系统对人格的评价。
- 适合本项目的改造方式：见报后展示谁被追问、谁提前防备、什么证物无法复核；不显示牺牲账数值，不给“善/恶记者”标签。
- 不适用条件：Technical QA 所需的隐藏状态可以存在，但不得成为正式玩家界面的道德评分。
- 参考竞品：Papers, Please、Pentiment。
- 来源：[Papers, Please Steam](https://store.steampowered.com/app/239030/Papers_Please/)、[Pentiment 官方站](https://pentiment.obsidian.net/)
- 最后验证时间：2026-08-30

### PATTERN-20260830-07｜先给具体异常，再让玩家主动越界验证

- 状态：已验证
- 对应决策：无
- 问题：高价值线索需要风险行为才能取得，但玩家在行动前没有任何理由怀疑那里有东西。
- 常见失败方式：越界选项像随机按钮；NPC 直接提示“那里有关键线索”；越界后立即给完整答案。
- 已验证竞品做法：GDC 的侦探循环要求游戏先交付具体、可思考的信息，再由玩家采取行动证明理解；Golden Idol 的开发测试会检查场景是否提供足够但不过量的线索。
- 为什么有效：风险行为来自玩家自己的假说，不来自任务箭头；发现的功劳归玩家。
- 适合本项目的改造方式：台下先看见景片高度不齐，再决定是否违反“戏未散不上天桥”，上去只能确认绳被动过，不能直接得到勒颈答案。
- 不适用条件：不得用闪光、高亮、NPC 提醒或超自然演出指路。
- 参考竞品：The Case of the Golden Idol、Overboard!（GDC 机制框架）。
- 来源：[Golden Idol 试玩迭代访谈](https://www.gamedeveloper.com/business/-the-case-of-the-golden-idol-i-used-frequent-testing-to-improve-its-mystery-solving)、[GDC｜The Burden of Proof](https://gdcvault.com/play/1027684/The-Burden-of-Proof-Narrative)
- 最后验证时间：2026-08-30

### PATTERN-20260830-08｜Demo 必须实际交付商店承诺的核心动作

- 状态：已验证
- 对应决策：无
- 问题：商店页说玩家会推理、组合材料和承担后果，Demo 却主要展示对白、气氛和教程文字。
- 常见失败方式：核心系统只在 Demo 结尾短暂出现；截图只能展示人物对话；Trailer 用正式版设想而非 Demo 实机功能。
- 已验证竞品做法：Golden Idol 的 Steam 页面直接展示“自由调查、发现线索、建立理论”，并长期提供可下载 Demo；Valve 要求独立 Demo 页面描述和截图只展示 Demo 实际包含的功能与体验。
- 为什么有效：玩家能用一次完整循环验证购买理由，商店表达与试玩体验一致。
- 适合本项目的改造方式：序章先完成一次短写稿练习；第一章完整经历观察、犯忌/取舍、写稿、见报后果；截图必须能看到原件/速记/稿件之间的关系。
- 不适用条件：不得为了 Trailer 新增只用一次的 CG、UI 或分支；正式商店策略仍待确认。
- 参考竞品：The Case of the Golden Idol；Steam Demo 规范。
- 来源：[Golden Idol Steam](https://store.steampowered.com/app/1677770/The_Case_of_the_Golden_Idol/)、[Steamworks｜Demos](https://partner.steamgames.com/doc/store/application/demos?l=en)
- 最后验证时间：2026-08-30

### PATTERN-20260830-09｜全量可回放与有限观察是两种不同承诺

- 状态：已验证
- 对应决策：无
- 问题：设计同时想要“玩家不会漏关键线索”和“位置选择有永久代价”，但两者未经区分会互相抵消。
- 常见失败方式：错过的位置可立即回放，取舍失去意义；关键事实只存在于一次盲选，玩家认为不公平。
- 已验证竞品做法：Unheard 明确让全部线索都可被玩家听到并反复回放，公平性来自信息全量开放；Overboard! 与 Pentiment 则用时间和人物行动制造不可兼得路径。
- 为什么有效：每款游戏先选择一种核心承诺，再围绕它校准公平性，而不是两边都要。
- 适合本项目的改造方式：本作选择“有限观察”：关键调查方向不应整条消失，但证据强度、现场原貌和人物态度可以因选择永久变化。
- 不适用条件：不得照搬 Unheard 的无限回放；也不得用“有限观察”为盲抽和无提示关键遗漏开脱。
- 参考竞品：Unheard、Overboard!、Pentiment。
- 来源：[Unheard Steam 官方说明](https://store.steampowered.com/app/942970/Unheard/)、[inkle｜Overboard!](https://www.inklestudios.com/overboard/)、[Pentiment 导演访谈](https://www.mmorpg.com/interviews/the-rpg-files-building-obsidians-pentiment-interview-with-game-director-josh-sawyer-2000126821)
- 最后验证时间：2026-08-30

### PATTERN-20260830-10｜先建立可信职业日常，再让异常侵入同一动作

- 状态：已验证
- 对应决策：无
- 问题：恐怖作品如果一开始只用怪声、黑影和惊吓宣告类型，玩家能感到气氛，却不一定在意异常破坏了什么。
- 常见失败方式：正常流程尚未被玩家理解就开始故障；异常只存在于过场；为了升级恐怖不断增加新系统和一次性演出。
- 已验证竞品做法：DEAD LETTER DEPT. 先让玩家反复辨认并录入普通残损信件，再让信件内容与界面逐渐显得针对玩家；Killer Frequency 让接听、查资料和操作广播台始终是同一组职业动作，但来电后果越来越危险。
- 为什么有效：恐怖来自玩家已建立的操作预期被轻微破坏；同一个动作可以同时承担玩法、叙事和氛围升级。
- 适合本项目的改造方式：先让读报、速记、核对来源和写稿盘成为可靠日常；随后用字迹不一致、材料缺页、同一句话在不同来源中变形、印出后产生意外反应等可核对异常增加不安。
- 不适用条件：异常不能自动证明超自然因果，不能把 UI 故障伪装成谜题答案，也不能新增第七个主角动词。
- 参考竞品：DEAD LETTER DEPT.、Killer Frequency。
- 来源：[DEAD LETTER DEPT. Steam 官方说明](https://store.steampowered.com/app/1627350/DEAD_LETTER_DEPT/)、[Team17｜Killer Frequency](https://www.team17.com/games/killer-frequency)
- 最后验证时间：2026-08-30

### PATTERN-20260830-11｜主控心声不替玩家连接线索

- 状态：已验证
- 对应决策：无
- 问题：主角每读到一件材料就用心声概括关系、提出嫌疑或解释情绪，玩家虽然看懂了故事，却失去自己产生假说的空间。
- 常见失败方式：心声复述屏幕上刚出现的文字；替玩家说出“两件事有关”；点击后自动评价“这里值得追”；在选择前解释选项意义和代价。
- 已验证竞品做法：Golden Idol 刻意依靠场景、线索与玩家提交推断制造“Aha”，开发者把“信任玩家自己想明白”视为核心；Obra Dinn 与 Her Story 同样把整理和连接负担留给玩家。Pentiment 即使使用有明确身份的主角，也把核心承诺写成“由玩家自行调查并承担选择的长期后果”。相反，Disco Elysium 的技能与思想会主动和主角对话、生成对白选项与事件后果，高频内在声音能成立，是因为它们本身就是可构筑、可触发的 RPG 系统，而不是普通说明旁白。
- 为什么有效：材料负责提供事实，玩家负责形成关系，角色只负责行动和承担；三者分开后，“我想到的”不会被误成“作者告诉我的”。
- 适合本项目的改造方式：沈砚舟读取纸面材料后默认沉默；能从排版、并置、动作或后果看出的内容不写心声。只保留会改变场面关系、获取信息或承担公开后果的对外发言。若某个瞬间确有不可替代的私人感受，必须同时满足“外部无法观察”“不包含线索关系”“会改变紧接着的行动”三项，且只用一次短句。
- 不适用条件：这不是把主角写成哑巴；被质问、主动询问、作证和发稿时仍要让玩家选择对外行动。也不能照搬 Disco Elysium 的高频心声，除非未来把内在声音正式设计成核心机制并重新进入决策闭环。
- 参考竞品：The Case of the Golden Idol、Return of the Obra Dinn、Her Story、Pentiment、Disco Elysium；中国市场类型对照为《隐形守护者》，其真人互动影像与上百分支以角色身份和剧情选择为卖点，不应用来给硬推理文本密度定标。
- 来源：[Golden Idol 设计访谈](https://www.gamedeveloper.com/design/case-of-the-golden-idol)、[Obra Dinn 船册开发日志](https://dukope.com/devlogs/obra-dinn/tig-37/)、[Her Story 官方介绍](https://www.herstorygame.com/about/)、[Pentiment 官方站](https://pentiment.obsidian.net/)、[Disco Elysium 官方开发日志｜Thought Cabinet](https://discoelysium.com/devblog/2019/09/30/introducing-the-thought-cabinet)、[Disco Elysium 官方开发日志｜Skill Checks](https://discoelysium.com/devblog/2016/09/19/on-skill-checks)、[隐形守护者 Steam](https://store.steampowered.com/app/998940/)
- 最后验证时间：2026-08-30

### PATTERN-20260830-12｜对白必须是行动，不是资料传送

- 状态：已验证
- 对应决策：无
- 问题：角色轮流把作者需要的资料说完整，句子语法正确却像采访提纲、审讯菜单或任务提示。
- 常见失败方式：重复画面已经给出的信息；问一句就得到完整背景；角色替系统重申截止时间和规则；所有人都用完整、礼貌、同长度的书面句。
- 已验证竞品做法：Oxenfree 把玩家发言、沉默和打断都放进持续谈话流，谈话本身就是玩家行动；Overboard! 的人物会记住看见、听见和玩家做过的事，因此说什么会改变后续状态；Pentiment 的对白选择带有角色态度，是否合适取决于对象和情境，不把已解锁选项自动当作最佳答案。
- 为什么有效：自然感主要来自双方目标不完全一致；每句话都在争夺主动权，而不是合作完成作者的信息表。
- 适合本项目的改造方式：一句对白至少改变信息、态度、关系、位置、证物、公开口径或下一步行动之一。已经由纸面、动作和构图表达的内容不重复说；NPC 可以答一半、反问或拒答。警察笔录允许程序性短问，但不得把整段写成连续信息菜单。
- 不适用条件：不得为了“自然”增加闲聊、方言拼写或口头禅；关键证物来源和警方程序仍要清楚。实时打断与倒计时不是本作需要新增的系统。
- 参考竞品：Oxenfree、Overboard!、Pentiment；《隐形守护者》只用于高压选择与身份后果对照，不作为本作对白密度范本。
- 来源：[GDC｜Oxenfree Narrative Mechanics](https://www.gdcvault.com/play/1024270/Building-Game-Mechanics-to-Elevate)、[inkle｜Overboard!](https://www.inklestudios.com/overboard/)、[Pentiment 导演访谈](https://www.mmorpg.com/interviews/the-rpg-files-building-obsidians-pentiment-interview-with-game-director-josh-sawyer-2000126821)、[隐形守护者 Steam](https://store.steampowered.com/app/998940/)
- 最后验证时间：2026-08-30

### PATTERN-20260830-13｜开场先让主控失去具体东西，再解释他为什么失败

- 状态：已验证
- 对应决策：无
- 问题：开场先讲职业方法、世界规则或案件原理，玩家虽然收到信息，却还不知道主控过得怎么样、想要什么，因此无法在意这次失败。
- 常见失败方式：上司用一句抽象判词定义主角能力；主控自称落魄；先解释证据规范，再补职业压力；用房租、饥饿等未确认事实粗暴制造可怜。
- 已验证竞品做法：《极乐迪斯科》先用失控房间、欠款、丢失警徽及与旅店经理和警局的难堪交涉，把“失败侦探”变成一连串玩家亲历的处境；《隐形守护者》先在记者会中让反抗者被拖走、全场噤声，再让主控举手，身份危险由行动成立；Pentiment 让字体、称谓、谁能支使谁和对话结果共同表现社会位置；Oxenfree 则把沉默与打断本身变成关系行动，而不是让人物说明彼此关系。《烟火》制作人也明确指出，主角若没有个人层面的刻画，只会成为玩家手中的旁观工具。
- 为什么有效：玩家先看见谁控制主角需要的资源、主角刚失去什么、他愿意怎样争取；后续职业规则因此不再是教程，而是解释这次具体损失的细节。
- 适合本项目的改造方式：S00 先撤掉沈砚舟的稿位，让他请求再给时间；再把赵敬文死后没人接的春和线交给他，并拒绝预留版面。红笔与证词差距只留在稿纸上，玩家可读但不要求立即理解。主角只问“再给多久／留几栏”，不说“我混得不好”或用心声自评。
- 不适用条件：不得自行新增欠薪、房租、饥饿、停职或失去记者证；本作已确认的是职业信用低、屡遭退稿、长期跑边角料和春和线随时可被收走。也不得为了显惨增加新 CG、新角色或长篇羞辱对白。
- 参考竞品：Disco Elysium、隐形守护者、Pentiment、Oxenfree、烟火。
- 来源：[Disco Elysium 官方开发日志｜Choose Your Own Misadventure](https://discoelysium.com/devblog/2019/07/15/choose-your-own-misadventure-part-1)、[隐形守护者导演访谈](https://www.sohu.com/a/311671196_524286)、[Pentiment 导演访谈](https://www.mmorpg.com/interviews/the-rpg-files-building-obsidians-pentiment-interview-with-game-director-josh-sawyer-2000126821)、[GDC｜Oxenfree Narrative Mechanics](https://www.gdcvault.com/play/1024270/Building-Game-Mechanics-to-Elevate)、[《烟火》制作人访谈](https://www.gcores.com/articles/134609)、[GDC｜Delivering Exposition in Games](https://gdcvault.com/play/1013829/I-Don-t-Want-to)
- 最后验证时间：2026-08-30
