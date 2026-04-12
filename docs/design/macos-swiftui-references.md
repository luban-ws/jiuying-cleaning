# macOS 界面与 SwiftUI — 官方对照索引

本仓库目标为 **macOS 15+**，窗口与详情区实现应对齐下列资料（按优先级）。

## Human Interface Guidelines（macOS）

- [macOS HIG 总览](https://developer.apple.com/design/human-interface-guidelines/macos)
- 重点子主题：**Layout**、**Windows**、**Toolbars**、**Materials**（与系统「设置」类应用一致的分组、边距与层次）

## SwiftUI（窗口与工具栏）

- [windowToolbarStyle(_:)](https://developer.apple.com/documentation/swiftui/scene/windowtoolbarstyle(_:)) — **unified** 等与标题栏合并的工具栏样式
- Apple Developer Documentation 中检索：**「Customizing window styles」**（macOS 上 `toolbarBackground`、`toolbarBackgroundVisibility`、沉浸式顶栏与 `WindowDragGesture` 的组合说明）
- 代码中已用：`toolbarBackground` / `toolbarBackgroundVisibility`（`for: .windowToolbar`）、`WindowDragGesture`、`contentMargins`（`for: .scrollContent`）、`navigationSubtitle`

## WWDC（逐年补充）

在 [Apple Developer 视频](https://developer.apple.com/videos/) 中按年份检索关键词：**SwiftUI macOS**、**window**、**toolbar**、**design**，以获取当年度 API 与示例应用（如 Destination Video）的布局模式。

## 与本工程的关系

- **Liquid Glass** 等随更新系统发布的视觉语言往往依赖**更新 SDK**；本包最低 **15.0**，不假设未在部署目标内声明的 API。
- 若最低版本抬升到 **macOS 16+**，再评估新增修饰符与示例中对齐项（例如额外的边距、顶栏可见性策略）。
