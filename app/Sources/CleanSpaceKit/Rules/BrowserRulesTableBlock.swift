//
//  BrowserRulesTableBlock.swift
//  CleanSpaceKit
//
//  浏览器类规则以表格列表展示，便于逐项对照「清理 / 名称 / 体积 / 风险」。
//

import SwiftUI

/// 规则行尾的风险角标（与勾选列表行共用样式）
struct RuleRiskChip: View {
    let risk: CleaningRuleRisk

    var body: some View {
        switch risk {
        case .low:
            EmptyView()
        case .medium:
            Text(L10n.Rules.riskMedium)
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        case .high:
            Text(L10n.Rules.riskHigh)
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }
}

/// 浏览器缓存等规则：表格式列表 + 勾选参与清理
struct BrowserRulesTableBlock: View {
    let rules: [CleaningRule]
    let scannedSizes: [String: Int64]
    @Binding var selectedRuleIds: Set<String>
    let formatBytes: (Int64?) -> String

    var body: some View {
        Table(rules) {
            TableColumn(L10n.Rules.browserTableClean) { rule in
                Toggle(
                    "",
                    isOn: Binding(
                        get: { selectedRuleIds.contains(rule.id) },
                        set: { if $0 { selectedRuleIds.insert(rule.id) } else { selectedRuleIds.remove(rule.id) } }
                    )
                )
                .labelsHidden()
                .toggleStyle(.checkbox)
                .accessibilityLabel(rule.name)
                .accessibilityHint(L10n.Rules.listA11yToggleHint)
            }
            .width(52)

            TableColumn(L10n.Rules.browserTableItem) { rule in
                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.name)
                        .font(.body)
                    if let w = rule.warning, !w.isEmpty {
                        Text(w)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .width(min: 160, ideal: 220)

            TableColumn(L10n.Rules.browserTableSize) { rule in
                Group {
                    if rule.type == .command {
                        Text(rule.estimate ?? L10n.Rules.estimateCommand)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text(formatBytes(scannedSizes[rule.id]))
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .help(L10n.Rules.listHelpScanColumn)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(RulesScanListLayoutMetrics.scanColumnWidth)

            TableColumn(L10n.Rules.browserTableRisk) { rule in
                RuleRiskChip(risk: rule.riskLevel)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(RulesScanListLayoutMetrics.riskColumnWidth)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .frame(minHeight: CGFloat(min(380, max(120, 52 + rules.count * 32))))
    }
}
