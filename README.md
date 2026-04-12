# CleanSpace

macOS 原生清理工具（Swift / SwiftUI）：按规则扫描与清理浏览器缓存、Docker 相关目录、AI 工具缓存等，并在「磁盘」页查看卷空间与顶层目录占用（与系统「已用」口径差异见应用内说明）。

## 环境要求

- **系统**：macOS 15 及以上（与 `Package.swift` 中 `swift-tools-version: 6.0`、`platforms: [.macOS(.v15)]` 及 `Support/Info.plist` 的 `LSMinimumSystemVersion` 一致）。
- **构建**：本机已安装 **Swift** 与 **Apple 平台 SDK**（`xcode-select --install` 的 Command Line Tools 即可，**不必**打开 Xcode.app）。
- **可选**：**Node.js 18+** 与 **pnpm**（用于 Husky 与根目录脚本封装；可用 [Corepack](https://nodejs.org/api/corepack.html) 对齐 `package.json` 里的 `packageManager` 字段）；**rsvg-convert**（`brew install librsvg`，从 SVG 再生应用图标 PNG）。

## 克隆后

```bash
corepack enable   # 可选：按 package.json 的 packageManager 固定 pnpm 版本
pnpm install
```

会安装 Husky，启用提交/推送前的构建与测试钩子。

开发与再小的 UI 改动也请遵守仓库根目录 **[AGENTS.md](./AGENTS.md)** 中的基线（本地化走 `L10n`、双语文案、测试不断言翻译句等）。

## 常用命令

在**仓库根目录**执行：

| 目的 | 命令 |
|------|------|
| 调试构建 | `pnpm run build:app` |
| 运行应用（SwiftPM） | `pnpm run:app` |
| 单元测试 | `pnpm run test:app` |
| 打可在访达双击的 `.app` | `pnpm run bundle:app` |

**应用起不来？**

- 包管理器是 **pnpm**（不是 `pap` / `npm` 混用）：在**仓库根目录**（有 `package.json` 的那一层）执行 `pnpm run:app`。`run:app` 会调用 `scripts/run-app.sh`，不依赖你当前终端是否已 `cd app`。
- 若终端里构建成功但「像没反应」：窗口可能在其他应用后面，用 **Command+Tab** 或程序坞切到 **CleanSpace**。
- 等价命令：`./scripts/run-app.sh` 或 `cd app && swift run CleanSpace`（需本机已安装 Swift / macOS SDK）。

等价的 SwiftPM 命令（在 `app/` 下）：

```bash
cd app
swift build          # 调试构建
swift run CleanSpace # 运行
swift test           # 测试
```

Release 产物示例路径：

- 可执行文件与资源包：`app/.build/<架构>-apple-macosx/release/CleanSpace` 与 `CleanSpace_CleanSpaceKit.bundle`
- 打包后的应用：`app/.build/<架构>-apple-macosx/release/CleanSpace.app`（由 `scripts/bundle-mac-app.sh` 生成）

构建缓存目录 `app/.build/` 已被 Git 忽略。

## 仓库结构

| 路径 | 说明 |
|------|------|
| `package.json` / `pnpm-lock.yaml` | 根目录脚本（Husky、Swift 构建/运行/测试封装）与 pnpm 锁文件 |
| `app/Package.swift` | Swift Package 清单 |
| `app/Sources/CleanSpaceKit/` | 界面与业务（库目标） |
| `app/Sources/CleanSpace/` | 可执行入口（`@main`） |
| `app/Sources/CleanSpaceKit/Resources/` | 内置 `cleaning-rules.json`、素材目录 |
| `app/Tests/CleanSpaceTests/` | 单元测试 |
| `app/Support/Info.plist` | 打 `.app` 时使用的 Bundle 信息 |
| `design/` | 应用图标矢量源 `icon.svg` 与 `generate-app-icon.sh` |
| `scripts/bundle-mac-app.sh` | 将 `swift build` 产物组装为 `.app` |
| `docs/rfc/` | 能力范围与规则格式等说明 |
| `ROADMAP.md` | RFC **顺序与路线图状态**（与 RFC 正文、`TASK_TRACKING.md` 同步） |
| `TASK_TRACKING.md` | RFC 落地的**细项任务**与完成状态 |
| `.husky/` | `pre-commit` / `pre-push` 等 Git 钩子 |

## 清理能力（规范）

内置规则文件：`app/Sources/CleanSpaceKit/Resources/cleaning-rules.json`。用户覆盖规则（同结构、同 `id` 时覆盖内置）：`~/Library/Application Support/CleanSpace/user-cleaning-rules.json`。

### RFC 索引

**进度与状态以 [`ROADMAP.md`](ROADMAP.md) 为准**；**任务拆解以 [`TASK_TRACKING.md`](TASK_TRACKING.md) 为准**。RFC 文件头部「状态」应与 `ROADMAP.md` 同步更新。

新 RFC 文件命名：`NNN-功能简述.md`（三位数字补零）。

| RFC | 标题 |
|-----|------|
| [001](docs/rfc/001-ccleaner-style-cleaning-spec.md) | CCleaner 式清理规范 |

## Git 钩子（Husky）

- **pre-commit**：`scripts/check-swift-ui-l10n.sh`（需 `rg`）+ `cd app && swift build`
- **pre-push**：`cd app && swift build && swift test`
- **commit-msg**：提交说明非空且不少于 3 个字符（见 `.husky/commit-msg`）

## 应用图标

- **`design/icon.svg`**：应用图标矢量源（几何原创，无第三方图案）。
- **`AppIcon-1024.png`**：由 `design/generate-app-icon.sh` 生成，输出到 `app/Sources/CleanSpaceKit/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`。

在 **`pnpm run build:app`**、**`pnpm run bundle:app`** 时会自动调用该脚本。若本机有 **`rsvg-convert`**（例如 `brew install librsvg`），会从 SVG 重新导出 PNG；若没有，则使用仓库里已提交的 PNG，构建照常通过。

手动从 SVG 同步图标：

```bash
cd design && ./generate-app-icon.sh
```
