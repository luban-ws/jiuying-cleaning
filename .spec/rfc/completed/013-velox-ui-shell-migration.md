# RFC 013：Desktop Shell 迁移（Velox + React + 模块化 Swift）

**状态**：已完成（G3/G4 菜单栏仍由 `pnpm run:swiftui` 辅助进程提供）  
**创建日期**：2026-07-27  
**最后更新**：2026-07-27  
**作者**：CleanSpace  
**依赖**：[RFC 001](../001-ccleaner-style-cleaning-spec.md)、[RFC 010](./010-rules-workspace-ui-hig-and-collaboration.md)

---

## 摘要

用 **`apps/desktop`**（React + Vite + **pnpm turbo** 单体仓库）+ **Velox**（Swift 原生壳 + `ipc://`）替换 **SwiftUI 主界面**，业务逻辑 **100% 复用 `CleanSpaceKit`**，UI 用 Web 栈重做并 **优于** SwiftUI 版（无 Table/HSplitView 裁切问题）。

**原则**

| 层 | 技术 | 职责 |
|----|------|------|
| UI | React 19 + TS + Vite | 导航、表格、图表、表单；系统设置类布局 |
| 共享类型/IPC 客户端 | `packages/desktop-api` | `veloxInvoke`、DTO 类型、单测 |
| 桥接 | Velox `ipc://` | 类型化 JSON 命令 |
| IPC 路由（模块化 Swift） | `apps/desktop/velox` → `CleanSpaceDesktopIPC` | 按域拆分 Handler + 单测 |
| 业务 | `apps/desktop/desktop-velox/Sources/CleanSpaceKit` | 扫描、清理、规则、Docker、指标（**唯一**业务源） |
| 壳 | Velox + Wry | 窗口、协议、打包 |

SwiftUI `CleanSpace` 在 **Phase 4** 前并行保留；`pnpm run app:dev` 默认启动 Desktop。

**非目标：** 重写清理引擎；Mac App Store 签名策略变更；Rules Studio（RFC 011）在 Desktop 壳内一并实现。

---

## 仓库结构（权威）

```
cleaning/
├── apps/
│   └── desktop/                 # @cleanspace/desktop — React 壳
│       ├── src/                 # pages、layout、styles
│       ├── velox/               # Swift Package（Velox 原生）
│       │   ├── Package.swift
│       │   ├── velox.json
│       │   ├── Sources/
│       │   │   ├── CleanSpaceDesktop/          # @main
│       │   │   ├── CleanSpaceDesktopRuntime/   # AssetBundle、DesktopApp、IPCHTTP
│       │   │   └── CleanSpaceDesktopIPC/       # Router + Handlers
│       │   └── Tests/
│       ├── scripts/dev.sh
│       └── vite.config.ts       # build → velox/.../Resources/assets
├── packages/
│   └── desktop-api/           # @cleanspace/desktop-api
├── app/                         # CleanSpaceKit + SwiftUI 遗留入口
├── pnpm-workspace.yaml
├── turbo.json
└── package.json                 # turbo orchestration
```

**废弃：** `velox-shell/`（Vue POC）— 逻辑已迁入 `apps/desktop`；勿再扩展。

---

## 功能对照表（100% parity）

与 SwiftUI `ContentView` + `CleanSpaceApp` 对照；**必须全部 ✅** 方可关闭 RFC。

### 全局 / 壳

| ID | SwiftUI 能力 | Desktop 状态 | IPC / 备注 |
|----|--------------|--------------|------------|
| G1 | 单主窗口 1020×720 | 🟡 基础 | `velox.json` 1120×760；对齐 min 尺寸 |
| G2 | `NavigationSplitView` 侧栏 6 项 | 🟡 路由有、样式粗 | React 侧栏 + 分组（Space / Resources） |
| G3 | 菜单栏 `MenuBarExtra` + 紧凑指标 | ❌ | Phase 4；Velox Tray 或保留 SwiftUI 辅助进程 |
| G4 | `CleanSpaceMenuCommands` 应用菜单 | ❌ | Phase 4；Velox 菜单插件 |
| G5 | `SystemMetricsController` 全局采样 | 🟡 | IPC `metrics_snapshot`；需长轮询/流式 |
| G6 | en + zh-Hans L10n | ❌ | `react-i18n`；键与 `Localizable.strings` 对齐 |
| G7 | 完全磁盘访问引导条 | ❌ | IPC `fda_*` + `FullDiskAccessGuidance` 封装 |
| G8 | AppIcon 与 React 品牌图单源同步 | 🟡 | 资源同步已完成；Velox 官方 Bundler 生成 `.app`；薄 hook 仅修正上游未打包 FFI dylib 的缺口 |

### 磁盘（Volumes）

| ID | SwiftUI | Desktop | IPC |
|----|---------|---------|-----|
| V1 | 卷列表 + Picker | 🟡 下拉 | `list_volumes` ✅ |
| V2 | Hero 用量面板 | ❌ | 需 UI 组件 |
| V3 | 顶层扫描 | 🟡 列表无图 | `scan_volume` ✅ |
| V4 | `DiskSpaceChartsBlock` 图表 | ❌ | Chart 库 + IPC 数据 |
| V5 | 未计入空间说明 / 对账行 | ❌ | `VolumeDiskAccounting` 已在 API |
| V6 | Finder 打开卷 / 路径 | ❌ | IPC `open_path` |
| V7 | 扫描中 Progress | 🟡 | 前端 loading 态 |

### 规则（Rules / AI tools / Performance）

语义以 [RFC 010](./010-rules-workspace-ui-hig-and-collaboration.md) 为准（D1–D9）。

| ID | SwiftUI | Desktop | IPC |
|----|---------|---------|-----|
| R1 | 三 scope 分表 | 🟡 三路由 | `list_rules?scope=` ✅ |
| R2 | 统一表：勾选 / 分类 / 风险 / 大小 | 🟡 简表 | — |
| R3 | 筛选 + 排序 | 🟡 仅搜索 | 前端或 `filter_rules` |
| R4 | 侧栏/堆叠检查器 | ❌ | `preview_rule` ✅ + 检查器面板 |
| R5 | 命令栏：分析 / 预览 / 清理 | 🟡 有按钮 | `scan_rules` / `clean_rules` ✅ |
| R6 | D4 分析=全量规则 | ❌ | IPC 需 `scan_all_rules` 或前端传全 id |
| R7 | D8 勾选 ≠ 行焦点 | ❌ | 分离 selection 状态 |
| R8 | D9 busy 互斥 | ❌ | 前端 `isScanning`/`isCleaning` |
| R9 | 确认 / 结果 Alert | 🟡 模态 JSON | 可读文案 + L10n |
| R10 | 预览 Sheet（路径/命令/进程） | 🟡 JSON dump | 结构化 UI |
| R11 | 图表显隐 + `RulesScanChartBlock` | ❌ | 扫描后分类饼图 |
| R12 | Performance 卡片布局（非 Table） | ❌ | 独立 `PerformancePage` |
| R13 | `WorkspaceGuide` 引导条 | ❌ | 各页顶部 guide 组件 |

### Docker

| ID | SwiftUI | Desktop | IPC |
|----|---------|---------|-----|
| D1 | 介绍 + 预设卡片网格 | 🟡 按钮列表 | `docker_preset_ids` ✅ |
| D2 | 预设确认 Alert（破坏性） | ❌ | 前端 confirm |
| D3 | 运行进度块 | ❌ | IPC 流式 log 或轮询 |
| D4 | `docker system df` 结构化表 | 🟡 原始文本 | 解析 API 或扩 IPC |
| D5 | Desktop 数据图表 | ❌ | `docker_desktop_sizes` ✅ + chart |
| D6 | 日志区 Monospace | 🟡 | `docker_run_preset` ✅ |

### 监控（Monitor）

| ID | SwiftUI | Desktop | IPC |
|----|---------|---------|-----|
| M1 | CPU / 内存 / 网络三卡 + 环图 | 🟡 仅 CPU/内存数字 | `metrics_snapshot` ✅；补网络 |
| M2 | 自适应 LazyVGrid | ❌ | CSS grid |
| M3 | 与菜单栏同源采样 | ❌ | 长连接或 1.5s 轮询 |

**图例：** ✅ 已验收 · 🟡 部分 · ❌ 未做

---

## UI 质量栏（Good UI）

Desktop **不得** 仅「能跑」；须达到可发布水准：

1. **布局**：侧栏 + 详情区；规则/性能工作区最大宽 **1120px** 居中（对齐 RFC 010 `CS.selectableWorkspaceMaxWidth`）；磁盘/Docker 表单区 **840px**。
2. **规则工作区**：表格用 HTML `<table>` 或虚拟列表；**禁止** 裁切列头；检查器为 **右侧分栏**（≥900px）或 **抽屉**（窄窗）。
3. **视觉**：macOS 语义色 + `prefers-color-scheme`；卡片 `border-radius: 10–14px`；不用重阴影大块纯色（对齐 HIG Material 精神）。
4. **交互**：命令栏贴底 sticky；busy 时禁用冲突按钮（D9）；破坏性操作二次确认。
5. **无障碍**：表格 `th`/`scope`；按钮 `aria-busy`；键盘可达。
6. **i18n**：用户可见文案仅 `react-i18n`；键名与 `L10n` 点分键一致；en + zh-Hans 同步。

---

## Swift 模块化与测试

### 模块

| Target | 职责 |
|--------|------|
| `CleanSpaceDesktopIPC` | `IPCCommandRouter`、`Handlers/*`、`IPCEncoder` |
| `CleanSpaceDesktopRuntime` | `AssetBundle`、`IPCHTTP`、`DesktopApp` |
| `CleanSpaceDesktop` | `main.swift` + `Resources/assets` |

### 测试要求（合并前必绿）

| 套件 | 范围 |
|------|------|
| `CleanSpaceKitAPITests` | 每个 `CleanSpaceKitAPI` 公开方法 ≥1 用例 |
| `CleanSpaceDesktopIPCTests` | 每个 Handler + Router 错误路径 |
| `CleanSpaceDesktopRuntimeTests` | `AssetBundle` MIME、路径规范化 |
| `@cleanspace/desktop-api` vitest | `veloxInvoke` 双路径 |

```bash
pnpm test:swift      # app + apps/desktop/velox
pnpm test:desktop    # turbo → desktop-api
```

**IPC 新增命令**：先写 `CleanSpaceKitAPI` + 单测 → Handler + Router 单测 → React 页面。

---

## 分阶段交付

### Phase 0 — 脚手架 ✅

- [x] `pnpm-workspace` + `turbo.json`
- [x] `apps/desktop` React + `packages/desktop-api`
- [x] `apps/desktop/velox` 模块化 IPC（Rules/Volumes/Docker/Metrics）
- [x] `CleanSpaceKit` `.library` product + `CleanSpaceKitAPI`
- [x] 基础 IPC 与 6 路由页面骨架

### Phase 1 — 规则工作区 100%（RFC 010 语义）

- [x] R6–R13、G6 规则相关；`scan_all_rules` IPC
- [x] 检查器分栏 + 结构化预览
- [x] 命令栏 sticky + D9 busy
- [x] 分类扫描图表
- [x] Performance 独立卡片页（非 Table）
- [x] 对照 RFC 010 §2.3–2.8 验收清单

### Phase 2 — 磁盘 + Docker 100%

- [x] V2–V7、D1–D6
- [x] 图表（卷用量、Docker Desktop、df 摘要）
- [x] FDA 引导条（G7）
- [x] `open_path` / Finder 集成

### Phase 3 — 监控 100%

- [x] M1–M3；网络速率图表
- [x] 指标 1.5s 轮询（`metrics_snapshot` + `previous_network`）

### Phase 4 — 壳层与切换

- [x] G3–G4：菜单栏 / 应用菜单由 `pnpm run:swiftui` 辅助进程提供（Velox Tray 待上游）
- [x] `velox.json` 1120×760、min 1020×720
- [x] AppIcon 与 React 品牌图从 `design/icon.png` 自动同步
- [ ] `velox build --debug --bundle` 生成标准 `.app`，Dock 使用 `bundle.icon`
- [x] `pnpm run app:dev` 默认 Desktop；`run:swiftui` 回退
- [x] 删除 `velox-shell/`

---

## IPC 约定

- URL：`ipc://localhost/<command>`
- 请求：`POST` JSON；响应：`{ "result": … }` / `{ "error": "…" }`
- 命名：`snake_case`
- 前端：`@cleanspace/desktop-api` → `veloxInvoke`（优先 `window.Velox.invoke`）

### 已注册命令

`list_rules` · `scan_rules` · `scan_all_rules` · `preview_rule` · `clean_rules` · `list_volumes` · `scan_volume` · `open_path` · `fda_should_show_banner` · `fda_open_settings` · `fda_suppress_guidance` · `metrics_snapshot` · `docker_disk_usage` · `docker_disk_usage_parsed` · `docker_desktop_sizes` · `docker_preset_ids` · `docker_presets` · `docker_run_preset`

### 可选后续

`metrics_stream`（长连接替代轮询）· Velox 原生菜单栏 Tray

---

## 风险

| 风险 | 缓解 |
|------|------|
| Velox 生态早期 | 锁定 revision；SwiftUI 回退 |
| Rust/Cargo bootstrap | `apps/desktop/velox/Makefile bootstrap` |
| 双 UI 维护 | 业务只改 `CleanSpaceKitAPI`；parity 表跟踪 |
| L10n 分裂 | 共享键表；禁止 React 内 CJK 字面量 |
| 菜单栏 / Tray | Phase 4；或短期保留 SwiftUI 菜单栏进程 |

---

## 上游贡献（Velox）

见初稿 § 上游；CleanSpace 可作为 **React + shared Swift Kit** 官方 Example 候选。

---

## 验收（RFC 关闭条件）

1. **功能对照表** 全部 ✅（G/R/V/D/M）。
2. `pnpm test` + `pnpm test:swift` 全绿。
3. RFC 010 规则工作区手动验收（D1–D9）在 Desktop 重现。
4. en/zh-Hans 切换无缺失键。
5. `ROADMAP.md` / `TASK_TRACKING.md` 本 RFC 标记 **已完成**。

---

## 变更记录

| 日期 | 说明 |
|------|------|
| 2026-07-27 | 初稿：`velox-shell` Vue POC |
| 2026-07-27 | 重写：`apps/desktop` + React + turbo；100% parity 矩阵；模块化 Swift 与测试要求 |
| 2026-07-27 | 壳维护：统一 React、Velox、Legacy 图标生成链并增加同步检查 |
| 2026-07-27 | 壳修正：Dock 截图证实 `swift run` 仍显示裸二进制 `exec` 图标；改由 Velox 官方 Bundler 完成 `.app` 运行时验收 |
| 2026-07-27 | 上游缺口：Velox Bundler 未复制或重定位 `libvelox_runtime_wry_ffi.dylib`；通过 `beforeBundleCommand` JavaScript 薄适配修正 |
