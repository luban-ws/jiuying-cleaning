//
//  ContentView.swift
//  CleanSpace
//
//  界面：侧栏 + 分组表单 + 工具栏，风格贴近 macOS「系统设置」。
//

import SwiftUI
import AppKit

// MARK: - 导航（仅三项，避免首页营销感）
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

// MARK: - 根视图
struct ContentView: View {
    @State private var section: MainSection = .rules

    var body: some View {
        NavigationSplitView {
            List(MainSection.allCases, selection: $section) { item in
                Label(item.title, systemImage: item.symbol)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .navigationTitle("CleanSpace")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

    var body: some View {
        Group {
            if rules.isEmpty {
                ContentUnavailableView(
                    "没有规则",
                    systemImage: "doc.text",
                    description: Text("请检查 Bundle 中的 cleaning-rules.json。")
                )
            } else {
                Form {
                    Text("勾选条目后先扫描，再清理。命令类规则无精确体积时显示说明文字。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)

                    let grouped = groupRulesByCategory(rules)
                    ForEach(Array(grouped.enumerated()), id: \.offset) { _, item in
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
        }
        .overlay(alignment: .bottom) {
            if isScanning || isCleaning {
                ProgressView(isScanning ? "正在扫描…" : "正在清理…")
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CS.cornerSmall, style: .continuous))
                    .padding(.bottom, 20)
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
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.name)
                    if let w = rule.warning, !w.isEmpty {
                        Text(w)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
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
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        case .high:
            Text("高")
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Color.red.opacity(0.12))
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
        Form {
            Section {
                Text("按顺序执行多条 docker 命令；与「规则」里的单条命令可配合使用。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                        Spacer(minLength: 0)
                        Button(preset.isDestructive ? "执行" : "运行") {
                            pendingPreset = preset
                            showPresetConfirm = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(preset.isDestructive ? .red : Color.accentColor)
                        .disabled(running)
                    }
                    .padding(.vertical, 2)
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
        .navigationTitle("Docker")
        .onAppear {
            refreshDf()
            refreshDesktopScan()
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
        .overlay {
            if running {
                ZStack {
                    Color.black.opacity(0.12)
                    ProgressView("执行中…")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CS.cornerPanel, style: .continuous))
                }
                .ignoresSafeArea()
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
    @State private var selected: MountedVolume?
    @State private var topFolders: [TopLevelFolderSize] = []
    @State private var scanning = false

    var body: some View {
        HSplitView {
            List(selection: $selected) {
                Section("卷") {
                    ForEach(volumes) { vol in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(vol.name)
                                .font(.body.weight(.medium))
                            Text(vol.url.path)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            if let t = vol.totalBytes, let f = vol.freeBytes, t > 0 {
                                let used = max(0, t - f)
                                let ratio = min(1, max(0, Double(used) / Double(t)))
                                VStack(alignment: .leading, spacing: 4) {
                                    ProgressView(value: ratio)
                                        .progressViewStyle(.linear)
                                    HStack {
                                        Text("\(formatBytes(f)) 可用")
                                        Spacer()
                                        Text("共 \(formatBytes(t))")
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .tag(vol)
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 240, idealWidth: 260, maxWidth: 320)
            .onAppear { volumes = VolumeScannerService.listMountedVolumes() }

            detailPane
                .frame(minWidth: 380)
        }
        .navigationTitle("磁盘")
    }

    @ViewBuilder
    private var detailPane: some View {
        if let vol = selected {
            Form {
                Section {
                    LabeledContent("路径") {
                        Text(vol.url.path)
                            .font(.caption)
                            .textSelection(.enabled)
                            .multilineTextAlignment(.trailing)
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
                        HStack {
                            ProgressView()
                                .scaleEffect(0.85)
                            Text("正在统计…")
                                .foregroundStyle(.secondary)
                        }
                    }
                    ForEach(topFolders) { row in
                        LabeledContent(row.name) {
                            HStack(spacing: 8) {
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
            }
            .formStyle(.grouped)
        } else {
            ContentUnavailableView(
                "选择卷",
                systemImage: "internaldrive",
                description: Text("在左侧选择磁盘后，可扫描根目录下一层文件夹大小。")
            )
        }
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
