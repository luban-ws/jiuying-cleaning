# CleanSpace

macOS 清理应用：管理浏览器、Docker、AI 工具（如 Cursor / Antigravity）等占用，释放多余空间。

## 项目结构

- **`app/`** — Xcode 工程与 Mac 应用源码
  - `app/CleanSpace.xcodeproj` — 用 Xcode 打开
  - `app/CleanSpace/` — SwiftUI 源码与资源
  - `app/design/` — 应用图标矢量源（SVG）及生成说明
- **`.husky/`** — Git 钩子：提交/推送前会执行 Xcode 构建校验

## 快速开始

1. **打开工程**：用 Xcode 打开 `app/CleanSpace.xcodeproj`，选择 scheme **CleanSpace** 运行。Derived Data 固定为 **`app/.derivedData`**（见 `app/CleanSpace.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`），不使用全局 `~/Library/Developer/Xcode/DerivedData`。
2. **命令行构建**：`npm run build:app`（已带 `-derivedDataPath`）或见 [app/README.md](app/README.md)。
3. **图标**：应用图标源为 `app/design/icon.svg`（几何原创），已生成 `AppIcon-1024.png`；如需重生成见 `app/design/README.md`。

## Git 钩子（Husky）

- **pre-commit**：提交前执行 CleanSpace 的 Debug 构建，失败则禁止提交。
- **commit-msg**：校验提交信息非空且至少 3 个字符。
- **pre-push**：推送前再次执行构建，确保可构建才推送。

安装依赖后自动启用：`npm install`（会执行 `husky` prepare）。

## 清理能力定义（RFC）

清理范围与行为以 **CCleaner** 为参考，并针对 macOS 与当前目标（浏览器、Docker、AI 工具）做了明确约定：

- **规范文档**：[docs/rfc/001-ccleaner-style-cleaning-spec.md](docs/rfc/001-ccleaner-style-cleaning-spec.md)
- **内容概要**：系统（Trash、用户缓存、Xcode）、浏览器（Chrome/Safari/Firefox/Edge/Arc 等路径与项）、Docker（prune 与可选路径清理）、AI 工具（Cursor/Antigravity 等缓存与可配置规则）。
- 实现顺序与 UI 在 RFC 之外按需迭代。

## 后续扩展

- 在 `CleanCategory` 与详情视图中接入真实扫描/清理逻辑。
- 用 RFC 001 中的配置文件或插件定义每类清理规则与路径，便于维护与扩展。
