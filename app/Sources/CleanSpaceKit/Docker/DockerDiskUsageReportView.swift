//
//  DockerDiskUsageReportView.swift
//  CleanSpaceKit
//
//  将 docker system df 输出渲染为摘要表 + 分块明细 Grid，避免整坨等宽字符串难以阅读。
//

import SwiftUI

/// 结构化展示 `DockerDfReport`；无法解析时仍可展开查看原始输出。
struct DockerDiskUsageReportView: View {
    let report: DockerDfReport

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let fatal = report.fatalErrorText {
                Text(fatal)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if report.summaryCommandFailed, report.fatalErrorText == nil {
                Text(L10n.Docker.dfSummaryUnavailable)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !report.summaryRows.isEmpty {
                Text(L10n.Docker.dfSummarySectionTitle)
                    .font(.headline)
                summaryTable(report.summaryRows)
            }

            ForEach(report.detailSections) { section in
                detailSectionCard(section)
            }

            if report.fatalErrorText == nil,
               report.summaryRows.isEmpty,
               report.detailSections.isEmpty {
                Text(L10n.Docker.dfPlaceholder)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            DisclosureGroup(L10n.Docker.dfRawOutputToggle) {
                ScrollView {
                    Text(combinedRawOutput)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
                .frame(minHeight: 100, maxHeight: 320)
            }
        }
    }

    private var combinedRawOutput: String {
        var parts: [String] = []
        if !report.rawSummary.isEmpty {
            parts.append("docker system df\n\n\(report.rawSummary)")
        }
        if !report.rawVerbose.isEmpty {
            parts.append("docker system df -v\n\n\(report.rawVerbose)")
        }
        if parts.isEmpty { return "—" }
        return parts.joined(separator: "\n\n────────\n\n")
    }

    private func summaryTable(_ rows: [DockerDfSummaryRow]) -> some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                GridRow {
                    headerCell(L10n.Docker.dfColResource, minW: 120)
                    headerCell(L10n.Docker.dfColTotal, minW: 56)
                    headerCell(L10n.Docker.dfColActive, minW: 56)
                    headerCell(L10n.Docker.dfColSize, minW: 72)
                    headerCell(L10n.Docker.dfColReclaimable, minW: 120)
                }
                ForEach(rows) { row in
                    GridRow {
                        bodyCell(row.resourceType, minW: 120, mono: false)
                        bodyCell(row.total, minW: 56, mono: true)
                        bodyCell(row.active, minW: 56, mono: true)
                        bodyCell(row.size, minW: 72, mono: true)
                        bodyCell(row.reclaimable, minW: 120, mono: true)
                    }
                }
            }
            .padding(12)
        }
        .background {
            RoundedRectangle(cornerRadius: CS.cornerSmall, style: .continuous)
                .fill(Material.thin)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CS.cornerSmall, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func headerCell(_ title: String, minW: CGFloat) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(minWidth: minW, alignment: .leading)
    }

    private func bodyCell(_ value: String, minW: CGFloat, mono: Bool) -> some View {
        Text(value)
            .font(mono ? .system(.caption, design: .monospaced) : .caption)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .frame(minWidth: minW, alignment: .leading)
            .textSelection(.enabled)
    }

    private func detailSectionCard(_ section: DockerDfDetailSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title)
                .font(.headline)

            if !section.prefixLines.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(section.prefixLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }

            if section.columnTitles.isEmpty {
                if !section.orphanLines.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(section.orphanLines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(.subheadline, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                        GridRow {
                            ForEach(Array(section.columnTitles.enumerated()), id: \.offset) { _, title in
                                Text(title)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .frame(minWidth: 72, alignment: .leading)
                            }
                        }
                        ForEach(Array(section.rows.enumerated()), id: \.offset) { _, row in
                            GridRow {
                                ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                    Text(cell)
                                        .font(.system(.caption, design: .monospaced))
                                        .lineLimit(3)
                                        .minimumScaleFactor(0.8)
                                        .frame(minWidth: 72, alignment: .leading)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }
                    .padding(10)
                }
            }

            if !section.columnTitles.isEmpty, !section.orphanLines.isEmpty {
                Text(L10n.Docker.dfOrphanLinesNote)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                ForEach(Array(section.orphanLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: CS.cornerPanel, style: .continuous)
                .fill(Material.thin)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CS.cornerPanel, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
}
