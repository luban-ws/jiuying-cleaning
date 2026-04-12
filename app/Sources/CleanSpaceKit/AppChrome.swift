//
//  AppChrome.swift
//  CleanSpace
//
//  详情区版式、间距与只读输出区域，对齐 macOS「系统设置」式布局。
//

import SwiftUI

enum CS {
    /// 详情正文最大宽度，避免超宽屏一行过长
    static let detailContentMaxWidth: CGFloat = 680
    static let detailHorizontalPadding: CGFloat = 32
    static let detailVerticalPadding: CGFloat = 20
    static let cornerSmall: CGFloat = 8
    static let cornerPanel: CGFloat = 12
}

// MARK: - 详情区：居中限宽 + 统一背景
struct DetailScaffold<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            content()
                .frame(maxWidth: CS.detailContentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, CS.detailHorizontalPadding)
                .padding(.vertical, CS.detailVerticalPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

/// CLI / 日志输出：等宽、可选中、与分组表单协调的背景
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
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: CS.cornerSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CS.cornerSmall, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 1)
        )
    }
}
