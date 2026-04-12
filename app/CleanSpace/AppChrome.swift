//
//  AppChrome.swift
//  CleanSpace
//
//  统一间距、圆角与只读等宽区域，贴近现代 macOS 设置类应用。
//

import SwiftUI

enum CS {
    static let contentMaxWidth: CGFloat = 720
    static let cornerSmall: CGFloat = 8
    static let cornerPanel: CGFloat = 12
}

/// 日志 / CLI 输出：浅色底、等宽、可选中
struct CSMonospaceBlock: View {
    let text: String
    var placeholder: String = "—"

    var body: some View {
        ScrollView {
            Text(text.isEmpty ? placeholder : text)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
        }
        .frame(minHeight: 120, maxHeight: 240)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: CS.cornerSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CS.cornerSmall, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
