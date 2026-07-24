# RFC 012：UI 抛光与 macOS HIG 自适应合规（UI Review & Polish）

**状态**：评审中（**本文含规范性 UI 细节设计与打磨项**；主要任务已落地代码库）  
**创建日期**：2026-07-24  
**作者**：CleanSpace  

**权威说明**：本文为 CleanSpace UI 全面审查（UI Review）后的抛光与自适应性增强设计规范，直接对齐 [Apple macOS HIG](https://developer.apple.com/design/human-interface-guidelines) 与 `docs/macos-swiftui-references.md` 的排版要求。

---

## 第一部分：摘要、问题与决策

### 1.1 背景与摘要
在经历多轮功能合并与 stash conflict 恢复后，CleanSpace 在某些特定视口与极端分辨率下暴露了以下排版及渲染边缘缺陷：
1. **沉浸式顶栏内容越界**：在 macOS 15 默认的 `.windowToolbarStyle(.unified)` 统一标题栏样式下，非滚动静态 `VStack` 面板（规则清理工作区）会被强制延伸至窗口绝对物理原点 `(0,0)` 渲染，导致顶部的 Guide Banner 被半透明工具栏彻底盖住。
2. **轻量占比图剪裁**：在微型尺寸（如 `38x38`）下，重型 Swift Charts 在渲染 `SectorMark` 时存在不可控的默认 padding，导致环形图在卡片边缘出现局部剪切（Cut-off）。
3. **宽屏布局拉伸**：Docker 预设卡片原采用固定的 `2-column` Flex 布局，在宽屏窗口下 Presets 会被横向过度拉扯变扁，破坏了原子设计的紧凑美感。

为了彻底消除这些技术债并防止未来重组时排版再次退化，特设立本 RFC 012 进行全局抛光与 HIG 自适应对齐。

### 1.2 决策矩阵 (Frozen Decisions)

| ID | 决策 | 实施说明 |
|----|------|------|
| **D1** | 静态非滚动详情面板必须显式处理 Top 安全区。 | 采用 `.safeAreaPadding(.top)` 使其自动避让 unified 透明标题栏，严禁 hardcode 固定高度值。 |
| **D2** | 小尺寸（直径 < 50pt）占比圆环禁用 Swift Charts。 | 统一重构为纯 SwiftUI `Circle().stroke().trim()` 配合 lineWidth/2 的 padding 补偿，实现 100% 矢量零开销绘制。 |
| **D3** | 卡片组/卡片网格禁止使用固定列数的 Flex 网格。 | 必须配置为自适应响应式网格 (`.adaptive(minimum: ...)`)，以便在不同窗口宽度下呈现最自然的列数。 |
| **D4** | SwiftUI 编写严格遵循 Correctness Checklist 规范。 | 所有 `@State` 显式标明 `private`；所有文案强制走 `L10n`；对重绘敏感的事件分离计算。 |

---

## 第二部分：任务跟踪与状态

对接 [TASK_TRACKING.md](file:///Volumes/ORICO/ws/prj/luban-ws/cleaning/TASK_TRACKING.md)，新增以下细分任务：

### TASK-012-01 — 非滚动工作区 Top 安全区对齐
* **目标**：在 `RulesWorkspaceView.selectableBody` 最外层的 VStack 挂载 `.safeAreaPadding(.top)`，动态腾出 unified 统一标题栏高度。
* **状态**：**已完成**
* **验收提交**：`05c87c6`

### TASK-012-02 — 重构微型圆环图为纯 SwiftUI 矢量绘制
* **目标**：将 `MetricsPopoverPercentDonut` 重构为基于 `Circle` 路径的 trim 环形图，并使用 `lineWidth / 2` 抵消 stroke 中心点外溢，确保微型比例下绝对不裁切。
* **状态**：**已完成**
* **验收提交**：`8e7d696`

### TASK-012-03 — Docker 预设面板改为自适应响应式网格
* **目标**：将 `DockerSpecialWorkspaceView` 中的 LazyVGrid 配置由 `[GridItem(.flexible()), GridItem(.flexible())]` 重构为 `[GridItem(.adaptive(minimum: 220, maximum: 360), spacing: 12)]`，使其在大屏下自动展开为多列，防扁平拉伸。
* **状态**：**已完成**
* **验收提交**：待提交（代码已验证且单测通过）

### TASK-012-04 — 全局 SwiftUI 代码规范性审计与抛光
* **目标**：对全项目 UI 视图执行 Checklist 静态审计，纠正非 private 的 `@State` 及硬编码文案。
* **状态**：**已完成**
* **验收提交**：`8e7d696`
