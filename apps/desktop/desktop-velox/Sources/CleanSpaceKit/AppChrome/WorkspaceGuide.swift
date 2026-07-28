//
//  WorkspaceGuide.swift
//  CleanSpaceKit
//
//  工作区顶部引导条：面向用户的简短三步流程（HIG：先说明再操作）。
//

import SwiftUI

/// 详情区顶部的友好流程提示。
struct CSWorkspaceGuideBanner: View {
    let text: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28, alignment: .center)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: CS.cornerPanel, style: .continuous)
                .fill(Material.thin)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CS.cornerPanel, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

/// 概览数字芯片（选中 / 已分析等）。
struct CSQuickStatChip: View {
    let label: String
    var emphasized: Bool = false

    var body: some View {
        Text(label)
            .font(.caption.weight(.medium))
            .monospacedDigit()
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule(style: .continuous)
                    .fill(emphasized ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.06))
            }
            .foregroundStyle(emphasized ? Color.accentColor : .secondary)
    }
}
