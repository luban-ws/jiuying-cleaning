//
//  PerformanceRulesWorkspaceContent.swift
//  CleanSpaceKit
//
//  性能工作区：单栏卡片 + 内联进程列表（避免 Table/List 在少行场景下的列宽裁切）。
//

import SwiftUI

/// 性能页主内容：引导、芯片、操作卡、泄漏进程详情（RFC 010 命令栏仍由外层 `RulesCommandBar` 承载）。
struct PerformanceRulesWorkspaceContent: View {
    let rules: [CleaningRule]
    let scannedProcessCounts: [String: Int]
    let totalRuleCount: Int
    let selectedCount: Int
    let analyzedCount: Int
    let guideText: String
    let guideSymbol: String
    @Binding var selectedRuleIds: Set<String>
    @Binding var tableSelection: Set<String>

    private var focusedRule: CleaningRule? {
        if let id = tableSelection.first {
            return rules.first { $0.id == id }
        }
        return rules.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            CSWorkspaceGuideBanner(text: guideText, systemImage: guideSymbol)

            performanceOverviewChips

            performanceSectionHeader(L10n.Performance.workspaceActionsSectionTitle)

            VStack(spacing: 12) {
                ForEach(rules) { rule in
                    PerformanceActionCard(
                        rule: rule,
                        isIncluded: inclusionBinding(for: rule.id),
                        isFocused: tableSelection.contains(rule.id),
                        scannedProcessCount: scannedProcessCounts[rule.id],
                        onFocus: { tableSelection = [rule.id] }
                    )
                }
            }

            if let rule = focusedRule {
                performanceSectionHeader(L10n.Performance.workspaceProcessesSectionTitle)
                PerformanceProcessDetailCard(
                    rule: rule,
                    scannedProcessCount: scannedProcessCounts[rule.id]
                )
            }
        }
    }

    private var performanceOverviewChips: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { chipViews }
            VStack(alignment: .leading, spacing: 8) { chipViews }
        }
    }

    @ViewBuilder
    private var chipViews: some View {
        CSQuickStatChip(label: L10n.Rules.overviewChipTotal(totalRuleCount))
        CSQuickStatChip(
            label: L10n.Rules.overviewChipSelected(selectedCount),
            emphasized: selectedCount > 0
        )
        CSQuickStatChip(
            label: L10n.Performance.overviewChipAnalyzed(analyzedCount),
            emphasized: analyzedCount > 0
        )
    }

    private func performanceSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    private func inclusionBinding(for ruleId: String) -> Binding<Bool> {
        Binding(
            get: { selectedRuleIds.contains(ruleId) },
            set: { checked in
                if checked { selectedRuleIds.insert(ruleId) }
                else { selectedRuleIds.remove(ruleId) }
            }
        )
    }
}

// MARK: - 单条性能操作卡

private struct PerformanceActionCard: View {
    let rule: CleaningRule
    @Binding var isIncluded: Bool
    let isFocused: Bool
    let scannedProcessCount: Int?
    let onFocus: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Toggle("", isOn: $isIncluded)
                    .labelsHidden()
                    .toggleStyle(.checkbox)
                    .accessibilityLabel(rule.name)
                    .accessibilityHint(L10n.Rules.listA11yToggleHint)

                VStack(alignment: .leading, spacing: 6) {
                    Text(rule.name)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let warning = rule.warning, !warning.isEmpty {
                        Text(warning)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: onFocus)

                VStack(alignment: .trailing, spacing: 8) {
                    Text(
                        scannedProcessCount.map { L10n.Performance.listProcessCount($0) }
                            ?? L10n.Performance.listAnalyzeHint
                    )
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(scannedProcessCount == nil ? .tertiary : .secondary)
                    .help(L10n.Performance.listHelpScanColumn)

                    RuleRiskChip(risk: rule.riskLevel)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: CS.cornerPanel, style: .continuous)
                .fill(Material.regular)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CS.cornerPanel, style: .continuous)
                .strokeBorder(
                    isFocused ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.08),
                    lineWidth: isFocused ? 1.5 : 1
                )
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - 泄漏进程详情卡

private struct PerformanceProcessDetailCard: View {
    let rule: CleaningRule
    let scannedProcessCount: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RulesInspectorMcpProcessesView(scannedCount: scannedProcessCount)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: CS.cornerPanel, style: .continuous)
                .fill(Material.thin)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CS.cornerPanel, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .accessibilityLabel(rule.name)
    }
}
