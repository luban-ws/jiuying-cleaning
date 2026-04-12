//
//  ContentView.swift
//  CleanSpace
//
//  侧栏导航 + 限宽详情区：NavigationSplitView + grouped Form，与当前 macOS HIG / 系统设置类应用一致。
//

import SwiftUI
import AppKit

// MARK: - 导航
/// 侧栏顺序：清理类应用先展示「整机/卷空间」再进入「按规则清理」，专项能力放后。
private enum MainSection: String, CaseIterable, Identifiable {
    case volumes
    case rules
    case docker

    var id: String { rawValue }

    var title: String {
        switch self {
        case .volumes: return L10n.Sidebar.volumes
        case .rules: return L10n.Sidebar.rules
        case .docker: return L10n.Sidebar.docker
        }
    }

    var symbol: String {
        switch self {
        case .volumes: return "internaldrive"
        case .rules: return "checklist"
        case .docker: return "shippingbox"
        }
    }

    var subtitle: String {
        switch self {
        case .volumes: return L10n.Sidebar.volumesBlurb
        case .rules: return L10n.Sidebar.rulesBlurb
        case .docker: return L10n.Sidebar.dockerBlurb
        }
    }
}

private func groupRulesByCategory(_ rules: [CleaningRule]) -> [(String, [CleaningRule])] {
    let grouped = Dictionary(grouping: rules) { $0.category }
    let order = CleaningRule.CategoryId.ordered
    return order.compactMap { key in
        guard let list = grouped[key], !list.isEmpty else { return nil }
        return (key, list.sorted { $0.name < $1.name })
    } + grouped.keys.filter { !order.contains($0) }.sorted().map { ($0, grouped[$0]!.sorted { $0.name < $1.name }) }
}

private func formatBytes(_ bytes: Int64?) -> String {
    guard let bytes = bytes, bytes > 0 else { return "—" }
    let f = ByteCountFormatter()
    f.countStyle = .file
    return f.string(fromByteCount: bytes)
}

private func formatBytes(_ bytes: Int64) -> String {
    formatBytes(Optional(bytes))
}

// MARK: - 侧栏行（避免 Label + sidebar List 在部分系统上贴左裁字）
private struct SidebarNavRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .font(.body)
                .imageScale(.medium)
                .frame(width: 22, alignment: .center)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 根视图（供可执行目标导入）
public struct ContentView: View {
    @State private var section: MainSection = .volumes

    public init() {}

    /// 侧栏行水平 inset：双行文案略增高，仍防贴边裁字
    private static let sidebarRowInsets = EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 10)

    public var body: some View {
        NavigationSplitView {
            // 显式行内边距：避免 macOS 上 .sidebar List 与 Label 组合时首字贴边被裁切
            List(MainSection.allCases, selection: $section) { item in
                SidebarNavRow(title: item.title, subtitle: item.subtitle, systemImage: item.symbol)
                    .tag(item)
                    .listRowInsets(Self.sidebarRowInsets)
            }
            .listStyle(.sidebar)
            .scrollIndicators(.hidden)
            .navigationTitle(L10n.App.name)
            .navigationSplitViewColumnWidth(min: 232, ideal: 258, max: 320)
            .simultaneousGesture(WindowDragGesture())
        } detail: {
            NavigationStack {
                Group {
                    switch section {
                    case .volumes:
                        VolumesWorkspaceView()
                    case .rules:
                        RulesWorkspaceView()
                    case .docker:
                        DockerSpecialWorkspaceView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            // macOS 15+：显式参与窗口工具栏材质/可见性，与 unified 标题栏行为一致（见 Apple「Customizing window styles」）
            .toolbarBackground(.automatic, for: .windowToolbar)
            .toolbarBackgroundVisibility(.automatic, for: .windowToolbar)
        }
        // 系统监控在系统菜单栏 `MenuBarExtra` 中展示，不再占用窗口工具栏。
    }
}

// MARK: - 规则清理
private struct RulesWorkspaceView: View {
    @State private var rules: [CleaningRule] = CleaningRulesLoader.loadMergedRules()
    @State private var scannedSizes: [String: Int64] = [:]
    @State private var selectedRuleIds: Set<String> = []
    @State private var isScanning = false
    @State private var isCleaning = false
    @State private var statusMessage: String?
    @State private var showCleanConfirm = false
    @State private var showCleanResult = false
    @State private var showDryRunSheet = false
    @State private var rulesToClean: [CleaningRule] = []

    private var groupedRules: [(String, [CleaningRule])] {
        groupRulesByCategory(rules)
    }

    /// 是否存在至少一条 dir 规则已有正扫描值（用于展示图表区块）
    private var hasDirScanResults: Bool {
        rules.contains { rule in
            rule.type == .dir && (scannedSizes[rule.id] ?? 0) > 0
        }
    }

    /// 导航栏副标题：规则数量与勾选状态（空列表时不展示）。
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
        selectedPathRules.reduce(0) { $0 + (scannedSizes[$1.id] ?? 0) }
    }

    private var sizedSelectedPathCount: Int {
        selectedPathRules.filter { scannedSizes[$0.id] != nil }.count
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
                DetailScaffold {
                    Form {
                        Section {
                            CSRulesOverviewPanel(
                                totalRules: rules.count,
                                selectedCount: selectedRuleIds.count,
                                scannedWithSizeCount: scannedSizes.values.filter { $0 > 0 }.count
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)

                        // 先读步骤再看到操作卡：自上而下与「概览 → 怎么做 → 动手」一致（RFC 010）。
                        Section {
                            Text(L10n.Rules.flowSteps)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                        } header: {
                            Text(L10n.Rules.flowSectionTitle)
                                .font(.subheadline.weight(.semibold))
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 6, trailing: 0))

                        Section {
                            CSRulesCleanWorkflowCard(
                                recoverableBytes: selectedRecoverableBytes,
                                selectedCount: selectedRuleIds.count,
                                selectedPathRuleCount: selectedPathRules.count,
                                selectedCommandRuleCount: selectedCommandRules.count,
                                sizedSelectedPathCount: sizedSelectedPathCount,
                                rulesNonEmpty: !rules.isEmpty,
                                isScanning: isScanning,
                                isCleaning: isCleaning,
                                onAnalyze: { scanAll() },
                                onPreview: { showDryRunSheet = true },
                                onRunClean: { prepareAndConfirmClean() },
                                onSelectAll: { selectedRuleIds = Set(rules.map(\.id)) },
                                onSelectNone: { selectedRuleIds = [] }
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)

                        if hasDirScanResults {
                            Section {
                                CSChartCard(title: L10n.Rules.chartCardTitle) {
                                    RulesScanChartBlock(rules: rules, scannedSizes: scannedSizes)
                                        .frame(minHeight: 260)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        ForEach(Array(groupedRules.enumerated()), id: \.offset) { _, item in
                            if item.0 == CleaningRule.CategoryId.browser {
                                Section {
                                    BrowserRulesTableBlock(
                                        rules: item.1,
                                        scannedSizes: scannedSizes,
                                        selectedRuleIds: $selectedRuleIds,
                                        formatBytes: formatBytes
                                    )
                                } header: {
                                    Text(CleaningRule.categoryDisplayName(item.0))
                                }
                            } else {
                                Section(CleaningRule.categoryDisplayName(item.0)) {
                                    ForEach(item.1) { rule in
                                        RulesScanListRow(
                                            rule: rule,
                                            isIncluded: Binding(
                                                get: { selectedRuleIds.contains(rule.id) },
                                                set: { newValue in
                                                    if newValue { selectedRuleIds.insert(rule.id) }
                                                    else { selectedRuleIds.remove(rule.id) }
                                                }
                                            ),
                                            scannedBytes: scannedSizes[rule.id],
                                            formatBytes: formatBytes
                                        )
                                        .listRowInsets(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 8))
                                    }
                                }
                            }
                        }
                    }
                    .formStyle(.grouped)
                }
            }
        }
        .navigationTitle(L10n.Rules.navTitle)
        .optionalNavigationSubtitle(rulesNavSubtitle)
        .alert(L10n.Rules.alertConfirmTitle, isPresented: $showCleanConfirm) {
            Button(L10n.Common.cancel, role: .cancel) { }
            Button(L10n.Rules.clean, role: .destructive) { performClean() }
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

    private func scanAll() {
        isScanning = true
        Task {
            var next: [String: Int64] = [:]
            for rule in rules {
                if let b = scanRule(rule) { next[rule.id] = b }
            }
            await MainActor.run {
                scannedSizes = next
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
            let msgs = batch.map { r in
                let out = cleanRule(r)
                return L10n.Rules.cleanResultLine(name: r.name, success: out.success, message: out.message)
            }
            await MainActor.run {
                isCleaning = false
                selectedRuleIds.subtract(batch.map(\.id))
                batch.map(\.id).forEach { scannedSizes.removeValue(forKey: $0) }
                statusMessage = msgs.joined(separator: "\n")
                showCleanResult = true
            }
        }
    }
}

// MARK: - 规则演练预览（dry run，不删文件）
private struct RulesDryRunSheet: View {
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
        case .noCommand:
            Text(L10n.Clean.missingCommand)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Docker
private struct DockerSpecialWorkspaceView: View {
    @State private var dfReport = DockerDfReport.empty
    @State private var desktopRows: [(String, String, Int64)] = []
    @State private var logText = ""
    @State private var running = false
    @State private var runTotalSteps = 0
    @State private var runCompletedSteps = 0
    @State private var runActiveCommand = ""
    @State private var showPresetConfirm = false
    @State private var pendingPreset: DockerCleanPreset?

    var body: some View {
        DetailScaffold {
            Form {
                Section {
                    Text(L10n.Docker.intro)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if running {
                    Section {
                        DockerPresetRunProgressBlock(
                            completedSteps: runCompletedSteps,
                            totalSteps: runTotalSteps,
                            activeCommand: runActiveCommand
                        )
                    }
                }

                Section(L10n.Docker.sectionDesktop) {
                    if desktopRows.isEmpty {
                        Text(L10n.Docker.loading)
                            .foregroundStyle(.secondary)
                    } else {
                        CSChartCard(title: L10n.Docker.chartCardTitle) {
                            DockerDesktopChartBlock(rows: desktopRows)
                                .frame(minHeight: 140)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Button(L10n.Docker.refreshSizes) {
                        refreshDesktopScan()
                    }
                    .help(L10n.Docker.helpRefreshSizes)
                    .disabled(running)
                }

                Section {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                        ],
                        spacing: 12
                    ) {
                        ForEach(DockerCleanPreset.allCases) { preset in
                            CSDockerPresetCard(
                                symbolName: preset.symbolName,
                                title: preset.title,
                                subtitle: preset.subtitle,
                                actionTitle: preset.isDestructive ? L10n.Docker.execute : L10n.Docker.run,
                                isDestructive: preset.isDestructive,
                                disabled: running,
                                action: {
                                    pendingPreset = preset
                                    showPresetConfirm = true
                                }
                            )
                        }
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text(L10n.Docker.sectionPresets)
                }

                Section(L10n.Docker.sectionDf) {
                    Button(L10n.Docker.refreshOutput) {
                        refreshDf()
                    }
                    .help(L10n.Docker.helpRefreshDf)
                    .disabled(running)
                    DockerDiskUsageReportView(report: dfReport)
                }

                if running || !logText.isEmpty {
                    Section(L10n.Docker.sectionLog) {
                        CSMonospaceBlock(
                            text: logText,
                            placeholder: running && logText.isEmpty ? L10n.Docker.logStreamingPlaceholder : ""
                        )
                    }
                }
            }
            .formStyle(.grouped)
        }
        .navigationTitle(L10n.Sidebar.docker)
        .optionalNavigationSubtitle(L10n.Docker.navSubtitle)
        .onAppear {
            refreshDf()
            refreshDesktopScan()
        }
        .alert(L10n.Docker.alertTitle, isPresented: $showPresetConfirm) {
            Button(L10n.Common.cancel, role: .cancel) { pendingPreset = nil }
            if let p = pendingPreset, p.isDestructive {
                Button(L10n.Docker.alertRunDestructive, role: .destructive) {
                    if let x = pendingPreset { runPreset(x) }
                    pendingPreset = nil
                }
            } else {
                Button(L10n.Docker.alertRunSafe) {
                    if let x = pendingPreset { runPreset(x) }
                    pendingPreset = nil
                }
            }
        } message: {
            if let p = pendingPreset {
                Text(p.isDestructive ? L10n.Docker.alertMsgDestructive : L10n.Docker.alertMsgSafe)
            }
        }
    }

    private func refreshDf() {
        dfReport = DockerSpecialCleanService.dockerDiskUsageReport()
    }

    private func refreshDesktopScan() {
        desktopRows = DockerSpecialCleanService.desktopDataDirectoryBytes()
    }

    private func runPreset(_ preset: DockerCleanPreset) {
        let steps = preset.commandSteps
        running = true
        logText = ""
        runTotalSteps = steps.count
        runCompletedSteps = 0
        runActiveCommand = ""
        Task {
            await Task.detached { @Sendable in
                _ = DockerSpecialCleanService.runPreset(
                    preset,
                    onCommandWillRun: { _, total, cmd in
                        Task { @MainActor in
                            runTotalSteps = max(runTotalSteps, total)
                            runActiveCommand = cmd
                        }
                    },
                    onCommandDidRun: { _, _, cmd, ok, out in
                        Task { @MainActor in
                            runCompletedSteps += 1
                            let sym = ok ? "✓" : "✗"
                            logText += "\(sym) \(cmd)\n\(out)\n\n"
                        }
                    }
                )
            }.value
            await MainActor.run {
                running = false
                runActiveCommand = ""
                refreshDf()
                refreshDesktopScan()
            }
        }
    }
}

// MARK: - 磁盘
private struct VolumesWorkspaceView: View {
    @State private var volumes: [MountedVolume] = []
    @State private var selectedVolumeID: String?
    @State private var topFolders: [TopLevelFolderSize] = []
    @State private var scanning = false

    private var selectedVolume: MountedVolume? {
        guard let id = selectedVolumeID else { return nil }
        return volumes.first { $0.id == id }
    }

    /// 当前卷或未选择时的引导文案（无可用卷时不展示副标题）。
    private var diskNavSubtitle: String? {
        if let vol = selectedVolume {
            return vol.name
        }
        if volumes.isEmpty {
            return nil
        }
        return L10n.Disk.navSubtitlePickVolume
    }

    var body: some View {
        DetailScaffold {
            Form {
                if volumes.isEmpty {
                    Section {
                        Text(L10n.Disk.noVolumes)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        Picker(L10n.Disk.pickerLabel, selection: $selectedVolumeID) {
                            Text(L10n.Disk.pickerPlaceholder).tag(Optional<String>.none)
                            ForEach(volumes) { vol in
                                Text(volumePickerTitle(vol)).tag(Optional(vol.id))
                            }
                        }
                    } header: {
                        Text(L10n.Disk.sectionSource)
                    }

                    if let vol = selectedVolume {
                        Section {
                            CSVolumeHeroPanel(
                                volumeName: vol.name,
                                freeText: formatBytes(vol.freeBytes),
                                usedText: volumeUsedBytesOnly(vol),
                                totalText: formatBytes(vol.totalBytes),
                                usageRatio: volumeUsageRatio(vol)
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)

                        Section {
                            HStack(spacing: 12) {
                                Button {
                                    scanVolume(vol)
                                } label: {
                                    Label(L10n.Disk.scanTopLevel, systemImage: "folder.badge.gearshape")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .help(L10n.Disk.helpScanTopLevel)
                                .disabled(scanning)

                                Button {
                                    NSWorkspace.shared.open(vol.url)
                                } label: {
                                    Label(L10n.Disk.showInFinder, systemImage: "arrow.right.circle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                .help(L10n.Disk.helpShowInFinder)
                            }
                            if scanning {
                                HStack(spacing: 10) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text(L10n.Disk.scanning)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } header: {
                            Text(L10n.Disk.sectionQuickActions)
                        }

                        Section {
                            LabeledContent(L10n.Disk.path) {
                                Text(vol.url.path)
                                    .font(.caption)
                                    .textSelection(.enabled)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }

                        Section {
                            CSChartCard(title: L10n.Disk.chartCardTitle) {
                                DiskSpaceChartsBlock(
                                    totalBytes: vol.totalBytes,
                                    freeBytes: vol.freeBytes,
                                    topFolders: topFolders,
                                    unaccountedBytes: unaccountedGapBytes(for: vol),
                                    onOpenPath: { path in
                                        NSWorkspace.shared.open(URL(fileURLWithPath: path))
                                    }
                                )
                            }
                        }

                        Section(L10n.Disk.sectionTopLevel) {
                            if topFolders.isEmpty, !scanning {
                                Text(L10n.Disk.scanHintEmpty)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        if !topFolders.isEmpty,
                           let usedVolume = VolumeDiskAccounting.volumeUsedBytes(total: vol.totalBytes, free: vol.freeBytes) {
                            let summed = VolumeDiskAccounting.topLevelFoldersSum(topFolders)
                            let gap = VolumeDiskAccounting.unaccountedUsedBytes(volumeUsed: usedVolume, topLevelSum: summed)
                            Section {
                                LabeledContent(L10n.Disk.sumTopLevel) {
                                    Text(formatExactByteCount(summed))
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                LabeledContent(L10n.Disk.unaccounted) {
                                    Text(formatExactByteCount(gap))
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                            } header: {
                                Text(L10n.Disk.sectionAccounting)
                            } footer: {
                                Text(L10n.Disk.accountingFooter)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    } else {
                        Section {
                            Label(L10n.Disk.selectVolumeHint, systemImage: "internaldrive")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .symbolRenderingMode(.hierarchical)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 24)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .navigationTitle(L10n.Disk.navTitle)
        .optionalNavigationSubtitle(diskNavSubtitle)
        .onAppear {
            volumes = VolumeScannerService.listMountedVolumes()
            if selectedVolumeID == nil, let boot = volumes.first {
                selectedVolumeID = boot.id
            }
        }
    }

    private func volumePickerTitle(_ vol: MountedVolume) -> String {
        if let f = vol.freeBytes {
            return L10n.Disk.volumePickerLine(name: vol.name, freeFormatted: formatBytes(f))
        }
        return vol.name
    }

    /// 已用字节单行展示（首屏三列大数字需保持简短）。
    private func volumeUsedBytesOnly(_ vol: MountedVolume) -> String {
        guard let t = vol.totalBytes, let f = vol.freeBytes, t > 0 else { return "—" }
        let used = max(0, t - f)
        return formatBytes(used)
    }

    /// 已用占总容量比例，用于首屏线性进度条。
    private func volumeUsageRatio(_ vol: MountedVolume) -> Double? {
        guard let t = vol.totalBytes, let f = vol.freeBytes, t > 0 else { return nil }
        let used = max(0, t - f)
        return min(1, max(0, Double(used) / Double(t)))
    }

    private func unaccountedGapBytes(for vol: MountedVolume) -> Int64 {
        guard !topFolders.isEmpty,
              let u = VolumeDiskAccounting.volumeUsedBytes(total: vol.totalBytes, free: vol.freeBytes)
        else { return 0 }
        let sum = VolumeDiskAccounting.topLevelFoldersSum(topFolders)
        return VolumeDiskAccounting.unaccountedUsedBytes(volumeUsed: u, topLevelSum: sum)
    }

    /// 显示包括 0 在内的字节数（与「已用空间」对照用）
    private func formatExactByteCount(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }

    private func scanVolume(_ vol: MountedVolume) {
        scanning = true
        topFolders = []
        Task {
            let rows = await VolumeScannerService.scanTopLevelFolders(on: vol.url)
            await MainActor.run {
                topFolders = rows
                scanning = false
            }
        }
    }
}

// MARK: - navigationSubtitle（可选，避免空串占位）
/// 仅在字符串非空时应用 `navigationSubtitle`，与 HIG 中「标题 + 简短上下文」一致。
private struct OptionalNavigationSubtitle: ViewModifier {
    let text: String?

    func body(content: Content) -> some View {
        if let text, !text.isEmpty {
            content.navigationSubtitle(text)
        } else {
            content
        }
    }
}

private extension View {
    func optionalNavigationSubtitle(_ text: String?) -> some View {
        modifier(OptionalNavigationSubtitle(text: text))
    }
}

#Preview {
    ContentView()
        .environmentObject(SystemMetricsController.shared)
        .frame(width: 1000, height: 680)
}
