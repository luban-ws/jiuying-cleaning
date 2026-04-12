# CleanSpace（Xcode）

## Derived Data（固定在本目录）

本工程 **不使用** Xcode 默认的全局路径 `~/Library/Developer/Xcode/DerivedData/...`。

- **在 Xcode 里打开**：打开 `CleanSpace.xcodeproj` 后，共享工作区设置会把 Derived Data 指到 **`app/.derivedData`**（与 `.xcodeproj` 同级目录）。
- **命令行**：务必带 `-derivedDataPath`，与 Husky / npm 脚本一致：

```bash
cd app
xcodebuild -scheme CleanSpace -configuration Debug -derivedDataPath "$(pwd)/.derivedData" build
open "$(pwd)/.derivedData/Build/Products/Debug/CleanSpace.app"
```

或使用仓库根目录：

```bash
npm run build:app
```

`.derivedData` 已在 `.gitignore` 中，不会提交。

## 若 Xcode 仍指向全局 Derived Data

1. 完全退出 Xcode 后重新打开 `CleanSpace.xcodeproj`。  
2. 菜单 **File → Workspace Settings…**（或 **Project Settings**）中确认 Derived Data 为 **Relative to Workspace** / 与 `WorkspaceSettings.xcsettings` 一致。
