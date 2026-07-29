# macOS 界面与 SwiftUI — 官方对照索引

本仓库目标为 **macOS 15+**，窗口与详情区实现应对齐下列资料（按优先级）。

## Human Interface Guidelines（macOS）

- [macOS HIG 总览](https://developer.apple.com/design/human-interface-guidelines/macos)
- 常用子主题：**Layout**、**Windows**、**Toolbars**、**Menus**、**Materials**、**Accessibility**

## SwiftUI（窗口与工具栏）

- [windowToolbarStyle(_:)](https://developer.apple.com/documentation/swiftui/scene/windowtoolbarstyle(_:)) — **unified** 等与标题栏合并的工具栏样式
- Apple Developer Documentation 检索关键词：**Customizing window styles**（`toolbarBackground`、`toolbarBackgroundVisibility`、`contentMargins`）
- 表单与列表：**Form**、**Table**、**NavigationSplitView**

## WWDC

在 [Apple Developer 视频](https://developer.apple.com/videos/) 中按年份检索：**SwiftUI macOS**、**window**、**toolbar**、**design**

## 与本工程的关系

- 最低系统以 `Package.swift` 的 `platforms` 与 `Support/Info.plist` 的 `LSMinimumSystemVersion` 为准。
- **规则清理详情区**的详细 UI 设计以 **[RFC 010 第二部分](../.spec/rfc/010-rules-workspace-ui-hig-and-collaboration.md#detailed-ui-spec)** 为准。
