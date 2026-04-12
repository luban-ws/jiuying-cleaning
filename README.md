# CleanSpace

macOS 清理应用：管理浏览器、Docker、AI 工具（如 Cursor / Antigravity）等占用，释放多余空间。

## 项目结构

- **`app/`** — Swift Package（SwiftPM）与 Mac 应用源码
  - `app/Package.swift` — 包清单；用 **`swift build`** 编译，无需打开 Xcode.app
  - `app/Sources/CleanSpaceKit/` — SwiftUI 界面与业务库
  - `app/Sources/CleanSpace/` — 可执行入口（`@main`）
  - `app/design/` — 应用图标矢量源（SVG）及生成说明
- **`.husky/`** — Git 钩子：提交前 `swift build`，推送前 `swift build` + `swift test`

## 快速开始

1. **命令行构建**：`npm run build:app` 或 `cd app && swift build`（需 macOS 与 Swift 工具链 / Command Line Tools）。
2. **运行**：`cd app && swift run CleanSpace`。
3. **打 .app**：`npm run bundle:app`，然后打开 `app/.build/.../release/CleanSpace.app`（详见 [app/README.md](app/README.md)）。
4. **图标**：应用图标源为 `app/design/icon.svg`（几何原创）；构建前脚本会尝试生成 `AppIcon-1024.png`（需 `rsvg-convert` 时见 `app/design/README.md`）。

## Git 钩子（Husky）

- **pre-commit**：提交前执行 `swift build`，失败则禁止提交。
- **commit-msg**：校验提交信息非空且至少 3 个字符。
- **pre-push**：推送前执行 `swift build` 与 `swift test`。

安装依赖后自动启用：`npm install`（会执行 `husky` prepare）。

## 清理能力定义（RFC）

清理范围与行为以 **CCleaner** 为参考，并针对 macOS 与当前目标（浏览器、Docker、AI 工具）做了明确约定：

- **规范文档**：[docs/rfc/001-ccleaner-style-cleaning-spec.md](docs/rfc/001-ccleaner-style-cleaning-spec.md)
- **内容概要**：系统（Trash、用户缓存、Xcode）、浏览器（Chrome/Safari/Firefox/Edge/Arc 等路径与项）、Docker（prune 与可选路径清理）、AI 工具（Cursor/Antigravity 等缓存与可配置规则）。
- 实现顺序与 UI 在 RFC 之外按需迭代。

## 后续扩展

- 在 `CleanCategory` 与详情视图中接入真实扫描/清理逻辑。
- 用 RFC 001 中的配置文件或插件定义每类清理规则与路径，便于维护与扩展。
