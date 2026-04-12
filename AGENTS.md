# CleanSpace — 协作与自动化约定

面向人类贡献者与 AI 代理：再小的改动也应遵守下列基线，避免「以后再修」的技术债。

## 本地化（非可选）

- **用户可见的任意自然语言**（中/英/标点说明句）必须放在 `app/Sources/CleanSpaceKit/Resources/` 下各语言的 `Localizable.strings` 中，开发语言为 **en**（与 `Package.swift` 中 `defaultLocalization` 一致）。
- Swift 代码中通过 **`L10n`**（`Localization/L10n.swift`）引用，**禁止**在 `Text("…")`、`Button("…")`、`Section("…")`、`.alert("…")`、`title:`、`placeholder:` 等位置写入 CJK 字面量。
- 新增键时至少同步维护 **`en.lproj`** 与 **`zh-Hans.lproj`**；键名用一致的点分命名（与现有文件对齐）。
- 单元测试中断言 **稳定标识**（如 `SpaceChartSlice.id`、规则 `id`），不要断言随语言变化的 **展示文案**。

## 构建与钩子

- 提交前：`.husky/pre-commit` 会运行 `scripts/check-swift-ui-l10n.sh` 与 `cd app && swift build`。
- 推送前：`.husky/pre-push` 会 `swift build && swift test`。
- 本地可执行：`pnpm run test:app`、`pnpm run build:app`（见根目录 `package.json`）；依赖与锁文件由 **pnpm** 管理（`pnpm-lock.yaml`）。

## 界面（macOS）

- **最低系统**：**macOS 15**（Sequoia），与 `Package.swift` 中 `platforms: [.macOS(.v15)]`（`swift-tools-version: 6.0`）及 `Support/Info.plist` 的 `LSMinimumSystemVersion`（`15.0`）一致。
- 窗口与工具栏的**官方对照**见仓库内 `docs/design/macos-swiftui-references.md`（HIG、SwiftUI 文章与 WWDC 检索关键词）。
- 以 **[Apple Human Interface Guidelines — macOS](https://developer.apple.com/design/human-interface-guidelines)** 与系统自带「设置」类应用为参照：优先 `NavigationSplitView`、**unified** 窗口工具栏、系统 **Material** 与指针 **`.help()`**，避免过时的大块纯色底与重阴影卡片。

## 结构

- 可复用 UI 与业务在 **`CleanSpaceKit`**；可执行目标 **`CleanSpace`** 仅保留 `@main` 入口。
- 新增大段逻辑时优先拆到独立类型/文件，避免单文件无限膨胀。

## 依赖

- `scripts/check-swift-ui-l10n.sh` 依赖 **ripgrep**（`rg`）。若未安装，脚本会跳过检查；建议在开发机上安装以便钩子生效。
