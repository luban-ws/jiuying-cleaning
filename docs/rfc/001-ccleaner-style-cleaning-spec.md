# RFC 001：CCleaner 式清理规范

**状态**：实施中（规范正文仍可迭代；**顺序/阶段/状态表**以仓库根目录 **`ROADMAP.md`** 为准，**任务拆解**以 **`TASK_TRACKING.md`** 为准）  
**创建日期**：2026-02-21  
**作者**：CleanSpace  

---

## 摘要

参考 **CCleaner** 的清理能力（浏览器、系统临时文件、回收站、应用缓存），在 **macOS** 上限定 CleanSpace 的清理范围，重点覆盖 **浏览器**、**Docker** 与 **AI 工具**（如 Cursor、Antigravity）。本 RFC 只规定**能清理什么**以及**对应路径**，不规定界面或实现顺序。

---

## 背景与问题

- 用户希望在一个地方回收浏览器、Docker 和 AI  IDE 占用的空间。
- 若没有明确规范，“清理浏览器”或“清理 Docker”含义模糊（清哪些路径？执行什么操作？）。
- CCleaner 提供了清晰的心智模型：分类（系统 vs 应用）、子项（缓存、Cookie、历史记录）以及可选的“自定义包含/排除”。
- CleanSpace 必须明确且安全：只针对已定义的位置，且仅执行可逆或风险已说明的操作。

---

## 目标

1. **定义清理分类**：与 CCleaner 对齐（系统 vs 应用），并映射到 macOS 与我们的目标（浏览器、Docker、AI 工具）。
2. **列出每类可清理项**：路径、类型（缓存/Cookie/历史/临时）及清理方式（删目录、清库、执行 CLI）。
3. **支持配置驱动**：通过配置即可新增浏览器或 AI 工具，无需改代码（路径 + 规则即可）。
4. **兼顾安全与可逆性**：不通过修改注册表/plist 做“清理”；优先“删除缓存”而非“改配置”。
5. **长期能力：支持用户定义清理规则**：产品应具备“由用户/高级用户**定义**清理规则”的能力，而不仅依赖内置配置；新应用、新目录或团队共享规则均可通过同一套规则格式扩展。

---

## 与 CCleaner 的对应关系（参考）

| CCleaner 概念       | CleanSpace 在 macOS 上的对应 |
|---------------------|-------------------------------|
| Windows / 系统      | macOS：废纸篓、系统/用户缓存、Xcode 派生数据（可选） |
| 应用程序           | 浏览器、Docker、AI 工具       |
| 回收站             | 废纸篓（`~/.Trash`）         |
| 临时文件           | `/var/folders`、`~/Library/Caches`、应用临时目录 |
| 浏览器缓存/Cookie  | 见下文各浏览器路径           |
| 自定义文件/文件夹  | 配置中的用户路径（包含/排除） |
| 注册表             | macOS 无；本产品不通过修改 plist 做“清理” |
| 驱动器擦除/安全删除 | 本 RFC 不涉及                 |

---

## 方案：CleanSpace 可清理内容

### 1. 系统（macOS）

| 项目           | 路径 / 操作 | 风险   | 说明 |
|----------------|-------------|--------|------|
| 用户废纸篓     | `~/.Trash`  | 低     | 清空废纸篓（与 Finder 一致）。 |
| 用户缓存       | `~/Library/Caches`（可按应用或整体可选） | 中 | 部分缓存会加速应用；可提供“仅大项”或排除列表。 |
| Xcode DerivedData | `~/Library/Developer/Xcode/DerivedData` | 低 | 再次编译会重新生成。 |
| Xcode 归档     | `~/Library/Developer/Xcode/Archives` | 低 | 旧归档。 |
| 用户临时目录   | `$TMPDIR` 或 `~/Library/Caches` 下临时子目录 | 中 | 按应用；清理前按大小列出。 |

*v1 不清理系统级 `/private/var/folders` 或 root 缓存；仅操作用户可写路径。*

---

### 2. 浏览器

按浏览器定义**清理项**与**路径**。具体“怎么清”（删目录还是调浏览器 API）可放在后续 RFC。

#### 2.1 Google Chrome

| 项目           | 路径 / 范围 | 可安全删除？ |
|----------------|-------------|--------------|
| 缓存           | `~/Library/Caches/Google/Chrome` | 是 |
| Application Cache | `~/Library/Application Support/Google/Chrome/*/Application Cache` | 是 |
| Code Cache     | `~/Library/Application Support/Google/Chrome/*/Code Cache` | 是 |
| GPUCache       | `~/Library/Application Support/Google/Chrome/*/GPUCache` | 是 |
| Cookie         | `~/Library/Application Support/Google/Chrome/*/Cookies`（SQLite） | 是（会退出网站登录） |
| 历史记录       | `~/Library/Application Support/Google/Chrome/*/History`（SQLite） | 是 |
| 本地存储       | `~/Library/Application Support/Google/Chrome/*/Local Storage` | 是 |
| 会话存储       | 仅内存/会话 | N/A |
| 崩溃报告       | `~/Library/Application Support/Google/Chrome/Crashpad` | 是 |
| 着色器缓存     | `~/Library/Application Support/Google/Chrome/*/ShaderCache` | 是 |

*默认配置为 `Default`；多配置路径为 `Application Support/Google/Chrome/<配置名>/` 下相同结构。*

#### 2.2 Safari

| 项目           | 路径 / 范围 | 可安全删除？ |
|----------------|-------------|--------------|
| 缓存           | `~/Library/Caches/com.apple.Safari` | 是 |
| 本地存储/数据库 | `~/Library/Safari/LocalStorage`、`Databases` 等 | 是（可能重置站点数据） |
| 历史记录       | `~/Library/Safari/History.db`（SQLite） | 是 |
| 下载列表       | 仅 Safari 元数据；实际文件在 `~/Downloads` | 可选 |

*也可通过系统设置 / 隐私 清理 Safari；此处列出路径便于脚本化与行为一致。*

#### 2.3 Firefox

| 项目           | 路径 / 范围 | 可安全删除？ |
|----------------|-------------|--------------|
| 缓存           | `~/Library/Caches/Firefox` | 是 |
| 配置档缓存     | `~/Library/Application Support/Firefox/Profiles/*/cache2` | 是 |
| Cookie/存储    | 配置档内 `*.default*` 等 SQLite 文件 | 是（会退出登录） |
| 崩溃报告       | `~/Library/Application Support/Firefox/Crash Reports` | 是 |

*配置档路径一般为 `~/Library/Application Support/Firefox/Profiles/<随机>.default-release` 等。*

#### 2.4 Edge（Chromium）

与 Chrome 结构相同，路径为：

- `~/Library/Application Support/Microsoft Edge`
- `~/Library/Caches/Microsoft Edge`

清理项与 Chrome 相同（缓存、Cookie、历史、Code Cache、GPUCache 等）。

#### 2.5 Arc、Brave、Opera（Chromium 系）

- **Arc**：`~/Library/Application Support/Arc`，`~/Library/Caches/Arc`
- **Brave**：`~/Library/Application Support/BraveSoftware/Brave-Browser`，`~/Library/Caches/BraveSoftware`
- **Opera**：`~/Library/Application Support/com.operasoftware.Opera`，`~/Library/Caches/com.operasoftware.Opera`

逻辑项与 Chrome 相同（缓存、Cookie、历史、Code Cache 等）；路径遵循 Chromium 布局。

---

### 3. Docker

规定 CleanSpace **能清理什么**以及**如何清理**（CLI 或路径）。路径级清理仅作为“彻底重置”的可选项。

#### 3.1 通过 Docker CLI（推荐用于回收空间）

| 操作               | 命令 / 行为 | 风险 |
|--------------------|-------------|------|
| 移除已停止的容器   | `docker container prune -f` | 低 |
| 移除未使用镜像     | `docker image prune -a -f`（可选 `-a` 清理全部未使用） | 中（需重新拉取） |
| 移除未使用卷       | `docker volume prune -f` | 中（若卷内有重要数据会丢失） |
| 移除构建缓存       | `docker builder prune -a -f` | 低 |
| 系统清理           | `docker system prune -a -f`（容器、网络、镜像、构建缓存） | 中（较激进） |
| 回收磁盘空间       | `docker run --privileged --pid=host docker/desktop-reclaim-space`（在 prune 之后） | 低 |

CleanSpace 可将上述作为**选项**提供（如“仅容器”“镜像+构建缓存”“完整系统清理”），并配清晰说明与可选确认。

#### 3.2 路径级（Docker Desktop 残留）

仅在用户选择“移除 Docker 数据”或“卸载后清理”时提供：

| 项目               | 路径 | 说明 |
|--------------------|------|------|
| Docker Desktop 数据 | `~/Library/Group Containers/group.com.docker` | 设置、虚拟机数据 |
| Docker 配置        | `~/.docker` | 配置、上下文 |
| Docker 应用支持   | `~/Library/Application Support/Docker Desktop` | |
| Docker 缓存       | `~/Library/Caches/Docker Desktop` | |
| 容器（应用）      | `~/Library/Containers/com.docker.docker` | |

*删除上述路径会 effectively 重置 Docker Desktop；仅在用户明确确认、且 preferably Docker 未运行时提供。*

---

### 4. AI 工具（Cursor、Antigravity 等）

基于 Electron/VS Code；缓存与数据位于 `~/Library/Application Support` 与 `~/Library/Caches`。规定**可清理项**与**路径**，便于后续用配置扩展。

#### 4.1 Cursor

| 项目           | 路径 / 范围 | 可安全删除？ |
|----------------|-------------|--------------|
| 缓存           | `~/Library/Application Support/Cursor/Cache` | 是 |
| CachedData     | `~/Library/Application Support/Cursor/CachedData` | 是 |
| CachedExtensions | `~/Library/Application Support/Cursor/CachedExtensions` | 是（扩展会重新下载） |
| Code Cache     | `~/Library/Application Support/Cursor/Code Cache` | 是 |
| GPUCache       | `~/Library/Application Support/Cursor/GPUCache` | 是 |
| 崩溃/日志      | `~/Library/Application Support/Cursor/logs`、崩溃转储 | 是 |
| 全局缓存       | `~/Library/Caches/Cursor` | 是 |
| 索引/工作区    | `~/Library/Application Support/Cursor/User/workspaceStorage` | 中（工作区状态；可按大小列出） |

*不删除 `User/settings.json` 或快捷键配置；仅清理缓存/索引/临时。*

#### 4.2 Antigravity（及同类基于 VS Code 的 AI IDE）

| 项目           | 路径 / 范围 | 可安全删除？ |
|----------------|-------------|--------------|
| 缓存           | `~/Library/Application Support/Google Antigravity/Cache`（或实际应用名） | 是 |
| CachedData     | `~/Library/Application Support/.../CachedData` | 是 |
| Code Cache/GPU | 与 Cursor 相同模式 | 是 |
| 日志/崩溃      | `~/Library/Application Support/.../logs` | 是 |
| 全局缓存       | `~/Library/Caches/...` 下对应应用名 | 是 |

*实际文件夹名可能因安装方式不同；CleanSpace 应支持**配置中定义**的应用名与路径，以便新增 AI 工具时无需改代码。*

#### 4.3 通用“AI/IDE”规则模板

后续工具可在配置中增加类似条目：

```yaml
id: my-ai-tool
name: "我的 AI IDE"
paths:
  - base: "~/Library/Application Support/MyAI"
    dirs: ["Cache", "CachedData", "Code Cache", "GPUCache", "logs"]
  - base: "~/Library/Caches/MyAI"
    dirs: ["*"]  # 或列出具体子目录
warning: "清理后可能需要重新下载模型或扩展。"
```

通过配置即可扩展“能清理什么”和“路径”。

---

## 如何定义清理规则

所有可清理项统一用**清理规则**描述，便于配置驱动、扫描与执行一致。

### 规则通用字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 是 | 唯一标识，建议小写+连字符，如 `chrome-cache`。 |
| `category` | string | 是 | 分类：`system` / `browser` / `docker` / `ai-tools`。 |
| `name` | string | 是 | 界面显示名称，如「Chrome 缓存」。 |
| `type` | string | 是 | 清理方式：`dir`（删目录）、`command`（执行命令）。 |
| `risk` | string | 否 | 风险等级：`low` / `medium` / `high`，用于提示与确认。默认 `low`。 |
| `warning` | string | 否 | 执行前展示的警告文案（如会退出登录、需重新下载等）。 |

### 按 type 的差异化字段

**`type: dir`**（按路径删除目录）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `paths` | array | 是 | 路径列表，见下。 |

每个 `paths` 元素：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `base` | string | 是 | 基础路径，支持 `~`。 |
| `dirs` | array | 是 | 相对 `base` 的子目录名列表；`"*"` 表示 `base` 下全部子目录。 |

扫描时：对每个 `base/dir` 计算占用；清理时：删除对应目录（若不存在则跳过）。

**`type: command`**（执行 CLI，如 Docker prune）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `command` | string | 是 | 要执行的 shell 命令（如 `docker container prune -f`）。 |
| `estimate` | string | 否 | 无法预先扫描时的说明，如「依当前容器/镜像而定」。 |

扫描时：可显示 `estimate` 或跳过大小；清理时：在子进程执行 `command`。

### 完整示例

**系统 - 废纸篓**

```yaml
id: trash
category: system
name: "废纸篓"
type: dir
risk: low
paths:
  - base: "~/.Trash"
    dirs: ["*"]
```

**系统 - Xcode DerivedData**

```yaml
id: xcode-derived-data
category: system
name: "Xcode DerivedData"
type: dir
risk: low
warning: "清理后下次编译会稍慢。"
paths:
  - base: "~/Library/Developer/Xcode/DerivedData"
    dirs: ["*"]
```

**浏览器 - Chrome 缓存**

```yaml
id: chrome-cache
category: browser
name: "Chrome 缓存"
type: dir
risk: low
paths:
  - base: "~/Library/Caches/Google/Chrome"
    dirs: ["*"]
  - base: "~/Library/Application Support/Google/Chrome"
    dirs: ["Default/Application Cache", "Default/Code Cache", "Default/GPUCache"]
```

**浏览器 - Chrome Cookie/历史（会退出网站登录）**

```yaml
id: chrome-cookies-history
category: browser
name: "Chrome Cookie 与历史"
type: dir
risk: medium
warning: "将清除网站登录状态与浏览历史。"
paths:
  - base: "~/Library/Application Support/Google/Chrome/Default"
    dirs: ["Cookies", "History", "Local Storage"]
```

**Docker - 系统清理（CLI）**

```yaml
id: docker-system-prune
category: docker
name: "Docker 系统清理（未使用容器/镜像/卷/构建缓存）"
type: command
risk: medium
warning: "将删除未使用的容器、镜像、卷与构建缓存，需重新拉取镜像时会更慢。"
command: "docker system prune -a -f"
estimate: "依当前未使用资源而定"
```

**Docker - 仅构建缓存**

```yaml
id: docker-builder-prune
category: docker
name: "Docker 构建缓存"
type: command
risk: low
command: "docker builder prune -a -f"
estimate: "依构建缓存大小而定"
```

**AI 工具 - Cursor 缓存**

```yaml
id: cursor-cache
category: ai-tools
name: "Cursor 缓存与扩展缓存"
type: dir
risk: low
warning: "扩展可能需重新下载。"
paths:
  - base: "~/Library/Application Support/Cursor"
    dirs: ["Cache", "CachedData", "CachedExtensions", "Code Cache", "GPUCache", "logs"]
  - base: "~/Library/Caches/Cursor"
    dirs: ["*"]
```

### 配置文件放置与格式

- **内置规则**：`app/Sources/CleanSpaceKit/Resources/cleaning-rules.json`（随应用打包，从 SwiftPM 模块 `Bundle.module` 读取）。格式支持 **JSON** 或 **YAML**；当前实现使用 JSON，顶层为规则数组 `[ ... ]`。
- **用户规则**：`~/Library/Application Support/CleanSpace/user-cleaning-rules.json`（若存在则与内置合并；同 `id` 时用户规则覆盖内置）。可选后续支持 `user-cleaning-rules.yaml`。
- 规则格式：每条规则字段见上文「规则通用字段」与「按 type 的差异化字段」；JSON 即相同结构的数组，YAML 可为 `rules: [ ... ]` 或直接 `[ ... ]`。

### 在 Mac 应用中的用法

应用启动后，规则在 Xcode Mac 应用内按以下方式使用，RFC 约定行为以保证实现一致。

**规则来源与加载**

- 启动时调用“合并加载”：先读内置 `cleaning-rules.json`，再读用户规则文件（若存在），按 `id` 合并（用户覆盖内置），得到唯一规则列表。
- 规则列表按 `category` 分组，分组顺序建议：system → browser → docker → ai-tools → custom（若有）。

**界面行为**

- **侧栏**：按分类展示所有规则，每条规则一行，显示名称、可选警告摘要、风险标签（中/高）；支持勾选/取消勾选以参与本次清理。
- **详情区**：展示“已加载 N 条规则”说明，以及：
  - **扫描占用**：对每条 `type: dir` 的规则在后台计算路径占用（字节），结果展示在该行；`type: command` 可展示配置中的 `estimate` 文案。
  - **清理选中项**：仅对用户勾选的规则执行清理；执行前弹窗确认，若存在中/高风险规则须在确认文案中说明。
- **清理执行**：对每条选中规则：`type: dir` 删除规则解析出的路径（不存在则跳过）；`type: command` 通过 `/bin/sh -c` 执行 `command`。执行后展示结果摘要（成功/失败及信息）。

**增改规则**

- **改内置**：编辑 `app/Sources/CleanSpaceKit/Resources/cleaning-rules.json`，保持与本节及上文规则 schema 一致，重新构建运行即可。
- **用户自定义**：在 `~/Library/Application Support/CleanSpace/` 下创建或编辑 `user-cleaning-rules.json`（同一 JSON 数组结构），应用下次启动或重新加载时合并；同 `id` 覆盖内置。长期可增加设置页“自定义规则”的增删改与导入/导出。

**安全**

- 无勾选不执行任何删除或命令；中/高风险规则在确认弹窗中明确提示；用户规则路径与命令限制见「长期能力：用户定义清理规则」中的安全与校验。

### 多配置/多 profile（浏览器）

Chrome 等有多配置时，可用一条规则 + 多个 `paths.base` 覆盖各 profile，或在配置中用变量（如 `{profile}`）由实现解析；v1 可采用“写死 Default + 常见第二 profile”或“扫描 `Application Support/Google/Chrome` 下所有子目录再按规则匹配”。

---

## 长期能力：用户定义清理规则

为支持长期扩展与不同用户场景，CleanSpace 应具备**由用户定义清理规则**的能力：用户或高级用户可新增、编辑、禁用规则，而不仅依赖应用内置配置。

### 能力目标

- **扩展无需发版**：新应用、新缓存目录出现时，用户可通过新增规则支持，无需等待应用更新。
- **同一套规则格式**：用户定义的规则与内置规则使用同一 schema（见上文「如何定义清理规则」），实现只做“来源”区分（内置 vs 用户）。
- **可选界面**：提供“自定义规则”入口：新增/编辑/删除/启用/禁用；或仅支持通过配置文件编辑，由高级用户使用。
- **共享与复用**：支持导出、导入规则（单条或整份 YAML），便于团队或社区共享。

### 用户规则存放与合并

- **路径**：用户规则放在 `~/Library/Application Support/CleanSpace/user-cleaning-rules.yaml`（或 `custom-rules.yaml`）。若存在则与内置规则合并展示；合并时用户规则可带标记（如「自定义」）并允许单独启用/禁用。
- **合并策略**：内置规则与用户规则合并为同一列表；`id` 若冲突，以用户规则覆盖内置（或禁止用户使用与内置同 id，由实现选择）。可选：用户规则中支持 `disableBuiltinIds: [id1, id2]` 以禁用指定内置规则。

### 安全与校验

- **路径限制**：用户规则中的 `base` 仅允许用户可写路径，例如限定为 `~` 或 `~/Library` 下，禁止 `/System`、`/usr` 等系统路径，防止误删系统文件。
- **命令限制**：`type: command` 的用户规则需谨慎：可仅允许白名单命令（如 `docker …`），或对任意命令做二次确认并标记为「高风险」。
- **风险默认**：用户新增规则时，未填 `risk` 则视为 `medium`，并在首次清理前给予明确提示。

### 分类扩展

- 用户规则可使用现有分类（`system` / `browser` / `docker` / `ai-tools`），或使用扩展分类如 `custom`；界面中「自定义」分类下列出所有用户定义规则，便于管理。

### 实现阶段建议

- **v1（当前）**：内置规则使用 `cleaning-rules.json`，支持从 `~/Library/Application Support/CleanSpace/user-cleaning-rules.json` 读取并合并（同 id 用户覆盖内置）；界面提供按分类展示、扫描占用、勾选后清理，无单独“编辑规则”入口。
- **后续**：可选支持 YAML 用户规则（`user-cleaning-rules.yaml`）；增加设置页「自定义规则」的增删改与导入/导出。

---

## 实现要点（高层）

- **数据模型**：每条“清理规则”对应一项或一组，包含：分类（system/browser/docker/ai-tools）、显示名、路径、类型（dir/sqlite/command）、可选 CLI 命令、风险等级。
- **配置文件**：YAML 或 JSON，放在 `app/Sources/CleanSpaceKit/Resources/` 或用户应用支持目录，列出全部规则；新增浏览器或 AI 工具即新增配置项。
- **扫描阶段**：按规则计算占用（目录大小或预定义）；展示列表与预估可回收空间。
- **清理阶段**：按用户勾选执行删除路径、执行 `docker … prune` 或调用脚本；记录操作便于审计（撤销可单独 RFC）。
- **安全**：无用户勾选不删除；可选“预演”（仅列出将删除项）；不编辑 plist/注册表；Docker 路径删除需强确认。

---

## 已考虑的替代方案

- **调用浏览器/IDE API**：更精确但需逐应用对接，且未必有“仅清缓存”的 API；基于路径的清理更简单、跨版本可用。
- **Docker 仅用 CLI**：不做路径级 Docker 清理，只提供 `docker system prune`；对多数用户足够；路径级保留给“彻底重置”或卸载后清理。
- **注册表/plist 清理**：v1 不做；风险高且与“仅回收空间”目标不符。

---

## 风险与注意

- **Cookie/历史删除**：用户可能丢失登录或历史；界面须明确提示。
- **Docker 卷清理**：可能删除含数据的命名卷；须警告并可选择排除命名卷。
- **AI 工具缓存**：清理 Cursor/Antigravity 缓存可能导致重新下载或首次启动变慢；在界面中说明。
- **权限**：部分路径可能需要“完全磁盘访问”；仅在用户启用对应分类时再申请。

---

## 测试策略

- **单元**：对模拟路径做大小计算；规则加载（配置 → 内存规则）。
- **集成**：在开发机上对真实路径执行“扫描”；验证不崩溃且大小合理。
- **清理**：在虚拟机或临时账号中执行：清理某一浏览器后确认缓存/Cookie 已清且应用仍可启动；执行 Docker prune 确认空间释放；清理 AI 工具缓存后确认应用仍可用。
- **安全**：确认无用户操作不执行删除；对高风险（Docker 路径删除、卷清理）做确认弹窗。

---

## 总结：CleanSpace 可清理项一览

| 分类     | 可清理内容 |
|----------|------------|
| **系统** | 用户废纸篓；用户缓存（可选）；Xcode DerivedData/Archives；用户临时目录。 |
| **浏览器** | Chrome、Safari、Firefox、Edge、Arc、Brave、Opera：缓存、Cookie、历史、Code Cache、GPU 缓存、崩溃报告（基于路径）。 |
| **Docker** | 已停止容器；未使用镜像/卷；构建缓存；系统清理；回收空间（CLI）。可选路径级 Desktop 清理（需确认）。 |
| **AI 工具** | Cursor：Cache、CachedData、CachedExtensions、Code Cache、GPUCache、日志、workspaceStorage（可选）。Antigravity 等：通过配置采用相同模式。支持配置驱动的新 AI IDE。 |

本 RFC 界定 CleanSpace 的**清理行为范围**，并将**支持用户定义清理规则**列为长期能力（同一规则格式、用户规则文件、路径/命令安全约束、可选 UI 与导入导出）。实现顺序与界面由后续工作决定。
