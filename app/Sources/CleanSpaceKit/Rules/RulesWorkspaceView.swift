//
//  RulesWorkspaceView.swift
//  CleanSpaceKit
//
//  可扫选规则工作区：筛选栏 + 统一表格 + 检查器 + 底部命令栏。
//

import SwiftUI

enum RulesWorkspaceScope {
    case storageRules
    case aiToolsSpace
    case performance
}

struct RulesWorkspaceView: View {
    var scope: RulesWorkspaceScope = .storageRules

    @State private var allRules: [CleaningRule] = CleaningRulesLoader.loadMergedRules()
    @State private var scannedSizes: [String: Int64] = [:]
    @State private var scannedProcessCounts: [String: Int] = [:]
    @State private var selectedRuleIds: Set<String> = []
    @State private var tableSelection: Set<String> = []
    @State private var filter = RulesTableFilter()
    @State private var sortKey: RulesTableSortKey = .impact
    @State private var showChart = true
    @State private var isScanning = false
    @State private var isCleaning = false
    @State private var statusMessage: String?
    @State private var showCleanConfirm = false
    @State private var showCleanResult = false
    @State private var showDryRunSheet = false
    @State private var rulesToClean: [CleaningRule] = []
    /// RFC 004：分析后若捕获权限拒绝则展示引导条。
    @State private var showFullDiskAccessBanner = false

    private var presentation: RulesWorkspacePresentation {
        scope == .performance ? .performance : .storage
    }

    private var rules: [CleaningRule] {
        let activeRules = allRules.filter { !($0.hiddenFromRulesList ?? false) }
        switch scope {
        case .storageRules:
            return activeRules.filter { CleaningRule.CategoryId.storageRuleCategories.contains($0.category) }
        case .aiToolsSpace:
            return activeRules.filter { CleaningRule.CategoryId.aiToolsSpaceCategories.contains($0.category) }
        case .performance:
            return activeRules.filter { CleaningRule.CategoryId.performanceCategories.contains($0.category) }
        }
    }

    private var workspaceTitle: String {
        switch scope {
        case .storageRules: return L10n.Rules.navTitle
        case .aiToolsSpace: return L10n.Sidebar.aiToolsSpace
        case .performance: return L10n.Performance.navTitle
        }
    }

    private var visibleRules: [CleaningRule] {
        RulesTableModel.sorted(
            RulesTableModel.filtered(rules, filter: filter),
            by: sortKey,
            scannedSizes: scannedSizes,
            scannedProcessCounts: scannedProcessCounts
        )
    }

    private var categoryOptions: [String] {
        RulesTableModel.distinctCategories(in: rules)
    }

    private var showCategoryColumn: Bool {
        categoryOptions.count > 1
    }

    private var focusedRule: CleaningRule? {
        guard let id = tableSelection.first else { return nil }
        return rules.first { $0.id == id }
    }

    private var hasDirScanResults: Bool {
        presentation == .storage && rules.contains { rule in
            rule.type == .dir && (scannedSizes[rule.id] ?? 0) > 0
        }
    }

    private var rulesNavSubtitle: String? {
        guard !rules.isEmpty else { return nil }
        return L10n.Rules.navSubtitleSelected(selected: selectedRuleIds.count, total: rules.count)
    }

    private var selectedPathRules: [CleaningRule] {
        rules.filter { selectedRuleIds.contains($0.id) && $0.type == .dir }
    }

    private var selectedCommandRules: [CleaningRule] {
        rules.filter { selectedRuleIds.contains($0.id) && $0.type == .command }
    }

    private var selectedRecoverableBytes: Int64 {
        rules
            .filter { selectedRuleIds.contains($0.id) }
            .reduce(0) { $0 + (scannedSizes[$1.id] ?? 0) }
    }

    private var selectedProcessCount: Int {
        rules
            .filter { selectedRuleIds.contains($0.id) }
            .reduce(0) { $0 + (scannedProcessCounts[$1.id] ?? 0) }
    }

    private var sizedSelectedPathCount: Int {
        selectedPathRules.filter { scannedSizes[$0.id] != nil }.count
    }

    private var analyzedSelectedCount: Int {
        rules.filter { selectedRuleIds.contains($0.id) }.filter { rule in
            if rule.displaysScannedProcessCount {
                return scannedProcessCounts[rule.id] != nil
            }
            return scannedSizes[rule.id] != nil
        }.count
    }

    private var selectedInViewCount: Int {
        visibleRules.filter { selectedRuleIds.contains($0.id) }.count
    }

    private var scannedMetricCount: Int {
        switch presentation {
        case .storage:
            return scannedSizes.values.filter { $0 > 0 }.count
        case .performance:
            return scannedProcessCounts.values.filter { $0 > 0 }.count
        }
    }

    private var workspaceGuideText: String {
        switch scope {
        case .storageRules: return L10n.Rules.workspaceGuideStorage
        case .aiToolsSpace: return L10n.Rules.workspaceGuideAiTools
        case .performance: return L10n.Rules.workspaceGuidePerformance
        }
    }

    private var workspaceGuideSymbol: String {
        switch scope {
        case .storageRules: return "checklist"
        case .aiToolsSpace: return "sparkles.rectangle.stack"
        case .performance: return "bolt.horizontal.circle"
        }
    }

    private var confirmCleanButtonTitle: String {
        presentation == .performance ? L10n.Performance.boost : L10n.Rules.clean
    }

    var body: some View {
        Group {
            if rules.isEmpty {
                DetailScaffold {
                    ContentUnavailableView(
                        L10n.Rules.emptyTitle,
                        systemImage: "doc.text",
                        description: Text(L10n.Rules.emptyDescription)
                    )
                    .frame(maxWidth: .infinity, minHeight: 280)
                }
            } else {
                selectableBody
            }
        }
        .id(scope)
        .navigationTitle(workspaceTitle)
        .optionalNavigationSubtitle(rulesNavSubtitle)
        .toolbar {
            if hasDirScanResults {
                ToolbarItem(placement: .automatic) {
                    Toggle(isOn: $showChart) {
                        Label(L10n.Rules.chartCardTitle, systemImage: "chart.pie")
                    }
                    .help(L10n.Rules.chartCardTitle)
                }
            }
        }
        .alert(L10n.Rules.alertConfirmTitle, isPresented: $showCleanConfirm) {
            Button(L10n.Common.cancel, role: .cancel) { }
            Button(confirmCleanButtonTitle, role: .destructive) { performClean() }
        } message: {
            if let msg = statusMessage { Text(msg) }
        }
        .alert(L10n.Rules.alertResultTitle, isPresented: $showCleanResult) {
            Button(L10n.Common.ok, role: .cancel) { }
        } message: {
            if let msg = statusMessage { Text(msg) }
        }
        .sheet(isPresented: $showDryRunSheet) {
            RulesDryRunSheet(rules: rules.filter { selectedRuleIds.contains($0.id) })
        }
    }

    private var selectableBody: some View {
        SelectableWorkspaceScaffold {
            GeometryReader { windowProxy in
                VStack(spacing: 0) {
                    workspaceHeaderSection

                    if showChart && hasDirScanResults {
                        CSChartCard(title: L10n.Rules.chartCardTitle) {
                            RulesScanChartBlock(rules: rules, scannedSizes: scannedSizes)
                                .frame(minHeight: 260)
                        }
                        .padding(.horizontal, CS.detailHorizontalPadding)
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                    }

                    RulesFilterToolbar(
                        filter: $filter,
                        sortKey: $sortKey,
                        categories: categoryOptions,
                        visibleCount: visibleRules.count,
                        totalCount: rules.count,
                        selectedInViewCount: selectedInViewCount,
                        onSelectAllVisible: { selectAllVisible() },
                        onSelectNone: { selectedRuleIds.subtract(visibleRules.map(\.id)) },
                        onSelectAll: { selectedRuleIds = Set(rules.map(\.id)) }
                    )

                    Divider()

                    RulesWorkspaceTableInspectorLayout(
                        presentation: presentation,
                        tableMinWidth: RulesUnifiedTableLayout.minimumWidth(
                            showCategoryColumn: showCategoryColumn,
                            showTypeColumn: presentation != .performance,
                            compactItemColumn: presentation == .performance
                        )
                    ) {
                        Group {
                            if visibleRules.isEmpty {
                                ContentUnavailableView(
                                    L10n.Rules.filterNoResultsTitle,
                                    systemImage: "line.3.horizontal.decrease.circle",
                                    description: Text(L10n.Rules.filterNoResultsDescription)
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                RulesUnifiedTable(
                                    rules: visibleRules,
                                    scannedSizes: scannedSizes,
                                    scannedProcessCounts: scannedProcessCounts,
                                    selectedRuleIds: $selectedRuleIds,
                                    tableSelection: $tableSelection,
                                    formatBytes: formatBytesOptional,
                                    showCategoryColumn: showCategoryColumn,
                                    showTypeColumn: presentation != .performance,
                                    compactItemColumn: presentation == .performance,
                                    fillsAvailableHeight: true
                                )
                            }
                        }
                    } inspector: {
                        RulesInspectorPanel(
                            rule: focusedRule,
                            isIncluded: inspectorIncludeBinding,
                            scannedBytes: focusedRule.flatMap { scannedSizes[$0.id] },
                            scannedProcessCount: focusedRule.flatMap { scannedProcessCounts[$0.id] },
                            formatBytes: formatBytesOptional,
                            presentation: presentation
                        )
                    }
                    .frame(minHeight: 0, maxHeight: .infinity)
                    .layoutPriority(1)
                }
                .frame(width: windowProxy.size.width, height: windowProxy.size.height, alignment: .top)
                .clipped()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    RulesCommandBar(
                        recoverableBytes: selectedRecoverableBytes,
                        selectedProcessCount: selectedProcessCount,
                        selectedCount: selectedRuleIds.count,
                        selectedPathRuleCount: selectedPathRules.count,
                        selectedCommandRuleCount: selectedCommandRules.count,
                        sizedSelectedPathCount: sizedSelectedPathCount,
                        analyzedSelectedCount: analyzedSelectedCount,
                        rulesNonEmpty: !rules.isEmpty,
                        isScanning: isScanning,
                        isCleaning: isCleaning,
                        presentation: presentation,
                        onAnalyze: { scanAll() },
                        onPreview: { showDryRunSheet = true },
                        onRunClean: { prepareAndConfirmClean() }
                    )
                }
            }
        }
    }

    /// 引导条 + 统计芯片（与表格/命令栏分离，避免挤占底部操作区）。
    private var workspaceHeaderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            CSWorkspaceGuideBanner(text: workspaceGuideText, systemImage: workspaceGuideSymbol)
            if showFullDiskAccessBanner {
                FullDiskAccessBanner(
                    onOpenSettings: { FullDiskAccessGuidance.openFullDiskAccessSettings() },
                    onLater: { showFullDiskAccessBanner = false },
                    onDontAskAgain: {
                        FullDiskAccessGuidance.suppressGuidancePermanently()
                        showFullDiskAccessBanner = false
                    }
                )
            }
            overviewChips
        }
        .padding(.horizontal, CS.detailHorizontalPadding)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var overviewChips: some View {
        ViewThatFits(in: .horizontal) {
            overviewChipRow
            overviewChipStack
        }
    }

    private var overviewChipRow: some View {
        HStack(spacing: 8) {
            overviewChipViews
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var overviewChipStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            overviewChipViews
        }
    }

    @ViewBuilder
    private var overviewChipViews: some View {
        CSQuickStatChip(label: L10n.Rules.overviewChipTotal(rules.count))
        CSQuickStatChip(
            label: L10n.Rules.overviewChipSelected(selectedRuleIds.count),
            emphasized: selectedRuleIds.count > 0
        )
        CSQuickStatChip(
            label: presentation == .performance
                ? L10n.Performance.overviewChipAnalyzed(scannedMetricCount)
                : L10n.Rules.overviewChipScanned(scannedMetricCount),
            emphasized: scannedMetricCount > 0
        )
    }

    private var inspectorIncludeBinding: Binding<Bool> {
        Binding(
            get: {
                guard let id = focusedRule?.id else { return false }
                return selectedRuleIds.contains(id)
            },
            set: { checked in
                guard let id = focusedRule?.id else { return }
                if checked { selectedRuleIds.insert(id) }
                else { selectedRuleIds.remove(id) }
            }
        )
    }

    private func selectAllVisible() {
        visibleRules.forEach { selectedRuleIds.insert($0.id) }
    }

    private func formatBytesOptional(_ bytes: Int64?) -> String {
        guard let bytes, bytes > 0 else { return "—" }
        return SpaceFormat.bytes(bytes)
    }

    private func scanAll() {
        isScanning = true
        Task {
            var next: [String: Int64] = [:]
            var nextProcessCounts: [String: Int] = [:]
            var denialReport = AccessDenialReport.empty
            for rule in rules {
                if rule.displaysScannedProcessCount {
                    let processes = await McpLeakedProcessCleaner.listLeakedProcessesInBackground()
                    nextProcessCounts[rule.id] = processes.count
                    next[rule.id] = processes.reduce(0) { $0 + $1.rssBytes }
                } else {
                    let outcome = scanRuleWithAccessReport(rule)
                    if let b = outcome.bytes {
                        next[rule.id] = b
                    }
                    denialReport.merge(outcome.accessDenial)
                }
            }
            let shouldShowBanner = FullDiskAccessGuidance.shouldPresentBanner(
                deniedPaths: denialReport.deniedPaths
            )
            await MainActor.run {
                scannedSizes = next
                scannedProcessCounts = nextProcessCounts
                showFullDiskAccessBanner = shouldShowBanner
                isScanning = false
            }
        }
    }

    private func prepareAndConfirmClean() {
        rulesToClean = rules.filter { selectedRuleIds.contains($0.id) }
        let risky = rulesToClean.contains { $0.riskLevel != .low }
        statusMessage = risky ? L10n.Rules.confirmCleanRisky() : L10n.Rules.confirmCleanSafe(rulesToClean.count)
        showCleanConfirm = true
    }

    private func performClean() {
        showCleanConfirm = false
        isCleaning = true
        let batch = rulesToClean
        Task {
            var msgs: [String] = []
            for r in batch {
                let out: (success: Bool, message: String)
                if r.id == McpLeakedProcessCleaner.ruleId {
                    out = await McpLeakedProcessCleaner.cleanOutcomeInBackground()
                } else {
                    out = cleanRule(r)
                }
                msgs.append(L10n.Rules.cleanResultLine(name: r.name, success: out.success, message: out.message))
            }
            await MainActor.run {
                isCleaning = false
                selectedRuleIds.subtract(batch.map(\.id))
                tableSelection.subtract(batch.map(\.id))
                batch.map(\.id).forEach {
                    scannedSizes.removeValue(forKey: $0)
                    scannedProcessCounts.removeValue(forKey: $0)
                }
                statusMessage = msgs.joined(separator: "\n")
                showCleanResult = true
            }
        }
    }
}

// MARK: - 演练预览
struct RulesDryRunSheet: View {
    @Environment(\.dismiss) private var dismiss
    let rules: [CleaningRule]

    private var sortedRules: [CleaningRule] {
        rules.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(L10n.Rules.dryRunDisclaimer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(sortedRules) { rule in
                    Section(rule.name) {
                        dryRunSectionBody(for: rule)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(L10n.Rules.dryRunSheetTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.ok) { dismiss() }
                }
            }
        }
        .frame(minWidth: 440, minHeight: 380)
    }

    @ViewBuilder
    private func dryRunSectionBody(for rule: CleaningRule) -> some View {
        if rule.id == McpLeakedProcessCleaner.ruleId {
            RulesDryRunMcpProcessSection()
        } else {
            switch ruleDryRunPayload(for: rule) {
            case .directory(let targets):
                if targets.isEmpty {
                    Text(L10n.Rules.dryRunNoPaths)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(targets.enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.path)
                                .font(.body.monospaced())
                                .textSelection(.enabled)
                            if !item.exists {
                                Text(L10n.Rules.dryRunPathMissing)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            case .commandLine(let cmd):
                Text(cmd)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
            case .processes(let processes):
                RulesDryRunProcessList(processes: processes)
            case .noCommand:
                Text(L10n.Clean.missingCommand)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct RulesDryRunMcpProcessSection: View {
    @State private var processes: [(pid: Int32, commandLine: String)]?
    @State private var didLoad = false

    var body: some View {
        Group {
            if let processes {
                RulesDryRunProcessList(processes: processes)
            } else if didLoad {
                Text(L10n.Clean.mcpNoneFound)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(L10n.Rules.dryRunLoadingProcesses)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            let listed = await McpLeakedProcessCleaner.listLeakedProcessesInBackground()
            processes = listed.map { (pid: $0.pid, commandLine: $0.commandLine) }
            didLoad = true
        }
    }
}

private struct RulesDryRunProcessList: View {
    let processes: [(pid: Int32, commandLine: String)]

    var body: some View {
        if processes.isEmpty {
            Text(L10n.Clean.mcpNoneFound)
                .foregroundStyle(.secondary)
        } else {
            ForEach(Array(processes.enumerated()), id: \.offset) { _, item in
                Text(L10n.Rules.dryRunProcessLine(pid: item.pid, command: item.commandLine))
                    .font(.body.monospaced())
                    .textSelection(.enabled)
            }
        }
    }
}

// MARK: - navigationSubtitle
struct OptionalNavigationSubtitle: ViewModifier {
    let text: String?

    func body(content: Content) -> some View {
        if let text, !text.isEmpty {
            content.navigationSubtitle(text)
        } else {
            content
        }
    }
}

extension View {
    func optionalNavigationSubtitle(_ text: String?) -> some View {
        modifier(OptionalNavigationSubtitle(text: text))
    }
}
