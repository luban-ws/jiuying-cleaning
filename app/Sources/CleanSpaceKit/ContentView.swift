//
//  ContentView.swift
//  CleanSpace
//
//  侧栏导航 + 限宽详情区：NavigationSplitView + grouped Form，与当前 macOS HIG / 系统设置类应用一致。
//

import SwiftUI
import AppKit

// MARK: - 导航
private enum MainSection: String, CaseIterable, Identifiable {
    case volumes
    case rules
    case aiToolsSpace
    case docker
    case performance
    case monitor

    var id: String { rawValue }

    static let spaceSections: [MainSection] = [.volumes, .rules, .aiToolsSpace, .docker]
    static let resourceSections: [MainSection] = [.performance, .monitor]

    var title: String {
        switch self {
        case .volumes: return L10n.Sidebar.volumes
        case .rules: return L10n.Sidebar.rules
        case .aiToolsSpace: return L10n.Sidebar.aiToolsSpace
        case .docker: return L10n.Sidebar.docker
        case .performance: return L10n.Performance.navTitle
        case .monitor: return L10n.Sidebar.monitor
        }
    }

    var symbol: String {
        switch self {
        case .volumes: return "internaldrive"
        case .rules: return "checklist"
        case .aiToolsSpace: return "sparkles.rectangle.stack"
        case .docker: return "shippingbox"
        case .performance: return "bolt.fill"
        case .monitor: return "waveform.path.ecg"
        }
    }

    var subtitle: String {
        switch self {
        case .volumes: return L10n.Sidebar.volumesBlurb
        case .rules: return L10n.Sidebar.rulesBlurb
        case .aiToolsSpace: return L10n.Sidebar.aiToolsSpaceBlurb
        case .docker: return L10n.Sidebar.dockerBlurb
        case .performance: return L10n.Sidebar.performanceBlurb
        case .monitor: return L10n.Sidebar.monitorBlurb
        }
    }
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

// MARK: - 侧栏行（系统设置风格：单行标题 + help 副文案）
private struct SidebarNavRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.body)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
                .frame(width: 18, height: 18, alignment: .center)
                .accessibilityHidden(true)
            Text(title)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
        .help(subtitle)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

// MARK: - 根视图
public struct ContentView: View {
    @State private var section: MainSection = .volumes

    public init() {}

    private static let sidebarRowInsets = EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 10)

    public var body: some View {
        NavigationSplitView {
            List(selection: $section) {
                Section(L10n.Sidebar.spaceGroup) {
                    ForEach(MainSection.spaceSections) { item in
                        sidebarRow(item)
                    }
                }
                Section(L10n.Sidebar.resourcesGroup) {
                    ForEach(MainSection.resourceSections) { item in
                        sidebarRow(item)
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollIndicators(.hidden)
            .navigationTitle(L10n.App.name)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            Group {
                switch section {
                case .volumes:
                    VolumesWorkspaceView()
                case .rules:
                    RulesWorkspaceView(scope: .storageRules)
                case .aiToolsSpace:
                    RulesWorkspaceView(scope: .aiToolsSpace)
                case .docker:
                    DockerSpecialWorkspaceView()
                case .performance:
                    RulesWorkspaceView(scope: .performance)
                case .monitor:
                    SystemMonitorWorkspaceView()
                }
            }
            .id(section)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipped()
            .toolbarBackground(.automatic, for: .windowToolbar)
            .toolbarBackgroundVisibility(.automatic, for: .windowToolbar)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func sidebarRow(_ item: MainSection) -> some View {
        SidebarNavRow(title: item.title, subtitle: item.subtitle, systemImage: item.symbol)
            .tag(item)
            .listRowInsets(Self.sidebarRowInsets)
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
                            GridItem(.adaptive(minimum: 220, maximum: 360), spacing: 12)
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
    /// RFC 004：顶层扫描遇到权限拒绝时展示引导。
    @State private var showFullDiskAccessBanner = false

    private var selectedVolume: MountedVolume? {
        guard let id = selectedVolumeID else { return nil }
        return volumes.first { $0.id == id }
    }

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
                        if showFullDiskAccessBanner {
                            Section {
                                FullDiskAccessBanner(
                                    onOpenSettings: { FullDiskAccessGuidance.openFullDiskAccessSettings() },
                                    onLater: { showFullDiskAccessBanner = false },
                                    onDontAskAgain: {
                                        FullDiskAccessGuidance.suppressGuidancePermanently()
                                        showFullDiskAccessBanner = false
                                    }
                                )
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowBackground(Color.clear)
                        }

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

    private func volumeUsedBytesOnly(_ vol: MountedVolume) -> String {
        guard let t = vol.totalBytes, let f = vol.freeBytes, t > 0 else { return "—" }
        let used = max(0, t - f)
        return formatBytes(used)
    }

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

    private func formatExactByteCount(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }

    private func scanVolume(_ vol: MountedVolume) {
        scanning = true
        topFolders = []
        Task {
            let outcome = await VolumeScannerService.scanTopLevelFoldersWithAccessReport(on: vol.url)
            let shouldShowBanner = FullDiskAccessGuidance.shouldPresentBanner(
                deniedPaths: outcome.accessDenial.deniedPaths
            )
            await MainActor.run {
                topFolders = outcome.folders
                showFullDiskAccessBanner = shouldShowBanner
                scanning = false
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SystemMetricsController.shared)
        .frame(width: 1100, height: 720)
}
