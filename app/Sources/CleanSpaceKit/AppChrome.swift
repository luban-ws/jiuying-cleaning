//
//  AppChrome.swift
//  CleanSpaceKit
//
//  详情区版式：对齐现代 macOS（NavigationSplitView + unified toolbar）下的分组内容 —
//  使用系统材质与分隔线，避免早期 Big Sur 式重阴影 + 纯色大块背景。
//

import SwiftUI

enum CS {
    /// 详情正文最大宽度（仪表盘式首屏略放宽，仍保持可读行长）
    static let detailContentMaxWidth: CGFloat = 840
    static let detailHorizontalPadding: CGFloat = 24
    static let detailVerticalPadding: CGFloat = 20
    /// 与系统设置类面板接近的连续圆角
    static let cornerSmall: CGFloat = 10
    static let cornerPanel: CGFloat = 14
    /// 首屏大卡片（卷摘要、预设宫格等）
    static let cornerHero: CGFloat = 16
}

// MARK: - 详情区：居中限宽（背景交给窗口与 NavigationStack，避免整块涂灰）
/// 内部若使用 `Form`，**不要**再包 `ScrollView`，否则 macOS 上 `Chart` / `Table` 常被压成 0 高度。
struct DetailScaffold<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        // 使用 contentMargins 与可滚动内容（Form 等）对齐，便于与 NavigationStack / 工具栏的版式一致（macOS 15+）。
        content()
            .frame(maxWidth: CS.detailContentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .contentMargins(.horizontal, CS.detailHorizontalPadding, for: .scrollContent)
            .contentMargins(.vertical, CS.detailVerticalPadding, for: .scrollContent)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // 详情区不使用 `WindowDragGesture`：与工具栏 `Menu` 的外点取消、下拉锚定同属窗口级事件，同层 `simultaneousGesture` 在部分系统上易抢手势。
            // 侧栏仍保留拖拽；窗口还可通过标题栏/工具栏空白区拖动（unified 样式下由系统提供）。
    }
}

// MARK: - 图表/统计卡片（regularMaterial + 轻分隔，替代重阴影）
struct CSChartCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "chart.pie.fill")
                .font(.headline)
                .labelStyle(.titleAndIcon)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: CS.cornerPanel, style: .continuous)
                .fill(Material.regular)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CS.cornerPanel, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
}

/// CLI / 日志：等宽、可选中；thinMaterial 与正文层次区分
struct CSMonospaceBlock: View {
    let text: String
    var placeholder: String = "—"

    var body: some View {
        ScrollView {
            Text(text.isEmpty ? placeholder : text)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(text.isEmpty ? .secondary : .primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
        .frame(minHeight: 140, maxHeight: 260)
        .background {
            RoundedRectangle(cornerRadius: CS.cornerSmall, style: .continuous)
                .fill(Material.thin)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CS.cornerSmall, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
        }
    }
}
