# CleanSpace

macOS 原生清理工具：Velox + React 壳，业务在 Swift `CleanSpaceKit`。按规则扫描与清理浏览器缓存、Docker、AI 工具缓存等；「磁盘」页查看卷空间与顶层目录占用。

## 环境要求

- **系统**：macOS 15 及以上（见 `apps/desktop/desktop-velox/Package.swift` 与 `Support/Info.plist`）。
- **构建**：本机已安装 **Swift** 与 **Apple 平台 SDK**（`xcode-select --install` 的 Command Line Tools 即可，**不必**打开 Xcode.app）。
- **可选**：**Node.js 18+** 与 **pnpm**（用于 Husky 与根目录脚本封装；可用 [Corepack](https://nodejs.org/api/corepack.html) 对齐 `package.json` 里的 `packageManager` 字段）；**rsvg-convert**（`brew install librsvg`，从 SVG 再生应用图标 PNG）。

## 克隆后

```bash
corepack enable   # 可选：按 package.json 的 packageManager 固定 pnpm 版本
pnpm install
```

会安装 Husky，启用提交/推送前的构建与测试钩子。

开发与再小的 UI 改动也请遵守仓库根目录 **[AGENTS.md](./AGENTS.md)** 中的基线（本地化走 `L10n`、双语文案、测试不断言翻译句等）。

## 使用流程（规则清理界面）

面向最终用户时，侧栏进入 **「规则清理」** 后，窗口采用固定工作台：标题与统计 → 顶部分析反馈 → 筛选 → 规则表与检查器 → 底部命令栏。分析进度与结果固定显示在顶部；规则表承担主滚动；预览与清理只作用于已加入清理队列的规则。**规则清理界面（扫描列表、预览、确认、清理）的详细设计**见 **[RFC 010](.spec/rfc/010-rules-workspace-ui-hig-and-collaboration.md#detailed-ui-spec)**（锚点 `detailed-ui-spec`）。

## 常用命令

在**仓库根目录**执行：

| 目的 | 命令 |
|------|------|
| 开发（Vite + Velox） | `pnpm dev` |
| 打 release `.app` | `pnpm build` 或 `pnpm build:app` |
| 打开 dev 应用 | `pnpm open:app:dev` |

**应用起不来？** 在仓库根目录执行 `pnpm dev`；窗口可能在后台，用 Command+Tab 切到 **Cleaning Dev**。

SwiftPM（在 `apps/desktop/desktop-velox/` 下）：

```bash
cd apps/desktop/desktop-velox
swift build
swift test
```

Release 产物：`apps/desktop/desktop-velox/dist/CleanSpaceDesktop.app`（由 `pnpm build:app` / `scripts/bundle-mac-app.sh` 生成）。

## 仓库结构

| 路径 | 说明 |
|------|------|
| `apps/desktop/` | React + Vite 前端 |
| `apps/desktop/desktop-velox/` | Velox 运行时、IPC、`CleanSpaceKit` 业务库 |
| `apps/desktop/desktop-velox/Sources/CleanSpaceKit/Resources/` | 内置 `cleaning-rules.json`、本地化与素材 |
| `apps/desktop/desktop-velox/Tests/CleanSpaceKitTests/` | 业务单元测试 |
| `packages/desktop-api/` | 前端 IPC 客户端 |
| `design/` | 应用图标矢量源 `icon.svg` 与 `generate-app-icon.sh` |
| `scripts/bundle-mac-app.sh` | 将 `swift build` 产物组装为 `.app` |
| `.spec/rfc/` | 能力范围与规则格式等说明 |
| `docs/macos-swiftui-references.md` | Apple HIG / SwiftUI 官方对照索引（规则 UI 细稿只在 [RFC 010#detailed-ui-spec](.spec/rfc/010-rules-workspace-ui-hig-and-collaboration.md#detailed-ui-spec)） |
| `ROADMAP.md` | RFC **顺序与路线图状态**（与 RFC 正文、`TASK_TRACKING.md` 同步） |
| `TASK_TRACKING.md` | RFC 落地的**细项任务**与完成状态 |
| `.husky/` | `pre-commit` / `pre-push` 等 Git 钩子 |

## 清理能力（规范）

内置规则文件：`apps/desktop/desktop-velox/Sources/CleanSpaceKit/Resources/cleaning-rules.json`。用户覆盖：`~/Library/Application Support/CleanSpace/user-cleaning-rules.json`。

### RFC 索引

**进度与状态以 [`ROADMAP.md`](ROADMAP.md) 为准**；**任务拆解以 [`TASK_TRACKING.md`](TASK_TRACKING.md) 为准**。RFC 文件头部「状态」应与 `ROADMAP.md` 同步更新。

新 RFC 文件命名：`NNN-功能简述.md`（三位数字补零）。

| RFC | 标题 |
|-----|------|
| [001](.spec/rfc/001-ccleaner-style-cleaning-spec.md) | CCleaner 式清理规范 |

## Git 钩子（Husky）

- **pre-commit**：`scripts/check-swift-ui-l10n.sh`（需 `rg`）+ `cd apps/desktop/desktop-velox && swift build`
- **pre-push**：`cd apps/desktop/desktop-velox && swift build && swift test`
- **commit-msg**：提交说明非空且不少于 3 个字符（见 `.husky/commit-msg`）

## 应用图标

- **`design/icon.svg`**：应用图标矢量源（几何原创，无第三方图案）。
- **`AppIcon-1024.png`**：由 `design/generate-app-icon.mjs` 生成，同步到 React 与 Velox 资源目录。

在 **`pnpm run build:app`**、**`pnpm run bundle:app`** 时会自动调用该脚本。若本机有 **`rsvg-convert`**（例如 `brew install librsvg`），会从 SVG 重新导出 PNG；若没有，则使用仓库里已提交的 PNG，构建照常通过。

手动从 SVG 同步图标：

```bash
cd design && ./generate-app-icon.sh
```
