//
//  RulesScanListRow.swift
//  CleanSpaceKit
//
//  非浏览器类规则：分组 Form 中的扫描列表行。列宽与 `BrowserRulesTableBlock` 的 Table 对齐，
//  便于用户在「表格」与「勾选列表」之间获得一致的扫读体验（macOS HIG：稳定列、指针 `.help`）。
//

import SwiftUI

/// 规则扫描列表与浏览器表格共用的列度量，避免「大小 / 风险」列忽宽忽窄。
enum RulesScanListLayoutMetrics {
    /// 与 `BrowserRulesTableBlock` 中 Size 列理想宽度接近，容纳本地化后的字节串。
    static let scanColumnWidth: CGFloat = 108
    /// 与 `BrowserRulesTableBlock` 中 Risk 列一致。
    static let riskColumnWidth: CGFloat = 56
}

/// 单条规则的勾选行：名称 + 警告 + 扫描体积 + 风险角标。
struct RulesScanListRow: View {
    let rule: CleaningRule
    @Binding var isIncluded: Bool
    /// `nil` 表示尚未扫描到该规则。
    let scannedBytes: Int64?
    let formatBytes: (Int64?) -> String

    var body: some View {
        Toggle(isOn: $isIncluded) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(rule.name)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                    if let w = rule.warning, !w.isEmpty {
                        Text(w)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    Group {
                        if rule.type == .command {
                            Text(rule.estimate ?? L10n.Rules.estimateCommand)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text(formatBytes(scannedBytes))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                                .help(L10n.Rules.listHelpScanColumn)
                        }
                    }
                    .frame(width: RulesScanListLayoutMetrics.scanColumnWidth, alignment: .trailing)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                    RuleRiskChip(risk: rule.riskLevel)
                        .frame(width: RulesScanListLayoutMetrics.riskColumnWidth, alignment: .trailing)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .contentShape(Rectangle())
        }
        .toggleStyle(.checkbox)
        .accessibilityHint(L10n.Rules.listA11yToggleHint)
    }
}
