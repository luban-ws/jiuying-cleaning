//
//  RulesWorkspaceLayout.swift
//  CleanSpaceKit
//
//  可扫选规则工作区：筛选栏、检查器、底部命令栏。
//

import SwiftUI

// MARK: - 筛选与批量选择
struct RulesFilterToolbar: View {
    @Binding var filter: RulesTableFilter
    @Binding var sortKey: RulesTableSortKey
    let categories: [String]
    let visibleCount: Int
    let totalCount: Int
    let selectedInViewCount: Int
    let onSelectAllVisible: () -> Void
    let onSelectNone: () -> Void
    let onSelectAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Rules.filterSectionTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            filterControls
            selectionControls
        }
        .padding(.horizontal, CS.detailHorizontalPadding)
        .padding(.vertical, 14)
        .background(Material.bar)
    }

    private var filterControls: some View {
        ViewThatFits(in: .horizontal) {
            filterControlsRow
            filterControlsStack
        }
    }

    private var filterControlsRow: some View {
        HStack(spacing: 12) {
            searchField
                .frame(maxWidth: 300)

            pickerControls

            Spacer(minLength: 8)

            visibleCountLabel
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var filterControlsStack: some View {
        VStack(alignment: .leading, spacing: 10) {
            searchField
                .frame(maxWidth: .infinity)
            pickerAndCountControls
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(L10n.Rules.filterSearchPlaceholder, text: $filter.searchText)
                .textFieldStyle(.roundedBorder)
        }
    }

    @ViewBuilder
    private var pickerControls: some View {
        if categories.count > 1 {
            Picker(L10n.Rules.filterCategoryLabel, selection: categoryBinding) {
                Text(L10n.Rules.filterAllCategories).tag(Optional<String>.none)
                ForEach(categories, id: \.self) { cat in
                    Text(CleaningRule.categoryDisplayName(cat)).tag(Optional(cat))
                }
            }
            .pickerStyle(.menu)
            .frame(width: 148)
        }

        Picker(L10n.Rules.filterSortLabel, selection: $sortKey) {
            ForEach(RulesTableSortKey.allCases) { key in
                Text(sortLabel(key)).tag(key)
            }
        }
        .pickerStyle(.menu)
        .frame(width: 132)
    }

    private var visibleCountLabel: some View {
        Text(L10n.Rules.filterVisibleFormat(visible: visibleCount, total: totalCount))
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }

    private var pickerAndCountControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                pickerControls
                Spacer(minLength: 8)
                visibleCountLabel
            }
            .fixedSize(horizontal: true, vertical: false)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    pickerControls
                }
                visibleCountLabel
            }
        }
    }

    private var selectionControls: some View {
        ViewThatFits(in: .horizontal) {
            selectionControlsRow
            selectionControlsStack
        }
    }

    private var selectionControlsRow: some View {
        HStack(spacing: 10) {
            batchControlGroup

            selectedInViewChip

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var selectionControlsStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            batchControlGroup
            selectedInViewChip
        }
    }

    private var batchControlGroup: some View {
        ControlGroup {
            Button(L10n.Rules.actionSelectAll, action: onSelectAll)
            Button(L10n.Rules.actionSelectFiltered, action: onSelectAllVisible)
                .disabled(visibleCount == 0)
            Button(L10n.Rules.actionSelectNone, action: onSelectNone)
                .disabled(selectedInViewCount == 0)
        }
        .controlSize(.small)
    }

    @ViewBuilder
    private var selectedInViewChip: some View {
        if selectedInViewCount > 0 {
            CSQuickStatChip(
                label: L10n.Rules.filterSelectedInViewFormat(selectedInViewCount),
                emphasized: true
            )
        }
    }

    private var categoryBinding: Binding<String?> {
        Binding(
            get: { filter.category },
            set: { filter.category = $0 }
        )
    }

    private func sortLabel(_ key: RulesTableSortKey) -> String {
        switch key {
        case .name: return L10n.Rules.sortName
        case .category: return L10n.Rules.sortCategory
        case .impact: return L10n.Rules.sortImpact
        case .risk: return L10n.Rules.sortRisk
        }
    }
}

// MARK: - 表格 + 检查器分栏（宽屏分栏，窄屏上下堆叠）
struct RulesWorkspaceTableInspectorLayout<Table: View, Inspector: View>: View {
    let presentation: RulesWorkspacePresentation
    let tableMinWidth: CGFloat
    @ViewBuilder var table: () -> Table
    @ViewBuilder var inspector: () -> Inspector

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width < tableMinWidth + 260 {
                stackedLayout
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            } else {
                sideBySideLayout
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            }
        }
        .frame(minHeight: 0, maxHeight: .infinity)
    }

    private var stackedLayout: some View {
        VStack(spacing: 0) {
            table()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .layoutPriority(1)
            Divider()
            inspector()
                .inspectorPanelLayout(.stacked)
                .layoutPriority(0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var sideBySideLayout: some View {
        HSplitView {
            table()
                .frame(minWidth: tableMinWidth, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .layoutPriority(1)
            inspector()
                .inspectorPanelLayout(.sidebar)
                .layoutPriority(0)
        }
    }
}

private enum RulesInspectorPanelLayout {
    case sidebar
    case stacked
}

private struct RulesInspectorPanelLayoutModifier: ViewModifier {
    let layout: RulesInspectorPanelLayout

    func body(content: Content) -> some View {
        switch layout {
        case .sidebar:
            content
                .frame(minWidth: 240, idealWidth: 280, maxWidth: 320)
                .frame(maxHeight: .infinity)
        case .stacked:
            // 窄窗：可伸缩高度，避免硬顶 200pt 裁切长路径/警告。
            content
                .frame(maxWidth: .infinity, minHeight: 180, idealHeight: 240, maxHeight: 320)
        }
    }
}

extension View {
    fileprivate func inspectorPanelLayout(_ layout: RulesInspectorPanelLayout) -> some View {
        modifier(RulesInspectorPanelLayoutModifier(layout: layout))
    }
}

// MARK: - 右侧检查器（单条规则详情）
struct RulesInspectorPanel: View {
    let rule: CleaningRule?
    @Binding var isIncluded: Bool
    let scannedBytes: Int64?
    let scannedProcessCount: Int?
    let formatBytes: (Int64?) -> String
    var presentation: RulesWorkspacePresentation = .storage

    var body: some View {
        VStack(spacing: 0) {
            Text(L10n.Rules.inspectorTitle)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let rule {
                        inspectorHeader(rule)
                        Divider()
                        inspectorMetrics(rule)
                        inspectorPathsOrCommand(rule)
                        Divider()
                        Toggle(L10n.Rules.inspectorInclude, isOn: $isIncluded)
                            .toggleStyle(.checkbox)
                    } else {
                        RulesInspectorEmptyState(presentation: presentation)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Material.thin)
    }

    @ViewBuilder
    private func inspectorHeader(_ rule: CleaningRule) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(rule.name)
                .font(.title3.weight(.semibold))
            Text(CleaningRule.categoryDisplayName(rule.category))
                .font(.caption)
                .foregroundStyle(.secondary)
            if let w = rule.warning, !w.isEmpty {
                Text(w)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            RuleRiskChip(risk: rule.riskLevel)
        }
    }

    @ViewBuilder
    private func inspectorMetrics(_ rule: CleaningRule) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(
                presentation == .performance
                    ? L10n.Performance.actionImpactLabel
                    : L10n.Rules.actionRecoverableLabel
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            if rule.displaysScannedProcessCount {
                Text(scannedProcessCount.map { L10n.Performance.listProcessCount($0) }
                    ?? L10n.Performance.listAnalyzeHint)
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
            } else if rule.displaysScannedByteSize {
                Text(formatBytes(scannedBytes))
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
            } else {
                Text(rule.estimate ?? L10n.Rules.estimateCommand)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func inspectorPathsOrCommand(_ rule: CleaningRule) -> some View {
        switch rule.type {
        case .dir:
            if let paths = rule.paths, !paths.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.Rules.inspectorPathsTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(Array(paths.enumerated()), id: \.offset) { _, block in
                        Text("\(block.base) → \(block.dirs.joined(separator: ", "))")
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        case .command:
            if let cmd = rule.command {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.Rules.inspectorCommandTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(cmd)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// 检查器空状态：避免 `ContentUnavailableView` 在窄栏内截断说明文案。
private struct RulesInspectorEmptyState: View {
    let presentation: RulesWorkspacePresentation

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "sidebar.right")
                .font(.system(size: 34))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)

            Text(L10n.Rules.inspectorEmptyTitle)
                .font(.headline)

            Text(emptyDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity, minHeight: 220)
        .accessibilityElement(children: .combine)
    }

    private var emptyDescription: String {
        presentation == .performance
            ? L10n.Rules.inspectorEmptyDescriptionPerformance
            : L10n.Rules.inspectorEmptyDescription
    }
}

// MARK: - 底部命令栏（分析 / 预览 / 清理 — 始终可见）
struct RulesCommandBar: View {
    let recoverableBytes: Int64
    let selectedProcessCount: Int
    let selectedCount: Int
    let selectedPathRuleCount: Int
    let selectedCommandRuleCount: Int
    let sizedSelectedPathCount: Int
    let analyzedSelectedCount: Int
    let rulesNonEmpty: Bool
    let isScanning: Bool
    let isCleaning: Bool
    var presentation: RulesWorkspacePresentation = .storage
    let onAnalyze: () -> Void
    let onPreview: () -> Void
    let onRunClean: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            commandBarRow
            commandBarStacked
        }
        .padding(.horizontal, CS.detailHorizontalPadding)
        .padding(.vertical, 14)
        .background {
            Rectangle()
                .fill(Material.bar)
                .overlay(alignment: .top) {
                    Divider()
                }
        }
    }

    private var commandBarStacked: some View {
        VStack(alignment: .leading, spacing: 12) {
            metricBlock
            if isScanning || isCleaning {
                progressRow
            }
            actionButtons
        }
    }

    private var commandBarRow: some View {
        HStack(alignment: .center, spacing: 16) {
            metricBlock
                .frame(minWidth: 160, alignment: .leading)

            if isScanning || isCleaning {
                progressRow
            }

            Spacer(minLength: 12)

            actionButtons
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var metricBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(metricLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(metricText)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(metricAccent ? Color.accentColor : .secondary)
                .lineLimit(presentation == .performance ? 2 : 1)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
            Text(captionText)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var progressRow: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text(isScanning ? scanningLabel : cleaningLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var actionButtons: some View {
        ViewThatFits(in: .horizontal) {
            actionButtonRow
            actionButtonStack
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.Rules.commandBarAccessibility)
    }

    private var actionButtonRow: some View {
        HStack(spacing: 10) {
            analyzeButton
            previewButton
            cleanButton
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var actionButtonStack: some View {
        VStack(spacing: 8) {
            analyzeButton
                .frame(maxWidth: .infinity)
            previewButton
                .frame(maxWidth: .infinity)
            cleanButton
                .frame(maxWidth: .infinity)
        }
    }

    private var analyzeButton: some View {
        Button(action: onAnalyze) {
            Label(L10n.Rules.scan, systemImage: "gauge.with.dots.needle.bottom.50percent")
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .help(L10n.Rules.helpScan)
        .disabled(!rulesNonEmpty || isScanning)
        .keyboardShortcut("r", modifiers: [.command, .shift])
    }

    private var previewButton: some View {
        Button(action: onPreview) {
            Label(L10n.Rules.dryRun, systemImage: "eye")
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .help(L10n.Rules.helpDryRun)
        .disabled(selectedCount == 0 || isCleaning)
        .keyboardShortcut("p", modifiers: [.command, .shift])
    }

    private var cleanButton: some View {
        Button(action: onRunClean) {
            Label(
                presentation == .performance ? L10n.Performance.boost : L10n.Rules.clean,
                systemImage: presentation == .performance ? "bolt.fill" : "trash"
            )
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .controlSize(.large)
        .help(L10n.Rules.helpClean)
        .disabled(selectedCount == 0 || isCleaning)
    }

    private var needsAnalyze: Bool {
        switch presentation {
        case .storage:
            return selectedPathRuleCount > 0 && sizedSelectedPathCount < selectedPathRuleCount
        case .performance:
            return selectedCount > 0 && analyzedSelectedCount < selectedCount
        }
    }

    private var metricText: String {
        if selectedCount == 0 {
            return presentation == .performance
                ? L10n.Performance.actionMetricPlaceholder
                : L10n.Rules.actionMetricPlaceholder
        }
        if needsAnalyze {
            return presentation == .performance
                ? L10n.Performance.actionMetricTapAnalyze
                : L10n.Rules.actionMetricTapAnalyze
        }
        switch presentation {
        case .storage:
            return SpaceFormat.bytes(recoverableBytes)
        case .performance:
            return L10n.Performance.actionMetricImpact(
                processes: selectedProcessCount,
                memoryBytes: recoverableBytes
            )
        }
    }

    private var metricAccent: Bool {
        guard selectedCount > 0, !needsAnalyze else { return false }
        switch presentation {
        case .storage: return recoverableBytes > 0
        case .performance: return selectedProcessCount > 0 || recoverableBytes > 0
        }
    }

    private var captionText: String {
        if selectedCount == 0 {
            return presentation == .performance
                ? L10n.Performance.actionCaptionNone
                : L10n.Rules.actionCaptionNone
        }
        if presentation == .performance {
            return L10n.Performance.actionCaptionSelected(selectedCount)
        }
        return L10n.Rules.actionCaptionCounts(
            selected: selectedCount,
            pathRules: selectedPathRuleCount,
            commandRules: selectedCommandRuleCount
        )
    }

    private var metricLabel: String {
        presentation == .performance
            ? L10n.Performance.actionImpactLabel
            : L10n.Rules.actionRecoverableLabel
    }

    private var scanningLabel: String {
        presentation == .performance ? L10n.Performance.scanning : L10n.Rules.scanning
    }

    private var cleaningLabel: String {
        presentation == .performance ? L10n.Performance.boosting : L10n.Rules.cleaning
    }
}
