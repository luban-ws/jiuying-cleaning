//
//  ContentView.swift
//  CleanSpace
//
//  侧栏导航 + 限宽详情区，风格贴近 macOS「系统设置」。
//

import SwiftUI
import AppKit

// MARK: - 导航
private enum MainSection: String, CaseIterable, Identifiable {
    case rules
    case docker
    case volumes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rules: return "规则清理"
        case .docker: return "Docker"
        case .volumes: return "磁盘"
        }
    }

    var symbol: String {
        switch self {
        case .rules: return "checklist"
        case .docker: return "shippingbox"
        case .volumes: return "internaldrive"
        }
    }
}

private func groupRulesByCategory(_ rules: [CleaningRule]) -> [(String, [CleaningRule])] {
    let grouped = Dictionary(grouping: rules) { $0.category }
    let order = ["system", "browser", "docker", "ai-tools", "custom"]
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
    let systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .font(.body)
                .frame(width: 20, alignment: .center)
            Text(title)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 根视图（供可执行目标导入）
public struct ContentView: View {
    @State private var section: MainSection = .rules

    public init() {}

    /// 侧栏行水平 inset：与窗口左缘留出安全距离，防止首字被裁
    private static let sidebarRowInsets = EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 12)

    public var body: some View {
        NavigationSplitView {
            // 显式行内边距：避免 macOS 上 .sidebar List 与 Label 组合时首字贴边被裁切
            List(MainSection.allCases, selection: $section) { item in
                SidebarNavRow(title: item.title, systemImage: item.symbol)
                    .tag(item)
                    .listRowInsets(Self.sidebarRowInsets)
            }
            .listStyle(.sidebar)
            .scrollIndicators(.hidden)
            .navigationTitle("CleanSpace")
            .navigationSplitViewColumnWidth(min: 212, ideal: 228, max: 280)
        } detail: {
            NavigationStack {
                Group {
                    switch section {
                    case .rules:
                        RulesWorkspaceView()
                    case .docker:
                        DockerSpecialWorkspaceView()
                    case .volumes:
                        VolumesWorkspaceView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
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
    @State private var rulesToClean: [CleaningRule] = []

    private var groupedRules: [(String, [CleaningRule])] {
        groupRulesByCategory(rules)
    }

    var body: some View {
        Group {
            if rules.isEmpty {
                DetailScaffold {
                    ContentUnavailableView(
                        "没有规则",
                        systemImage: "doc.text",
                        description: Text("请检查 Bundle 中的 cleaning-rules.json。")
                    )
                    .frame(maxWidth: .infinity, minHeight: 280)
                }
            } else {
                DetailScaffold {
                    Form {
                        Section {
                            Text("勾选后先「扫描」再「清理」。命令类规则无精确体积时显示说明。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        ForEach(Array(groupedRules.enumerated()), id: \.offset) { _, item in
                            Section(CleaningRule.categoryDisplayName(item.0)) {
                                ForEach(item.1) { rule in
                                    ruleToggleRow(rule)
                                }
                            }
                        }
                    }
                    .formStyle(.grouped)
                }
            }
        }
        .navigationTitle("规则清理")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    scanAll()
                } label: {
                    Label("扫描", systemImage: "arrow.clockwise")
                }
                .disabled(isScanning || rules.isEmpty)
                Button {
                    prepareAndConfirmClean()
                } label: {
                    Label("清理", systemImage: "trash")
                }
                .disabled(selectedRuleIds.isEmpty || isCleaning)
            }
            ToolbarItem(placement: .status) {
                if isScanning || isCleaning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(isScanning ? "正在扫描…" : "正在清理…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .alert("清理确认", isPresented: $showCleanConfirm) {
            Button("取消", role: .cancel) { }
            Button("清理", role: .destructive) { performClean() }
        } message: {
            if let msg = statusMessage { Text(msg) }
        }
        .alert("清理结果", isPresented: $showCleanResult) {
            Button("好", role: .cancel) { }
        } message: {
            if let msg = statusMessage { Text(msg) }
        }
    }

    @ViewBuilder
    private func ruleToggleRow(_ rule: CleaningRule) -> some View {
        Toggle(isOn: Binding(
            get: { selectedRuleIds.contains(rule.id) },
            set: { if $0 { selectedRuleIds.insert(rule.id) } else { selectedRuleIds.remove(rule.id) } }
        )) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
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
                Spacer(minLength: 8)
                Group {
                    if rule.type == .command {
                        Text(rule.estimate ?? "命令")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text(formatBytes(scannedSizes[rule.id]))
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minWidth: 72, alignment: .trailing)
                riskTag(rule.riskLevel)
            }
        }
        .toggleStyle(.checkbox)
    }

    @ViewBuilder
    private func riskTag(_ risk: CleaningRuleRisk) -> some View {
        switch risk {
        case .low:
            EmptyView()
        case .medium:
            Text("中")
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        case .high:
            Text("高")
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
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
        statusMessage = risky ? "所选包含中/高风险项，确认后将执行。" : "确认清理 \(rulesToClean.count) 项？"
        showCleanConfirm = true
    }

    private func performClean() {
        showCleanConfirm = false
        isCleaning = true
        let batch = rulesToClean
        Task {
            let msgs = batch.map { r in
                let out = cleanRule(r)
                return "\(r.name): \(out.success ? "成功" : "失败") \(out.message)"
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

// MARK: - Docker
private struct DockerSpecialWorkspaceView: View {
    @State private var dfText = ""
    @State private var desktopRows: [(String, String, Int64)] = []
    @State private var logText = ""
    @State private var running = false
    @State private var showPresetConfirm = false
    @State private var pendingPreset: DockerCleanPreset?

    var body: some View {
        DetailScaffold {
            Form {
                Section {
                    Text("按顺序执行多条 docker 命令；可与「规则清理」中的单条命令配合。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section("本机 Docker Desktop 目录") {
                    if desktopRows.isEmpty {
                        Text("加载中…")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(desktopRows.enumerated()), id: \.offset) { _, row in
                            LabeledContent(row.0) {
                                Text(formatBytes(row.2))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button("重新计算目录占用") {
                        refreshDesktopScan()
                    }
                    .disabled(running)
                }

                Section("预设") {
                    ForEach(DockerCleanPreset.allCases) { preset in
                        HStack(alignment: .center, spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.title)
                                    .font(.body.weight(.medium))
                                Text(preset.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 12)
                            Button(preset.isDestructive ? "执行" : "运行") {
                                pendingPreset = preset
                                showPresetConfirm = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .tint(preset.isDestructive ? .red : Color.accentColor)
                            .disabled(running)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("docker system df -v") {
                    Button("刷新输出") {
                        refreshDf()
                    }
                    .disabled(running)
                    CSMonospaceBlock(text: dfText, placeholder: "点击「刷新输出」")
                }

                if !logText.isEmpty {
                    Section("执行日志") {
                        CSMonospaceBlock(text: logText, placeholder: "")
                    }
                }
            }
            .formStyle(.grouped)
            .disabled(running)
        }
        .navigationTitle("Docker")
        .onAppear {
            refreshDf()
            refreshDesktopScan()
        }
        .toolbar {
            ToolbarItem(placement: .status) {
                if running {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("执行中…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .alert("确认", isPresented: $showPresetConfirm) {
            Button("取消", role: .cancel) { pendingPreset = nil }
            if let p = pendingPreset, p.isDestructive {
                Button("执行清理", role: .destructive) {
                    if let x = pendingPreset { runPreset(x) }
                    pendingPreset = nil
                }
            } else {
                Button("运行") {
                    if let x = pendingPreset { runPreset(x) }
                    pendingPreset = nil
                }
            }
        } message: {
            if let p = pendingPreset {
                Text(p.isDestructive ? "将按顺序执行多条清理命令。" : "仅查询占用，不删除数据。")
            }
        }
    }

    private func refreshDf() {
        dfText = DockerSpecialCleanService.dockerSystemDf()
    }

    private func refreshDesktopScan() {
        desktopRows = DockerSpecialCleanService.desktopDataDirectoryBytes()
    }

    private func runPreset(_ preset: DockerCleanPreset) {
        running = true
        logText = ""
        Task {
            let lines = DockerSpecialCleanService.runPreset(preset)
            let text = lines.map { step in
                "\(step.success ? "✓" : "✗") \(step.command)\n\(step.output)"
            }.joined(separator: "\n\n")
            await MainActor.run {
                running = false
                logText = text
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

    var body: some View {
        DetailScaffold {
            Form {
                Section {
                    if volumes.isEmpty {
                        Text("未检测到可用卷。")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("选择卷", selection: $selectedVolumeID) {
                            Text("请选择磁盘").tag(Optional<String>.none)
                            ForEach(volumes) { vol in
                                Text(volumePickerTitle(vol)).tag(Optional(vol.id))
                            }
                        }
                    }
                }

                if let vol = selectedVolume {
                    Section {
                        LabeledContent("路径") {
                            Text(vol.url.path)
                                .font(.caption)
                                .textSelection(.enabled)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        if let t = vol.totalBytes, let f = vol.freeBytes, t > 0 {
                            let used = max(0, t - f)
                            let ratio = min(1, max(0, Double(used) / Double(t)))
                            VStack(alignment: .leading, spacing: 8) {
                                LabeledContent("已用空间") {
                                    Text("\(formatBytes(used)) / \(formatBytes(t))")
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                ProgressView(value: ratio)
                                    .progressViewStyle(.linear)
                                LabeledContent("可用") {
                                    Text(formatBytes(f))
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section("顶层文件夹") {
                        Button {
                            scanVolume(vol)
                        } label: {
                            Label("计算根目录下一层占用", systemImage: "folder.badge.gearshape")
                        }
                        .disabled(scanning)
                        Button("在访达中显示") {
                            NSWorkspace.shared.open(vol.url)
                        }
                        if scanning {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("正在统计…")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        ForEach(topFolders) { row in
                            LabeledContent(row.name) {
                                HStack(spacing: 10) {
                                    Text(formatBytes(row.bytes))
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                    Button("访达") {
                                        NSWorkspace.shared.open(URL(fileURLWithPath: row.path))
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                    }

                    if !topFolders.isEmpty,
                       let usedVolume = VolumeDiskAccounting.volumeUsedBytes(total: vol.totalBytes, free: vol.freeBytes) {
                        let summed = VolumeDiskAccounting.topLevelFoldersSum(topFolders)
                        let gap = VolumeDiskAccounting.unaccountedUsedBytes(volumeUsed: usedVolume, topLevelSum: summed)
                        Section("与系统已用对照") {
                            LabeledContent("顶层扫描合计") {
                                Text(formatExactByteCount(summed))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            LabeledContent("未由扫描计入") {
                                Text(formatExactByteCount(gap))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        } footer: {
                            Text(
                                "「已用空间」由系统报告；顶层各文件夹为对可读文件的估算。两者之差通常来自 APFS 快照、系统保留与「系统数据」、受保护或无权限路径、文件系统元数据等，属正常现象。"
                            )
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        }
                    }
                } else if !volumes.isEmpty {
                    Section {
                        Label("在菜单中选择磁盘后可查看空间并扫描顶层目录。", systemImage: "internaldrive")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 24)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .navigationTitle("磁盘")
        .onAppear {
            volumes = VolumeScannerService.listMountedVolumes()
            if selectedVolumeID == nil, let boot = volumes.first {
                selectedVolumeID = boot.id
            }
        }
    }

    private func volumePickerTitle(_ vol: MountedVolume) -> String {
        if let f = vol.freeBytes {
            return "\(vol.name)  ·  \(formatBytes(f)) 可用"
        }
        return vol.name
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

#Preview {
    ContentView()
        .frame(width: 1000, height: 680)
}
