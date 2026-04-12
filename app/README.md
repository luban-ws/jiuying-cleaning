# CleanSpace（SwiftPM）

本应用在 **`app/`** 下为 Swift Package，使用 **Swift 工具链**即可编译，**无需安装或打开 Xcode.app**（仍需 macOS 与 Apple 平台 SDK，通常来自 `xcode-select --install` 或 Xcode 自带的 Command Line Tools）。

## 命令行构建

```bash
cd app
swift build
```

产物：`app/.build/<arch>-apple-macosx/debug/CleanSpace` 可执行文件；资源在同级目录的 `CleanSpace_CleanSpaceKit.bundle`。

## 运行

```bash
cd app
swift run CleanSpace
```

## 打 .app 包（访达可双击）

```bash
cd app
./scripts/bundle-mac-app.sh release
open .build/arm64-apple-macosx/release/CleanSpace.app
```

或使用仓库根目录：

```bash
npm run bundle:app
```

## 测试

```bash
cd app
swift test
```

或：`npm run test:app`

## 结构说明

| 内容 | 路径 |
|------|------|
| Package 清单 | `Package.swift` |
| 业务与界面（库） | `Sources/CleanSpaceKit/` |
| 可执行入口（@main） | `Sources/CleanSpace/CleanSpaceApp.swift` |
| 内置规则与素材 | `Sources/CleanSpaceKit/Resources/` |
| 单元测试 | `Tests/CleanSpaceTests/` |
| .app 用 Info.plist | `Support/Info.plist` |

构建缓存目录 **`app/.build/`** 已在仓库根 `.gitignore` 中忽略。

## 应用图标

矢量源与生成脚本见 `design/`；构建前会自动尝试从 `icon.svg` 生成 PNG（需 `rsvg-convert`，见 `design/README.md`）。
