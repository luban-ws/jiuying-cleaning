---
name: mac-app
description: Create and maintain native macOS apps with SwiftPM (Swift Package Manager), Swift/SwiftUI, app icon design, and Git hooks (Husky) for commit/push validation. Use when building Mac apps under app/, designing icons without pattern issues, or setting up pre-commit/pre-push checks with swift build / swift test.
---

# Mac 应用项目技能（SwiftPM）

## 适用场景

- 在仓库中创建或维护 **Swift Package** 形式的 Mac 应用（如放在 `app/` 下）
- 为 Mac 应用设计 **应用图标**（原创、无图案/版权问题）
- 使用 **Husky** 为 **swift build** / **swift test** 配置 **commit / push 钩子**
- 需要 **无需 Xcode.app**、仅用命令行工具链即可编译的流程

## 1. SwiftPM 项目结构（推荐）

- **位置**：`app/Package.swift`；界面与业务放在库目标（如 `Sources/CleanSpaceKit/`），`@main` 入口放在可执行目标（如 `Sources/CleanSpace/`）。
- **构建**：`cd app && swift build`；运行：`swift run <ProductName>`。
- **产物**：可执行文件与 `*_CleanSpaceKit.bundle` 等资源包位于 `app/.build/`（应加入 `.gitignore`）。
- **.app 包**：用脚本将可执行文件、`app/Support/Info.plist` 与资源 bundle 拷入 `Contents/MacOS` 与 `Contents/Resources`，便于访达双击（见本仓库 `scripts/bundle-mac-app.sh`）。
- **部署目标**：在 `Package.swift` 的 `platforms: [.macOS(.v14)]`（或所需版本）中声明。

## 2. 应用图标（无图案问题）

- **原则**：使用 **原创几何/矢量设计**，避免第三方素材或易产生版权争议的图案。
- **实现方式**：
  - 在仓库根目录 `design/icon.svg` 维护 **唯一矢量源**（纯几何、渐变、无复杂纹理）。
  - 用 `rsvg-convert` 生成 1024×1024 PNG 到 **`Sources/<Kit>/Resources/Assets.xcassets/AppIcon.appiconset/`**。
  - macOS 11+ 可只在 `AppIcon.appiconset` 中提供 **单张 1024×1024**，在 `Contents.json` 里声明 `"idiom": "mac", "scale": "1x", "size": "1024x1024"` 及对应 `filename`。
- **避免**：剪贴画、明显仿制他人图标、通用“图标库”图案。

## 3. Husky：commit 与 push 钩子

- **安装**：在仓库根目录 `npm install husky --save-dev`，`package.json` 中 `"prepare": "husky"`。
- **钩子建议**：
  - **commit-msg**：校验提交信息非空、长度等（可接 commitlint）。
  - **pre-commit**：`cd app && swift build`。
  - **pre-push**：`cd app && swift build && swift test`。
- **钩子脚本**：放在 `.husky/`，需可执行（`chmod +x`）。

## 4. 清理类应用的可扩展设计

- 用 **枚举**（如 `CleanCategory: browser | docker | aiTools`）定义清理类别，便于后续用配置文件或插件定义“如何清理”。
- 每类对应说明与预估空间，界面按类别展示；实际清理逻辑可抽到独立模块，由配置驱动（路径、命令、安全提示等）。

## 5. 检查清单（本仓库）

- [x] 在 `app/` 下使用 SwiftPM（CleanSpace + CleanSpaceKit）
- [x] 提供 SwiftUI 入口与主界面，支持浏览器 / Docker / AI 工具等分类
- [x] 使用原创 SVG 图标并生成 1024 PNG，无第三方图案
- [x] 根目录 `package.json` + Husky，`pre-commit` / `pre-push` 使用 `swift build` / `swift test`
- [x] 提供 `bundle-mac-app.sh` 生成 `.app`

## 参考路径（本仓库）

| 内容       | 路径 |
|------------|------|
| Swift 包   | `app/Package.swift` |
| 库与资源   | `app/Sources/CleanSpaceKit/` |
| 可执行入口 | `app/Sources/CleanSpace/` |
| 单元测试   | `app/Tests/CleanSpaceTests/` |
| 图标源 SVG | `design/icon.svg` |
| 打 .app 脚本 | `scripts/bundle-mac-app.sh` |
| Info.plist | `app/Support/Info.plist` |
| Husky 钩子 | `.husky/pre-commit`, `.husky/commit-msg`, `.husky/pre-push` |
| 仓库说明 | 根目录 `README.md` |
