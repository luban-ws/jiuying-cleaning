//
//  RulesUnifiedTable.swift
//  CleanSpaceKit
//
//  统一规则表：所有分类共用 Table + 勾选列，支持扫读与批量选择。
//

import SwiftUI

enum RulesUnifiedTableLayout {
    /// 与 RFC 010 §2.5.6 Clean 列、BrowserRulesTableBlock 对齐。
    static let cleanColumnWidth: CGFloat = 52
    static let itemColumnMinWidth: CGFloat = 180
    static let itemColumnCompactMinWidth: CGFloat = 220
    static let categoryColumnMinWidth: CGFloat = 88
    static let typeColumnWidth: CGFloat = 72
    /// 与 `RulesScanListLayoutMetrics.scanColumnWidth`（RFC §2.5.5 Size = 108）对齐。
    static let sizeColumnWidth: CGFloat = RulesScanListLayoutMetrics.scanColumnWidth
    static let riskColumnWidth: CGFloat = RulesScanListLayoutMetrics.riskColumnWidth
    static let rowStride: CGFloat = 36
    /// macOS `Table(selection:)` 隐式行选列占用宽度（用于 minimumWidth 与列宽预算）。
    static let selectionColumnWidth: CGFloat = 28

    /// 所有列宽之和，避免 HSplitView 左侧过窄时表头/首列被裁切。
    static func minimumWidth(
        showCategoryColumn: Bool,
        showTypeColumn: Bool,
        compactItemColumn: Bool
    ) -> CGFloat {
        let itemWidth = compactItemColumn ? itemColumnCompactMinWidth : itemColumnMinWidth
        var total = cleanColumnWidth + itemWidth + sizeColumnWidth + riskColumnWidth
        // 仅 `Table(selection:)` 需要为隐式行选列留白；性能紧凑 List 无此列。
        if !compactItemColumn { total += selectionColumnWidth }
        if showTypeColumn { total += typeColumnWidth }
        if showCategoryColumn { total += categoryColumnMinWidth }
        return total + 24
    }

    /// 随规则行数增长的最小高度；不设固定上限，避免 macOS Table 表头被顶裁切。
    static func preferredMinHeight(ruleCount: Int, compactItemColumn: Bool, rules: [CleaningRule]) -> CGFloat {
        let rows = max(ruleCount, 1)
        if compactItemColumn {
            return min(380, max(128, 64 + CGFloat(rows) * rowStride))
        }
        let body = rules.reduce(CGFloat(0)) { partial, rule in
            partial + (rule.warning?.isEmpty == false ? 52 : rowStride)
        }
        let content = rules.isEmpty ? rowStride : body
        return min(420, max(128, 64 + content))
    }
}

/// 全工作区规则表（浏览器 / 系统 / 性能等同列展示）。
struct RulesUnifiedTable: View {
    let rules: [CleaningRule]
    let scannedSizes: [String: Int64]
    let scannedProcessCounts: [String: Int]
    @Binding var selectedRuleIds: Set<String>
    @Binding var tableSelection: Set<String>
    let formatBytes: (Int64?) -> String
    var showCategoryColumn: Bool = true
    /// 性能页仅进程类规则，可隐藏「类型」列以留出项目列宽度。
    var showTypeColumn: Bool = true
    /// 性能页等长说明规则：表格只显示标题，详情在右侧检查器。
    var compactItemColumn: Bool = false
    /// 为 false 时表格高度随内容收缩，避免少量行时出现大片空行。
    var fillsAvailableHeight: Bool = true

    private var itemColumnMin: CGFloat {
        compactItemColumn
            ? RulesUnifiedTableLayout.itemColumnCompactMinWidth
            : RulesUnifiedTableLayout.itemColumnMinWidth
    }

    var body: some View {
        if compactItemColumn {
            RulesCompactRulesList(
                rules: rules,
                scannedSizes: scannedSizes,
                scannedProcessCounts: scannedProcessCounts,
                selectedRuleIds: $selectedRuleIds,
                tableSelection: $tableSelection,
                formatBytes: formatBytes,
                fillsAvailableHeight: fillsAvailableHeight
            )
        } else {
            unifiedTableBody
        }
    }

    private var unifiedTableBody: some View {
        Table(rules, selection: $tableSelection) {
            TableColumn(L10n.Rules.browserTableClean) { rule in
                Toggle(
                    "",
                    isOn: Binding(
                        get: { selectedRuleIds.contains(rule.id) },
                        set: { checked in
                            if checked { selectedRuleIds.insert(rule.id) }
                            else { selectedRuleIds.remove(rule.id) }
                        }
                    )
                )
                .labelsHidden()
                .toggleStyle(.checkbox)
                .accessibilityLabel(rule.name)
                .accessibilityHint(L10n.Rules.listA11yToggleHint)
            }
            .width(RulesUnifiedTableLayout.cleanColumnWidth)

            TableColumn(L10n.Rules.browserTableItem) { rule in
                Text(rule.name)
                    .font(.body)
                    .lineLimit(compactItemColumn ? 2 : 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .width(min: itemColumnMin, ideal: itemColumnMin, max: .infinity)

            if showCategoryColumn {
                TableColumn(L10n.Rules.tableCategory) { rule in
                    Text(CleaningRule.categoryDisplayName(rule.category))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .width(min: RulesUnifiedTableLayout.categoryColumnMinWidth, ideal: 110, max: 150)
            }

            if showTypeColumn {
                TableColumn(L10n.Rules.tableType) { rule in
                    Text(ruleTypeLabel(rule))
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule(style: .continuous))
                }
                .width(min: 60, ideal: RulesUnifiedTableLayout.typeColumnWidth, max: 90)
            }

            TableColumn(L10n.Rules.browserTableSize) { rule in
                impactCell(for: rule)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(RulesUnifiedTableLayout.sizeColumnWidth)

            TableColumn(L10n.Rules.browserTableRisk) { rule in
                RuleRiskChip(risk: rule.riskLevel)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(RulesUnifiedTableLayout.riskColumnWidth)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .modifier(RulesUnifiedTableFrameModifier(
            showCategoryColumn: showCategoryColumn,
            showTypeColumn: showTypeColumn,
            compactItemColumn: compactItemColumn,
            fillsAvailableHeight: fillsAvailableHeight,
            ruleCount: rules.count,
            rules: rules
        ))
    }

    @ViewBuilder
    private func impactCell(for rule: CleaningRule) -> some View {
        if rule.displaysScannedProcessCount {
            Text(scannedProcessCounts[rule.id].map { L10n.Performance.listProcessCount($0) }
                ?? L10n.Performance.listAnalyzeHint)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(scannedProcessCounts[rule.id] == nil ? .tertiary : .secondary)
                .help(L10n.Performance.listHelpScanColumn)
        } else if rule.displaysScannedByteSize {
            Text(formatBytes(scannedSizes[rule.id]))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .help(L10n.Rules.listHelpScanColumn)
        } else {
            Text(rule.estimate ?? L10n.Rules.estimateCommand)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func ruleTypeLabel(_ rule: CleaningRule) -> String {
        switch rule.type {
        case .dir: return L10n.Rules.tableTypePath
        case .command: return L10n.Rules.tableTypeCommand
        }
    }
}

/// 表格外框：性能页等内容少时不拉伸高度，避免空行占位。
private struct RulesUnifiedTableFrameModifier: ViewModifier {
    let showCategoryColumn: Bool
    let showTypeColumn: Bool
    let compactItemColumn: Bool
    let fillsAvailableHeight: Bool
    let ruleCount: Int
    let rules: [CleaningRule]

    func body(content: Content) -> some View {
        let minW = RulesUnifiedTableLayout.minimumWidth(
            showCategoryColumn: showCategoryColumn,
            showTypeColumn: showTypeColumn,
            compactItemColumn: compactItemColumn
        )
        let minH = RulesUnifiedTableLayout.preferredMinHeight(
            ruleCount: ruleCount,
            compactItemColumn: compactItemColumn,
            rules: rules
        )
        if fillsAvailableHeight {
            content.frame(minWidth: minW, maxWidth: .infinity, minHeight: 120, maxHeight: .infinity, alignment: .topLeading)
        } else {
            content.frame(minWidth: minW, maxWidth: .infinity, minHeight: minH, alignment: .topLeading)
        }
    }
}

// MARK: - 性能页紧凑列表（规避 `Table(selection:)` 列宽裁切）
/// 与 `RulesScanListRow` 列度量一致；行选仅驱动检查器（RFC 010 D8），勾选独立。
private struct RulesCompactRulesList: View {
    let rules: [CleaningRule]
    let scannedSizes: [String: Int64]
    let scannedProcessCounts: [String: Int]
    @Binding var selectedRuleIds: Set<String>
    @Binding var tableSelection: Set<String>
    let formatBytes: (Int64?) -> String
    let fillsAvailableHeight: Bool

    private let rowHorizontalPadding: CGFloat = 12

    var body: some View {
        let minW = RulesUnifiedTableLayout.minimumWidth(
            showCategoryColumn: false,
            showTypeColumn: false,
            compactItemColumn: true
        )
        let minH = RulesUnifiedTableLayout.preferredMinHeight(
            ruleCount: rules.count,
            compactItemColumn: true,
            rules: rules
        )

        VStack(spacing: 0) {
            compactHeader
            Divider()
            List(rules, selection: $tableSelection) { rule in
                compactRow(rule)
                    .tag(rule.id)
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .frame(
            minWidth: minW,
            maxWidth: .infinity,
            minHeight: fillsAvailableHeight ? 120 : minH,
            maxHeight: fillsAvailableHeight ? .infinity : minH,
            alignment: .topLeading
        )
    }

    private var compactHeader: some View {
        HStack(spacing: 12) {
            Text(L10n.Rules.browserTableClean)
                .frame(width: RulesUnifiedTableLayout.cleanColumnWidth, alignment: .leading)
            Text(L10n.Rules.browserTableItem)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(L10n.Rules.browserTableSize)
                .frame(width: RulesScanListLayoutMetrics.scanColumnWidth, alignment: .trailing)
            Text(L10n.Rules.browserTableRisk)
                .frame(width: RulesScanListLayoutMetrics.riskColumnWidth, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, rowHorizontalPadding)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func compactRow(_ rule: CleaningRule) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Toggle(
                "",
                isOn: Binding(
                    get: { selectedRuleIds.contains(rule.id) },
                    set: { checked in
                        if checked { selectedRuleIds.insert(rule.id) }
                        else { selectedRuleIds.remove(rule.id) }
                    }
                )
            )
            .labelsHidden()
            .toggleStyle(.checkbox)
            .frame(width: RulesUnifiedTableLayout.cleanColumnWidth, alignment: .leading)
            .accessibilityLabel(rule.name)
            .accessibilityHint(L10n.Rules.listA11yToggleHint)

            Text(rule.name)
                .font(.body)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            impactCell(for: rule)
                .frame(width: RulesScanListLayoutMetrics.scanColumnWidth, alignment: .trailing)

            RuleRiskChip(risk: rule.riskLevel)
                .frame(width: RulesScanListLayoutMetrics.riskColumnWidth, alignment: .trailing)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func impactCell(for rule: CleaningRule) -> some View {
        if rule.displaysScannedProcessCount {
            Text(scannedProcessCounts[rule.id].map { L10n.Performance.listProcessCount($0) }
                ?? L10n.Performance.listAnalyzeHint)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(scannedProcessCounts[rule.id] == nil ? .tertiary : .secondary)
                .help(L10n.Performance.listHelpScanColumn)
        } else if rule.displaysScannedByteSize {
            Text(formatBytes(scannedSizes[rule.id]))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .help(L10n.Rules.listHelpScanColumn)
        } else {
            Text(rule.estimate ?? L10n.Rules.estimateCommand)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
