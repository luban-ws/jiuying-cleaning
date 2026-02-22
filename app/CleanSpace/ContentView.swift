//
//  ContentView.swift
//  CleanSpace
//
//  主界面：由清理规则驱动，按分类展示、扫描占用、执行清理。
//

import SwiftUI

/// 按分类分组的规则
private func groupRulesByCategory(_ rules: [CleaningRule]) -> [(String, [CleaningRule])] {
    let grouped = Dictionary(grouping: rules) { $0.category }
    let order = ["system", "browser", "docker", "ai-tools", "custom"]
    return order.compactMap { key in
        guard let list = grouped[key], !list.isEmpty else { return nil }
        return (key, list.sorted { $0.name < $1.name })
    } + grouped.keys.filter { !order.contains($0) }.sorted().map { ($0, grouped[$0]!.sorted { $0.name < $1.name }) }
}

/// 格式化字节为可读字符串
private func formatBytes(_ bytes: Int64?) -> String {
    guard let bytes = bytes, bytes > 0 else { return "—" }
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}

struct ContentView: View {
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
        NavigationSplitView {
            RulesSidebarView(
                rules: rules,
                scannedSizes: scannedSizes,
                selectedRuleIds: $selectedRuleIds
            )
        } detail: {
            RulesDetailView(
                rules: rules,
                selectedRuleIds: selectedRuleIds,
                isScanning: isScanning,
                isCleaning: isCleaning,
                onScan: { scanAll() },
                onClean: { prepareAndConfirmClean() }
            )
        }
        .alert("清理确认", isPresented: $showCleanConfirm) {
            Button("取消", role: .cancel) { }
            Button("清理", role: .destructive) { performClean() }
        } message: {
            if let msg = statusMessage { Text(msg) }
        }
        .alert("清理结果", isPresented: $showCleanResult) {
            Button("确定", role: .cancel) { }
        } message: {
            if let msg = statusMessage { Text(msg) }
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedRuleIds.contains(id) { selectedRuleIds.remove(id) }
        else { selectedRuleIds.insert(id) }
    }

    private func scanAll() {
        isScanning = true
        Task {
            var next: [String: Int64] = [:]
            for rule in rules {
                if let bytes = scanRule(rule) { next[rule.id] = bytes }
            }
            await MainActor.run {
                scannedSizes = next
                isScanning = false
            }
        }
    }

    private func prepareAndConfirmClean() {
        rulesToClean = rules.filter { selectedRuleIds.contains($0.id) }
        let hasRisk = rulesToClean.contains { $0.riskLevel != .low }
        statusMessage = hasRisk ? "部分规则为中等或高风险，确认后将执行清理。" : "确认清理所选 \(rulesToClean.count) 项？"
        showCleanConfirm = true
    }

    private func performClean() {
        showCleanConfirm = false
        isCleaning = true
        let toClean = rulesToClean
        Task {
            let messages = toClean.map { rule in
                let result = cleanRule(rule)
                return "\(rule.name): \(result.success ? "成功" : "失败") \(result.message)"
            }
            await MainActor.run {
                isCleaning = false
                selectedRuleIds.subtract(toClean.map(\.id))
                for id in toClean.map(\.id) { scannedSizes.removeValue(forKey: id) }
                statusMessage = messages.joined(separator: "\n")
                showCleanResult = true
            }
        }
    }
}

// MARK: - 侧栏规则列表
private struct RulesSidebarView: View {
    let rules: [CleaningRule]
    let scannedSizes: [String: Int64]
    @Binding var selectedRuleIds: Set<String>

    var body: some View {
        listContent
            .navigationSplitViewColumnWidth(min: 260, ideal: 280)
            .navigationTitle("CleanSpace")
    }

    private var listContent: some View {
        let grouped = groupRulesByCategory(rules)
        return List {
            ForEach(Array(grouped.enumerated()), id: \.offset) { _, item in
                Section(CleaningRule.categoryDisplayName(item.0)) {
                    ForEach(item.1) { rule in
                        RuleRowView(
                            rule: rule,
                            sizeBytes: scannedSizes[rule.id],
                            estimate: rule.estimate,
                            isSelected: selectedRuleIds.contains(rule.id),
                            onToggle: { toggleSelection(rule.id) }
                        )
                    }
                }
            }
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedRuleIds.contains(id) { selectedRuleIds.remove(id) }
        else { selectedRuleIds.insert(id) }
    }
}

// MARK: - 详情区：说明与操作
private struct RulesDetailView: View {
    let rules: [CleaningRule]
    let selectedRuleIds: Set<String>
    let isScanning: Bool
    let isCleaning: Bool
    let onScan: () -> Void
    let onClean: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if rules.isEmpty {
                ContentUnavailableView(
                    "无清理规则",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("请确保 Resources 中存在 cleaning-rules.json")
                )
            } else {
                Text("已加载 \(rules.count) 条规则。勾选左侧规则后点击「扫描」计算占用，再点击「清理选中项」执行。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Button("扫描占用", action: onScan)
                        .buttonStyle(.borderedProminent)
                        .disabled(isScanning)
                    Button("清理选中项 (\(selectedRuleIds.count))", action: onClean)
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(selectedRuleIds.isEmpty || isCleaning)
                }
                if isScanning { ProgressView("扫描中…") }
                if isCleaning { ProgressView("清理中…") }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

/// 单条规则行：名称、风险、大小、勾选
struct RuleRowView: View {
    let rule: CleaningRule
    let sizeBytes: Int64?
    let estimate: String?
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.body)
                if let w = rule.warning, !w.isEmpty {
                    Text(w)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if rule.type == .command, let est = estimate {
                Text(est)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let bytes = sizeBytes {
                Text(formatBytes(bytes))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            riskBadge(rule.riskLevel)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func riskBadge(_ risk: CleaningRuleRisk) -> some View {
        switch risk {
        case .low:
            EmptyView()
        case .medium:
            Text("中")
                .font(.caption2)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(.orange.opacity(0.2))
                .cornerRadius(4)
        case .high:
            Text("高")
                .font(.caption2)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(.red.opacity(0.2))
                .cornerRadius(4)
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 560)
}
