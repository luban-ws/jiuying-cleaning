---
name: mac-app
description: Create and maintain native macOS apps with Xcode (Swift/SwiftUI), app icon design, and Git hooks (Husky) for commit/push validation. Use when building Mac apps, adding Xcode projects under app/, designing icons without pattern issues, or setting up pre-commit/pre-push checks for Xcode builds.
---

# Mac 应用项目技能

## 适用场景

- 在仓库中创建或维护 **Xcode 项目**（如放在 `app/` 下）
- 为 Mac 应用设计 **应用图标**（原创、无图案/版权问题）
- 使用 **Husky** 为 Xcode 应用配置 **commit / push 钩子**（提交与推送前校验）
- 需要统一的项目结构、构建与提交流程

## 1. Xcode 项目结构（推荐）

- **位置**：`app/<ProductName>.xcodeproj`，源码放在 `app/<ProductName>/`。
- **必备文件**：
  - `app/<ProductName>.xcodeproj/project.pbxproj`（目标、源文件、资源、Build Settings）
  - `app/<ProductName>/<App>App.swift`：`@main` + `App` 协议入口
  - `app/<ProductName>/ContentView.swift`（或主界面）
  - `app/<ProductName>/Assets.xcassets/`（AppIcon、AccentColor 等）
- **Derived Data**：固定使用仓库内 **`app/.derivedData`**，避免全局 `~/Library/Developer/Xcode/DerivedData`。在 `project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` 中设置 `DerivedDataLocationStyle` = `WorkspaceRelativePath`、`DerivedDataCustomLocation` = `.derivedData`；命令行与 Husky 一律加 `-derivedDataPath "$(pwd)/.derivedData"`（在 `app` 目录下执行时）。
- **构建**：`cd app && xcodebuild -scheme <SchemeName> -configuration Debug -derivedDataPath "$(pwd)/.derivedData" build -quiet`
- **部署目标**：在 `project.pbxproj` 中设置 `MACOSX_DEPLOYMENT_TARGET`（如 14.0）。

## 2. 应用图标（无图案问题）

- **原则**：使用 **原创几何/矢量设计**，避免第三方素材或易产生版权争议的图案。
- **实现方式**：
  - 在 `app/design/icon.svg` 维护 **唯一矢量源**（纯几何、渐变、无复杂纹理）。
  - 用 `rsvg-convert` 生成 1024×1024 PNG：  
    `rsvg-convert -w 1024 -h 1024 -o …/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png icon.svg`
  - macOS 11+ 可只在 `AppIcon.appiconset` 中提供 **单张 1024×1024**，在 `Contents.json` 里声明 `"idiom": "mac", "scale": "1x", "size": "1024x1024"` 及对应 `filename`。
- **避免**：剪贴画、明显仿制他人图标、通用“图标库”图案。

## 3. Husky：commit 与 push 钩子

- **安装**：在仓库根目录 `npm install husky --save-dev`，`package.json` 中 `"prepare": "husky"`，保证 `npm install` 后自动启用。
- **钩子建议**：
  - **commit-msg**：校验提交信息非空、长度等（可接 commitlint）。
  - **pre-commit**：提交前执行 `cd app && xcodebuild … -derivedDataPath "$(pwd)/.derivedData" build -quiet`，避免与全局 DerivedData 的 `build.db` 锁冲突。
  - **pre-push**：同上，使用仓库内 `.derivedData`。
- **钩子脚本**：放在 `.husky/`，需可执行（`chmod +x`）；可先执行 `. "$(dirname -- "$0")/_/husky.sh"` 再写业务逻辑（注意 Husky 10 将弃用部分用法，以官方文档为准）。
- **与 Xcode 的关系**：钩子只调用 `xcodebuild`，不依赖 Xcode GUI；CI 也可复用同一命令。

## 4. 清理类应用的可扩展设计

- 用 **枚举**（如 `CleanCategory: browser | docker | aiTools`）定义清理类别，便于后续用配置文件或插件定义“如何清理”。
- 每类对应说明与预估空间，界面按类别展示；实际清理逻辑可抽到独立模块，由配置驱动（路径、命令、安全提示等）。

## 5. 检查清单（本仓库已做）

- [x] 在 `app/` 下创建 Xcode 项目（CleanSpace）
- [x] 提供 SwiftUI 入口与主界面，支持浏览器 / Docker / AI 工具等分类
- [x] 使用原创 SVG 图标并生成 1024 PNG，无第三方图案
- [x] 根目录 `package.json` + Husky，配置 `commit-msg`、`pre-commit`、`pre-push`
- [x] pre-commit / pre-push 均运行 `xcodebuild` 保证可构建

## 参考路径（本仓库）

| 内容       | 路径 |
|------------|------|
| Xcode 工程 | `app/CleanSpace.xcodeproj/` |
| 应用源码   | `app/CleanSpace/*.swift` |
| 图标资源   | `app/CleanSpace/Assets.xcassets/AppIcon.appiconset/` |
| 图标源 SVG | `app/design/icon.svg` |
| Husky 钩子 | `.husky/pre-commit`, `.husky/commit-msg`, `.husky/pre-push` |
| 工作区 Derived Data | `app/CleanSpace.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` |
| app 构建说明 | `app/README.md` |
