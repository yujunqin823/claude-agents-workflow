# Claude Code 四角色 Agents 工作流

一套给 Claude Code 用的**代码改动流水线**:

```
你提需求 → 主会话出计划 → 换一个血脉的模型审计划 → 执行者按计划落地
        → 同一个审查员再审实际代码 → 汇报「改了什么 / 怎么看出来生效了」→ 你自己跑验证
```

核心不是"多几个 agent 干活快",是**换血脉**。同一个模型审自己写的计划,漏掉的地方高度重合;换一个不同来源的模型去审,它能看见前一个结构性看不见的东西。这是整套设计唯一真正值钱的地方——**别为了省事把四个插座全填成同一家模型**,那样流水线还在,价值没了。

---

## 装

仓库结构:

```
CLAUDE.md                        → 放到项目根目录(排班规则,写给主会话)
agents/*.md                      → 放到 .claude/agents/(三个角色的岗位说明书)
install.ps1                      → Windows 一键装
install.sh                       → macOS / Linux 一键装

skills/start/SKILL.md            → 排班规则的 skill 版 ┐ 只有走「插件装」
.claude-plugin/*.json            → 插件 / 市场清单      ┘ 才用得到这两样
```

装法有两条路,**选一条就够**:

| | 一键装 / 手动装 | 插件装 |
|---|---|---|
| 怎么来 | 拷文件夹过去 | `claude plugin marketplace add` 你的 git 仓库 |
| 作用范围 | 每个项目单独装 | 装一次全机器生效 |
| 更新 | 每台机器手动重拷 | `claude plugin update` |
| 排班规则的强制力 | **强**(`CLAUDE.md` 无条件在上下文里) | **弱**(skill 要敲 `/agents-workflow:start` 才加载) |

**强制力这一栏是真正的区别。** 插件系统的组件只有 Skills / Agents / Hooks / MCP 四类,**没有"常驻上下文"这一类**——所以 `CLAUDE.md` 那条「所有代码改动都必须走工作流」在插件路线下没法自动生效。要那条硬规则,就得把 `CLAUDE.md` 放进项目根目录,两条路可以叠着用。

> **改规则的时候注意:** `skills/start/SKILL.md` 的正文是 `CLAUDE.md` 的逐字副本(只多了顶上四行 frontmatter)。**改了 `CLAUDE.md` 必须同步过去**,否则两条路线的规则会悄悄分叉——一边改了另一边没改,而且不报错。同步命令(PowerShell):
>
> ```powershell
> $b = [IO.File]::ReadAllText("CLAUDE.md", [Text.Encoding]::UTF8)
> $f = (Get-Content "skills\start\SKILL.md" -Raw -Encoding UTF8) -split "(?m)^---$" | Select-Object -Index 1
> [IO.File]::WriteAllText("skills\start\SKILL.md", "---$f---`n`n$b", (New-Object Text.UTF8Encoding($false)))
> ```

### 一键装(推荐)

先把这个文件夹弄到目标电脑上——解压 `claude-agents-workflow.zip`,或者 `git clone` 你自己的仓库,随便哪种。然后:

**Windows(PowerShell):**

```powershell
cd <解压出来的目录>

# 装到某个项目
.\install.ps1 -Target "H:\你的项目"

# 或者装到全机器(所有项目都吃这套)
.\install.ps1 -Global
```

**macOS / Linux:**

```bash
cd <解压出来的目录>
chmod +x install.sh          # 从 zip 解出来的,执行位会丢

./install.sh ~/你的项目      # 装到某个项目
./install.sh --global        # 装到全机器
```

脚本**不会覆盖已有的 `CLAUDE.md`**。目标位置已经有一份时,它会把新的写成 `CLAUDE.agents-workflow.md` 放在旁边,让你自己决定怎么合并。

### 手动装

就是复制两样东西,没有别的:

| 从 | 到(项目级) | 到(全局) |
|---|---|---|
| `CLAUDE.md` | `<项目>/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `agents/*.md` | `<项目>/.claude/agents/` | `~/.claude/agents/` |

项目级和全局可以同时存在,项目级的优先。

### 插件装(换电脑最省事)

这个仓库同时是一个 **Claude Code 插件**和一个**插件市场**,所以任何一台装了 Claude Code 的电脑,两条命令就能装上:

```bash
claude plugin marketplace add yujunqin823/claude-agents-workflow
claude plugin install agents-workflow@agents-workflow
```

装完 `claude plugin details agents-workflow` 会显示:

```
Component inventory
  Skills (1)  start
  Agents (3)  auditor, implementer, scout

Projected token cost
  Always-on:   ~395 tok   added to every session
```

三个 agent 直接可用(**不用重开窗口**,插件走的是另一条加载路径),排班规则敲:

```
/agents-workflow:start
```

**这个 `插件名:技能名` 的前缀是自动加的,不用你记。** 它也顺便解决了撞名问题——你装十个插件,各占各的前缀,谁也盖不掉谁。而且插件市场是**你自己一台台加的**,不存在全球共用的命名空间,别人叫什么跟你无关。

以后规则改了,推到仓库,每台电脑 `claude plugin update agents-workflow` 就同步了——这是插件路线相对拷文件夹唯一的、也是真正的好处。

不想用了:

```bash
claude plugin uninstall agents-workflow
claude plugin marketplace remove agents-workflow
```

**两个提醒:**

- **插件装是全局的**(user 作用域),所有项目都会吃到这三个 agent 和约 397 token 的常驻开销。只想在个别项目试,用上面的一键装。
- **`/agents-workflow:start` 是手动的。** 你不敲,主会话不一定会自觉走流水线。要「一律送审」的强制力,还是得把 `CLAUDE.md` 放进那个项目的根目录。

### 搬到别的电脑

整个文件夹就是全部内容,**没有任何依赖、没有安装过程**。三条路,由省事到麻烦:

1. **插件装** —— `claude plugin marketplace add yujunqin823/claude-agents-workflow`,见上一节。以后靠 `plugin update` 同步。
2. **git clone** —— 新电脑 `git clone https://github.com/yujunqin823/claude-agents-workflow.git`,再跑 `install.ps1`。要更新就 `git pull` 后重跑。
3. **拷 zip** —— 打包丢 U 盘 / 网盘 / 微信,解压跑 `install.ps1`。不用配任何凭证,但以后每次改规则都得手动重拷一遍。

新电脑上唯一要**重新配**的不是这些文件,是**插座映射**——`fable` / `sonnet` / `haiku` 分别指向哪个模型,那份配置在你的路由层(CCR 之类)里,**不在这个仓库里,也不会跟着 clone 过来**。见下面「插座和模型」。

---

## 更新怎么传播(不会自动)

一共有**三份互相独立的副本**,改了任何一份,另外两份都不会自己跟着变:

```
① 你本地的源文件            ② GitHub 仓库            ③ 别的电脑上的副本
   claude-agents-workflow/  ──push──▶              ──update──▶   ~/.claude/plugins/cache/
                                                                  或 clone 下来的那份
```

**★没有任何一步是自动的。** 每一跳都得你显式推一把。

### ① → ② 你改完,推上去

**★如果改的东西要通过「插件装」传出去,先把版本号 +1**——`.claude-plugin/plugin.json` 里那行 `"version"`。为什么见下面那条警告。

```bash
git add -A
git commit -m "改了什么"
git push
```

### ② → ③ 别的电脑拉下来

**插件装的:**

```bash
claude plugin marketplace update agents-workflow                # 先刷市场
claude plugin update agents-workflow@agents-workflow            # 再更新插件
```

两处容易写错:

- **插件名必须写全 `插件名@市场名`。** 只写 `claude plugin update agents-workflow` 会报 `Plugin "agents-workflow" not found`。
- **市场必须先刷。** 不刷,本地那份市场副本还停在上次 clone 的状态。

更新完**重开编辑器窗口**——命令自己也会提示 `Restart to apply changes`。

> **★★不改版本号 = 永远更不动,而且它会骗你说已经是最新。**
>
> 实测:改了内容推上 GitHub、版本号仍是 `1.0.0`,然后 `marketplace update` 成功刷到了新内容,但 `plugin update` 回的是
> `√ agents-workflow is already at the latest version (1.0.0).` —— **插件副本一个字没变。**
>
> 它只比版本号,不比内容。所以每次改完要传出去的东西,`plugin.json` 的 `version` 必须跟着 +1,否则所有装了插件的机器都会停在旧版,而且看起来一切正常。
>
> (改完再推一次实测:版本号 `1.0.1` 后同样两条命令,`√ Plugin "agents-workflow" updated from 1.0.0 to 1.0.1`,新内容到位。)

**clone 装的:**

```bash
git pull
```

拉完还没完:`install.ps1` 是**拷贝**文件进项目的,仓库更新了不等于项目里那份更新了,**得重跑一次安装脚本**(要覆盖已有的加 `-Force`)。这条路没有版本号的坑。

### 最容易忘的一处

装进项目里的 `CLAUDE.md` 和 `.claude/agents/*.md` 都是**拷贝,不是链接**。你在项目里顺手改了规则,仓库不知道;仓库更新了,项目也不知道。哪份是权威由你自己定,但别指望它们互相同步。

同理,仓库内部 `CLAUDE.md` 和 `skills/start/SKILL.md` 是同一份正文的两个副本,改了一个记得重新生成另一个(见上面「插件装」那节的重生成脚本)。

---

## 装完必须重开窗口

**`.claude/agents/` 只在启动时扫一次。** 新增或改名 agent 文件后,不重开编辑器窗口 = 那几个 agent 根本不存在,主会话会安安静静地自己把活干了,你还以为它送审了。

改 agent 文件的**内容**不用重开;改 `tools:` 字段或文件名,重开。

### 怎么确认真的装上了

在目标项目里开一个新会话,直接问:

```
现在有哪些 subagent 可用?
```

回答里要能看到 `auditor` / `implementer` / `scout` 三个。看不到就是没重开窗口,或者文件放错位置了。

---

## 怎么用

**你不用记任何命令。** 装好之后,你说"改 X",工作流自动开始跑。

一次典型的对话长这样:

> **你:** 把列表页的默认排序从「按创建时间」改成「按销量」
>
> **Claude:**(如果有会改变结果的选择,这里会一次性问你,比如"老数据要不要跟着改")
> …(内部跑:出计划 → 送审 → BLOCK → 改计划 → 再送审 → PASS → 执行者落地 → 再送审代码 → PASS)
>
> **Claude:** 改完了,两次送审都过。改了 `a.js:60`、`a.js:1227`、`b.js:568` 三处…
> **怎么看出来生效了:**打开列表页,不点任何筛选,第一行是销量最高的那条。
> 说明:审查通过 ≠ 验证通过,审查员只读代码没跑东西。

中间那一大段它自己走,不问你。

### 只有这四种情况它会停下来找你

1. **开工前的提问窗口** —— 有「会改变最终结果」的选择(填哪个数、冲突听谁的、出错是跳过还是中断)。一次问完,后面不再打断。
2. **审查 3 轮还没 PASS** —— 把三轮分歧摆给你,你拍板。
3. **发现需求本身有问题** —— 它不许自己把你的需求改小改简单,只能停下来问你。
4. **执行者连续失败 2 次** —— 不许无限重试。

### 想跳过流水线

小改动懒得走全套,直接说:

```
不用送审,你直接改
```

这句话是 `CLAUDE.md` 里写死的例外口令。

### 纯问问题不会触发

查文档、读代码、问状态、聊天——不走工作流。只有**真要动代码文件**才走。

---

## 装完要按项目定制两处

这两处是通用模板留的空,填了能省掉整轮无效审查:

### 1. `.claude/agents/auditor.md` 底部的「PROJECT-SPECIFIC TRAPS」

每个项目都有**长得像 BUG 但其实是刻意设计**的东西。审查员不知道,就会 BLOCK 它,或者更糟——执行者把 load-bearing 的代码删了。

打开 `auditor.md`,找到文件里那段 HTML 注释,把你项目的坑写进去,带 `file:line`:

```markdown
- 运费求解器里的 0.5kg 进位是刻意的排序键,不是四舍五入 BUG。
  删掉会算出更便宜但物理上发不了的 186cm 箱子。(freight.js:412)
- `api.example.com` 有数据,`api-us.example.com` 是空页。
  那个看起来"多余"的域名判断在干实事。(reader.js:88)
```

### 2. 项目根目录建一个 `PROJECT-NOTES.md`

`CLAUDE.md` 和 `auditor.md` 都会去读它。坑多了写不进 `auditor.md` 的,放这里,记的是同一类东西:**哪些行为是故意的、不许当 BUG 修**。

---

## 四个角色

| 角色 | 谁 | 插座 | 有什么工具 | 能干什么 |
|---|---|---|---|---|
| **大脑** | 主会话 | `ANTHROPIC_MODEL` | 全部 | 聊天、规划、调度。**唯一的调度点** |
| **审查** | `auditor.md` | fable | Read / Grep / Glob | 审计划、审代码。**没有 Bash,结构上就跑不了测试** |
| **执行** | `implementer.md` | sonnet | Read / Write / Edit / Grep / Glob / Bash / Agent | 严格按计划落地,不许自作主张 |
| **侦察** | `scout.md` | haiku | Read / Grep / Glob / Bash | 探接口、找代码、扫模式。只读 |

### 审查员为什么故意不给 Bash

给了它就会去跑测试,然后把"测试过了"报上来。而它跑的是它自己想出来的测试,证明的是它自己的假设。

**拿掉 Bash 之后,它只能读代码、顺着调用链在脑子里走一遍。** 它的 PASS 只代表"我看不出问题",永远不代表"测过了"。这两件事在汇报里必须分开说——`CLAUDE.md` 里有一整节在管这个。

**真正的测试归你跑。**

### 拓扑:兄弟看不见,上级能派下级

```
        主会话(唯一调度点)
       ╱      │       ╲
  审查员    执行者     侦察员
              │
            侦察员      ← 执行者可以自己派侦察员查事实
```

审查员和执行者是并行的独立进程,**互相看不见、不能传话**。所有横向信息必须经主会话中转。

执行者可以自己派侦察员——那是上级派下级,允许。但它只能**查事实**,不能**做决定**(改计划、扩范围、换做法都得报上来)。

---

## 插座和模型

agent 文件里写的是**插座名**(`fable` / `sonnet` / `haiku`),不是具体模型 ID。用 CCR 之类的路由层时,把插座指到别家模型,这些 `.md` 一个字都不用改。

插座实际是四个环境变量,路由层负责把它们填上:

| 插座 | 环境变量 | 谁在用 |
|---|---|---|
| 主会话 | `ANTHROPIC_MODEL` | 大脑 |
| fable | `ANTHROPIC_DEFAULT_FABLE_MODEL` | 审查员 |
| sonnet | `ANTHROPIC_DEFAULT_SONNET_MODEL` | 执行者 |
| haiku | `ANTHROPIC_DEFAULT_HAIKU_MODEL` | 侦察员 |

四个插座填什么,由你的路由层决定。一份**示意**(照着这个形状填你自己的):

```
ANTHROPIC_MODEL                 = <厂商A>/<你的主力模型>
ANTHROPIC_DEFAULT_FABLE_MODEL   = <厂商B>/<另一家的模型>   ← 必须跟主会话不同源,这条是关键
ANTHROPIC_DEFAULT_SONNET_MODEL  = <厂商C>/<干活快的模型>
ANTHROPIC_DEFAULT_HAIKU_MODEL   = <厂商C>/<最便宜的模型>
```

**唯一不能将就的是 fable 那行**:审查员跟主会话必须来自不同厂商。剩下三个怎么填都行,填错了最多是慢一点、贵一点,填成同一家审查员就白设了。

**如果启动后某个 agent 用不了,多半是插座名你的环境不认。** 打开对应的 `.md`,把 frontmatter 里的 `model:` 换成你环境认的值:

```yaml
model: fable        # 换成 opus / sonnet / haiku,或者完整模型 ID
```

**换的时候守住一条:审查员的模型必须跟主会话不同源。** 主会话是 Opus 就别让审查员也是 Opus,那等于自己审自己,整套东西白搭。宁可审查员用一个更弱但不同源的模型。

插座就四个,主会话占一个。再建 agent 文件只能复用已有插座——多出来的是一份独立注意力,不是一条新血脉。所以**"加角色"便宜,"加血脉"做不到**。

---

## 常见坑

| 症状 | 原因 |
|---|---|
| 它没送审就直接改了 | 没重开窗口,`.claude/agents/` 没被扫到 |
| `auditor` 找不到 / 报错 | `model: fable` 你的环境不认,换成 `opus` 之类 |
| 审查员老 BLOCK 同一类东西 | 那类东西该写进 `CLAUDE.md` 的「送审前自查清单」 |
| 审查员把刻意设计当 BUG 报 | `auditor.md` 底部的 TRAPS 段没填 |
| 全局装了但某个项目不想用 | 在那个项目根目录放一份自己的 `CLAUDE.md`,项目级优先 |
| 并行改动丢代码 | 两个执行者碰了同一个文件。文件集合必须完全不相交,`CLAUDE.md`「并行执行」一节有说明 |

---

## 这套东西解决的是什么

不是"让 AI 写得更快"。是把三件反复出问题的事变成结构性约束:

1. **AI 说"改好了",实际没验过。** → 审查员没有 Bash,它的 PASS 天然不能冒充验证;`CLAUDE.md` 强制汇报时把两者分开说。
2. **AI 自己审自己,漏的地方永远一样。** → 审计划的模型和写计划的模型不同源。
3. **AI 顺手"优化"了你没让它动的东西。** → 计划必须写 `CHANGE SCOPE`,执行者不许越界,审查员也只在范围内 BLOCK。

---

## License

MIT
