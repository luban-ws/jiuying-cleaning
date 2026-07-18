# AGENTS.md — CleanSpace 协作与 Agent 索引

面向人类贡献者与 AI：改动再小也应遵守基线，避免「以后再修」的技术债。本文上半为 **CleanSpace 工程约定**，下半为 **Persona 与快捷指令**（可选的协作隐喻；实现细节仍以 RFC 与本文件基线为准）。

---

## 黄金法则与工作流

> [!IMPORTANT]
>
> **先看 RFC，再动手。** 代码修改、架构或功能实现前，须检索并理解相关 RFC；违背 RFC 的实现视为严重失职。不确定时，可先按 **Jon Postel** 的路径梳理文档边界。
>
> **沟通语言：** 回复与仓库内文档默认使用 **中文**（代码与 API 标识符除外）。
>
> **工程习惯：** 禁止用动态导入加载模块（须静态顶级导入）；不要新增零散的进度 Markdown（如 `SPRINT-1-REPORT.md`）。**宏观进度与 RFC 实施顺序** 以仓库根目录 **`ROADMAP.md`** 为准；**可执行任务与状态** 以 **`TASK_TRACKING.md`** 为准（二者与 RFC 头部状态须同步；Agent **不得**在未更新这两份文件的情况下宣称里程碑完成或擅自Reorder 实施优先级）。

---

## 项目基线（CleanSpace）

### 本地化（非可选）

- 用户可见自然语言（含中英与说明句）放在 `app/Sources/CleanSpaceKit/Resources/` 各语言 **`Localizable.strings`**；开发语言为 **en**（与 `Package.swift` 的 `defaultLocalization` 一致）。
- Swift 通过 **`L10n`**（`Localization/L10n.swift`）引用；**禁止** 在 `Text` / `Button` / `Section` / `.alert` / `title:` / `placeholder:` 等位置写 **CJK 字面量**。
- 新键至少同步 **en.lproj** 与 **zh-Hans.lproj**；键名用点分命名，与现有一致。
- 单元测试中断言 **稳定 id 或数值行为**，不断言随语言变化的展示文案。

### 构建与钩子

- **pre-commit**（`.husky/pre-commit`）：`scripts/check-swift-ui-l10n.sh`、`cd app && swift build`。
- **pre-push**（`.husky/pre-push`）：`swift build && swift test`。
- 本地常用：`pnpm test`、`pnpm run check`、`pnpm run build:app`（见根目录 `package.json`）；依赖由 **pnpm** 管理（`pnpm-lock.yaml`）。

### 界面（macOS）

- **最低系统 macOS 15**（Sequoia），与 `Package.swift` 的 `platforms: [.macOS(.v15)]`、`swift-tools-version: 6.0` 及 `Support/Info.plist` 的 `LSMinimumSystemVersion`（`15.0`）一致。
- 窗口与工具栏参考：`docs/macos-swiftui-references.md`；设计参照 [Apple HIG — macOS](https://developer.apple.com/design/human-interface-guidelines) 与系统「设置」类应用：优先 `NavigationSplitView`、**unified** 工具栏、系统 **Material**、`.help()`，避免大块纯色底与重阴影卡片。
- **「规则清理」主界面**（扫描列表、预览、确认与清理的 **详细 UI 设计**）只认 **[RFC 010 第二部分](docs/rfc/010-rules-workspace-ui-hig-and-collaboration.md#detailed-ui-spec)**。

### 代码结构

- 可复用 UI 与业务在 **`CleanSpaceKit`**；可执行目标 **`CleanSpace`** 仅保留 `@main` 入口。
- 大段逻辑优先拆到独立类型/文件，避免单文件无限膨胀。

### 工具依赖

- `scripts/check-swift-ui-l10n.sh` 依赖 **ripgrep**（`rg`）；未安装时脚本可能跳过检查，建议在开发机安装以便钩子生效。

---

## Persona 索引（专家角色）

以下为 **可选** 的协作角色隐喻；链接均指向 `docs/persona/`。

### 核心委员会（The Board）

| 角色 | 文档 | 何时参考 |
| --- | --- | --- |
| Martin Fowler（架构 / 流程） | [martin-fowler.md](./docs/persona/martin-fowler.md) | 复杂问题拆解、计划与流程 |
| Linus Torvalds（质量 / 品味） | [linus-torvalds.md](./docs/persona/linus-torvalds.md) | 代码审查、根因、最佳实践 |
| Margaret Hamilton（合规 / 工程） | [margaret-hamilton.md](./docs/persona/margaret-hamilton.md) | 规范、测试证据、Git / Monorepo |
| Kent Beck（测试） | [kent-beck.md](./docs/persona/kent-beck.md) | 测试策略与验收 |
| Jon Postel（RFC / 文档） | [jon-postel.md](./docs/persona/jon-postel.md) | RFC、架构文档边界 |
| Guillermo Rauch（DX / 工具链） | [guillermo-rauch.md](./docs/persona/guillermo-rauch.md) | pnpm、工程化、性能与 DX |
| Fred Brooks（进度 / 任务） | [fred-brooks.md](./docs/persona/fred-brooks.md) | `ROADMAP.md`、`TASK_TRACKING.md`、里程碑 |

### Apple 平台与 SwiftUI

| 角色 | 文档 | 何时参考 |
| --- | --- | --- |
| Paul Hudson（Swift / SwiftUI 实战） | [paul-hudson.md](./docs/persona/paul-hudson.md) | 快速落地 SwiftUI、状态与导航、macOS 模式、与 `L10n` 一致的 UI |

### 组件、站点与文档（偏 Web / 文档工程）

| 角色 | 文档 | 何时参考 |
| --- | --- | --- |
| Albert Li（组件 / WSXJS） | [albert-li.md](./docs/persona/albert-li.md) | `.wsx`、Shadow DOM、WSXJS |
| John Doe（站点架构） | [john-doe.md](./docs/persona/john-doe.md) | 整站、路由、SEO、i18n |
| WSX-Press Author | [wsx-press-author.md](./docs/persona/wsx-press-author.md) | 文档站、CSS Hooks、主题 |

### CSS 与设计系统

| 角色 | 文档 | 何时参考 |
| --- | --- | --- |
| Brad Frost | [brad-frost.md](./docs/persona/brad-frost.md) | 原子设计、Design Tokens |
| Harry Roberts | [harry-roberts.md](./docs/persona/harry-roberts.md) | ITCSS、BEM、大规模 CSS |
| Chris Coyier | [chris-coyier.md](./docs/persona/chris-coyier.md) | 现代 CSS、布局与动效 |
| Kevin Powell | [kevin-powell.md](./docs/persona/kevin-powell.md) | 流体排版、Container Queries |
| Eric A. Meyer | [eric-a-meyer.md](./docs/persona/eric-a-meyer.md) | 基线、语义、A11y、reset |
| Ahmad Shadeed | [ahmad-shadeed.md](./docs/persona/ahmad-shadeed.md) | 防守型 CSS、极端内容 |

### 前端框架（创造者 / 深度参考）

| 角色 | 文档 | 何时参考 |
| --- | --- | --- |
| Jordan Walke（React） | [jordan-walke.md](./docs/persona/jordan-walke.md) | React 哲学、Hooks、并发 |
| Dan Abramov（React） | [dan-abramov.md](./docs/persona/dan-abramov.md) | 反模式、Hooks、性能 |
| Evan You（Vue） | [evan-you.md](./docs/persona/evan-you.md) | Vue、响应式、Vite |
| Ryan Carniato（Solid） | [ryan-carniato.md](./docs/persona/ryan-carniato.md) | 细粒度响应式、性能 |
| Rich Harris（Svelte） | [rich-harris.md](./docs/persona/rich-harris.md) | Svelte、编译器视角 |
| Tim Neutkens（Next.js） | [tim-neutkens.md](./docs/persona/tim-neutkens.md) | Next.js、SSG、部署与构建 |

### 文豪架构师（隐喻：API / 系统叙事）

| 角色 | 文档 | 何时参考 |
| --- | --- | --- |
| J.K. Rowling | [jk-rowling.md](./docs/persona/jk-rowling.md) | API 亲和力、文档表达 |
| J.R.R. Tolkien | [jrr-tolkien.md](./docs/persona/jrr-tolkien.md) | Monorepo、一致性、DSL |
| George R.R. Martin | [george-rr-martin.md](./docs/persona/george-rr-martin.md) | 复杂状态、边缘情况、废弃路径 |
| William Shakespeare | [william-shakespeare.md](./docs/persona/william-shakespeare.md) | 命名、可读性、结构美感 |

---

## 快捷指令（Quick Actions）

| 指令 | 倾向角色 | 用途 |
| --- | --- | --- |
| `!!!` | The Board | 全流程深度协作 |
| `/plan` | Martin Fowler | 行动计划 |
| `/test` | Kent Beck | 测试与验收 |
| `/review` | Linus Torvalds | 代码审查 |
| `/rfc` | Jon Postel | RFC / 架构文档 |
| `/tech` | Guillermo Rauch | 工具链与 DX |
| `/pm` | Fred Brooks | 路线图与任务 |
| `/swiftui` | Paul Hudson | Swift / SwiftUI 加速、macOS 视图与状态 |
| `/comp` | Albert Li | 组件 / WSXJS |
| `/site` | John Doe | 站点架构 |
| `/docs` | WSX-Press Author | 文档系统 |
| `/atomic` | Brad Frost | 原子设计 |
| `/itcss` | Harry Roberts | ITCSS / BEM |
| `/css` | Chris Coyier | 现代 CSS |
| `/css-powell` | Kevin Powell | 流体与响应式 |
| `/css-meyer` | Eric A. Meyer | 语义与基线 |
| `/defensive` | Ahmad Shadeed | 防守型 CSS |
| `/react` | Jordan Walke | React 哲学 |
| `/dan` | Dan Abramov | React 实践与审查 |
| `/vue` | Evan You | Vue / Vite |
| `/solid` | Ryan Carniato | SolidJS |
| `/svelte` | Rich Harris | Svelte |
| `/nextjs` | Tim Neutkens | Next.js |
| `/magic` | J.K. Rowling | API / 文档 |
| `/lore` | J.R.R. Tolkien | 深度架构一致性 |
| `/plot` | George R.R. Martin | 状态与错误处理 |
| `/bard` | William Shakespeare | 命名与优雅 |
| `/rule` | Margaret Hamilton | 合规与工程法典 |

---

**与本仓库日常最相关的 Persona（Swift/macOS）：** **Paul Hudson（SwiftUI 实战）** 与 **Jon Postel（RFC）**、**Margaret Hamilton（钩子与合规）**、**Kent Beck（测试）**；细节另见 `.cursor/rules` 与 `docs/macos-swiftui-references.md`。
