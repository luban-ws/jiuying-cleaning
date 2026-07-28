//
//  CleanSpaceKitAPI.swift
//  CleanSpaceKit
//
//  对外稳定 API：供 Velox 等非 SwiftUI 宿主通过 SPM library 调用。
//

import AppKit
import Foundation

/// CleanSpaceKit 对外入口；新增 IPC 命令时在此扩展，保持内部类型 `internal`。
public enum CleanSpaceKitAPI {
    // MARK: - Rules

    /// 按工作区范围列出可见规则。
    public static func listRules(scope: WorkspaceScope = .rules) -> [RuleSummary] {
        rulesForScope(scope).map(ruleSummary(from:))
    }

    /// 扫描当前工作区全部规则（RFC 010 D4：分析=全量，与勾选无关）。
    public static func scanAllRules(scope: WorkspaceScope) -> ScanRulesResult {
        scanRules(ruleIds: rulesForScope(scope).map(\.id))
    }

    /// 扫描指定规则（体积 / 进程数），并返回权限拒绝路径。
    public static func scanRules(ruleIds: [String]) -> ScanRulesResult {
        let merged = mergedVisibleRules()
        let byId = Dictionary(uniqueKeysWithValues: merged.map { ($0.id, $0) })
        var sizes: [String: Int64] = [:]
        var processCounts: [String: Int] = [:]
        var denied: Set<String> = []

        for ruleId in ruleIds {
            guard let rule = byId[ruleId] else { continue }
            let outcome = scanRuleWithAccessReport(rule)
            if let bytes = outcome.bytes {
                sizes[ruleId] = bytes
            }
            if rule.displaysScannedProcessCount {
                processCounts[ruleId] = McpLeakedProcessCleaner.listLeakedProcesses().count
            }
            denied.formUnion(outcome.accessDenial.deniedPaths)
        }

        return ScanRulesResult(
            sizes: sizes,
            processCounts: processCounts,
            deniedPaths: denied.sorted()
        )
    }

    /// 预览单条规则将作用的对象（不删除、不计量）。
    public static func previewRule(ruleId: String) -> RulePreviewResult? {
        guard let rule = mergedVisibleRules().first(where: { $0.id == ruleId }) else {
            return nil
        }
        if rule.id == McpLeakedProcessCleaner.ruleId {
            let processes = McpLeakedProcessCleaner.listLeakedProcesses().map {
                RulePreviewProcess(pid: $0.pid, commandLine: $0.commandLine)
            }
            return RulePreviewResult(kind: "processes", processes: processes)
        }
        switch ruleDryRunPayload(for: rule) {
        case .directory(let targets):
            return RulePreviewResult(
                kind: "directory",
                directoryTargets: targets.map { RulePreviewDirectoryTarget(path: $0.path, exists: $0.exists) }
            )
        case .commandLine(let cmd):
            return RulePreviewResult(kind: "command", commandLine: cmd)
        case .processes(let rows):
            return RulePreviewResult(
                kind: "processes",
                processes: rows.map { RulePreviewProcess(pid: $0.pid, commandLine: $0.commandLine) }
            )
        case .noCommand:
            return RulePreviewResult(kind: "none")
        }
    }

    /// 对指定规则执行清理。
    public static func cleanRules(ruleIds: [String]) -> CleanRulesResult {
        let merged = mergedVisibleRules()
        let byId = Dictionary(uniqueKeysWithValues: merged.map { ($0.id, $0) })
        let items = ruleIds.compactMap { ruleId -> CleanRulesResult.Item? in
            guard let rule = byId[ruleId] else { return nil }
            let outcome = cleanRule(rule)
            return CleanRulesResult.Item(ruleId: ruleId, success: outcome.success, message: outcome.message)
        }
        return CleanRulesResult(items: items)
    }

    // MARK: - Volumes

    public static func listVolumes() -> [VolumeSummary] {
        VolumeScannerService.listMountedVolumes().map { vol in
            VolumeSummary(
                id: vol.id,
                name: vol.name,
                path: vol.url.path,
                totalBytes: vol.totalBytes,
                freeBytes: vol.freeBytes
            )
        }
    }

    public static func scanVolume(
        volumePath: String,
        totalBytes: Int64? = nil,
        freeBytes: Int64? = nil
    ) -> VolumeScanResult {
        let url = URL(fileURLWithPath: volumePath)
        let outcome = VolumeScannerService.scanTopLevelFoldersSynchronously(on: url)
        let folders = outcome.folders.map {
            TopLevelFolderSummary(name: $0.name, path: $0.path, bytes: $0.bytes)
        }
        let topSum = VolumeDiskAccounting.topLevelFoldersSum(outcome.folders)
        let used = VolumeDiskAccounting.volumeUsedBytes(total: totalBytes, free: freeBytes)
        let accounting = VolumeAccounting(
            volumeUsedBytes: used,
            topLevelSum: topSum,
            unaccountedBytes: used.map { VolumeDiskAccounting.unaccountedUsedBytes(volumeUsed: $0, topLevelSum: topSum) }
        )
        return VolumeScanResult(
            folders: folders,
            deniedPaths: outcome.accessDenial.deniedPaths.sorted(),
            accounting: accounting
        )
    }

    // MARK: - System

    /// 在 Finder 中打开路径或卷。
    public static func openPath(_ path: String) -> OpenPathResult {
        OpenPathResult(success: NSWorkspace.shared.open(URL(fileURLWithPath: path)))
    }

    /// 是否应展示完全磁盘访问引导条。
    public static func fdaShouldShowBanner(deniedPaths: [String]) -> FdaBannerResult {
        FdaBannerResult(
            shouldShow: FullDiskAccessGuidance.shouldPresentBanner(deniedPaths: deniedPaths),
            suppressed: FullDiskAccessGuidance.isGuidanceSuppressed
        )
    }

    @discardableResult
    public static func fdaOpenSettings() -> OpenPathResult {
        OpenPathResult(success: FullDiskAccessGuidance.openFullDiskAccessSettings())
    }

    public static func fdaSuppressGuidance() -> FdaSuppressResult {
        FullDiskAccessGuidance.suppressGuidancePermanently()
        return FdaSuppressResult(success: true)
    }

    // MARK: - Metrics

    public static func metricsSnapshot() -> MetricsSnapshot {
        metricsSnapshot(previousTicks: nil, previousNetwork: nil).snapshot
    }

    /// 连续两次采样估算 CPU 与网络速率（供 Velox 1.5s 轮询）。
    public static func metricsSnapshot(
        previousTicks: MetricsCpuTicks?,
        previousNetwork: MetricsNetworkCounters? = nil
    ) -> (snapshot: MetricsSnapshot, ticks: MetricsCpuTicks, network: MetricsNetworkCounters) {
        let mem = HostMachineStats.memoryUsage()
        let currentTicks = HostMachineStats.cpuLoadTicks()
        let cpuPercent: Double
        if let currentTicks, let previous = previousTicks {
            cpuPercent = HostMachineStats.cpuPercentSince(
                previous: (previous.user, previous.system, previous.idle, previous.nice),
                current: (currentTicks.user, currentTicks.system, currentTicks.idle, currentTicks.nice)
            )
        } else {
            cpuPercent = 0
        }
        let ticks = currentTicks.map {
            MetricsCpuTicks(user: $0.user, system: $0.system, idle: $0.idle, nice: $0.nice)
        } ?? previousTicks ?? MetricsCpuTicks(user: 0, system: 0, idle: 0, nice: 0)

        let curNet = NetworkInterfaceCounters.totalBytesInOut()
        let networkCounters = MetricsNetworkCounters(bytesIn: curNet.in, bytesOut: curNet.out)
        let (networkDownBps, networkUpBps) = networkRates(current: curNet, previous: previousNetwork)

        let snapshot = MetricsSnapshot(
            cpuPercent: cpuPercent,
            memoryPercent: mem.percent,
            memoryUsedBytes: mem.usedBytes,
            memoryTotalBytes: mem.totalBytes,
            networkUpBps: networkUpBps,
            networkDownBps: networkDownBps
        )
        return (snapshot, ticks, networkCounters)
    }

    // MARK: - Docker

    public static func dockerDiskUsage() -> DockerDiskUsageResult {
        let report = DockerSpecialCleanService.dockerDiskUsageReport()
        return DockerDiskUsageResult(
            summaryOutput: report.rawSummary,
            verboseOutput: report.rawVerbose,
            failed: report.summaryCommandFailed || report.verboseCommandFailed || report.fatalErrorText != nil
        )
    }

    public static func dockerDiskUsageParsed() -> DockerDiskUsageParsed {
        let report = DockerSpecialCleanService.dockerDiskUsageReport()
        return DockerDiskUsageParsed(
            summaryRows: report.summaryRows.map {
                DockerDfSummaryRowDTO(
                    resourceType: $0.resourceType,
                    total: $0.total,
                    active: $0.active,
                    size: $0.size,
                    reclaimable: $0.reclaimable
                )
            },
            detailSections: report.detailSections.map {
                DockerDfDetailSectionDTO(
                    id: $0.id,
                    title: $0.title,
                    prefixLines: $0.prefixLines,
                    columnTitles: $0.columnTitles,
                    rows: $0.rows,
                    orphanLines: $0.orphanLines
                )
            },
            summaryCommandFailed: report.summaryCommandFailed,
            verboseCommandFailed: report.verboseCommandFailed,
            fatalErrorText: report.fatalErrorText,
            rawSummary: report.rawSummary,
            rawVerbose: report.rawVerbose
        )
    }

    public static func dockerPresets() -> [DockerPresetSummary] {
        DockerCleanPreset.allCases.map { preset in
            DockerPresetSummary(
                id: preset.rawValue,
                title: preset.title,
                subtitle: preset.subtitle,
                isDestructive: preset.isDestructive
            )
        }
    }

    public static func dockerDesktopSizes() -> [DockerDesktopSizeRow] {
        DockerSpecialCleanService.desktopDataDirectoryBytes().map { label, path, bytes in
            DockerDesktopSizeRow(label: label, path: path, bytes: bytes)
        }
    }

    public static func dockerRunPreset(presetId: String) -> DockerPresetRunResult {
        guard let preset = DockerCleanPreset(rawValue: presetId) else {
            return DockerPresetRunResult(log: "Unknown preset: \(presetId)", success: false)
        }
        let collector = DockerRunLogCollector()
        _ = DockerSpecialCleanService.runPreset(
            preset,
            onCommandWillRun: { _, _, cmd in
                collector.append("$ \(cmd)\n")
            },
            onCommandDidRun: { _, _, cmd, ok, out in
                let sym = ok ? "✓" : "✗"
                collector.append("\(sym) \(cmd)\n\(out)\n\n")
                if !ok { collector.markFailure() }
            }
        )
        return DockerPresetRunResult(log: collector.log, success: collector.allOK)
    }

    public static func dockerPresetIds() -> [String] {
        DockerCleanPreset.allCases.map(\.rawValue)
    }

    // MARK: - Private

    private static func mergedVisibleRules() -> [CleaningRule] {
        CleaningRulesLoader.loadMergedRules().filter { !($0.hiddenFromRulesList ?? false) }
    }

    private static func rulesForScope(_ scope: WorkspaceScope) -> [CleaningRule] {
        let active = mergedVisibleRules()
        switch scope {
        case .rules:
            return active.filter { CleaningRule.CategoryId.storageRuleCategories.contains($0.category) }
        case .aiToolsSpace:
            return active.filter { CleaningRule.CategoryId.aiToolsSpaceCategories.contains($0.category) }
        case .performance:
            return active.filter { CleaningRule.CategoryId.performanceCategories.contains($0.category) }
        }
    }

    private static func ruleSummary(from rule: CleaningRule) -> RuleSummary {
        RuleSummary(
            id: rule.id,
            name: rule.name,
            category: rule.category,
            risk: rule.risk?.rawValue ?? CleaningRuleRisk.low.rawValue,
            type: rule.type.rawValue,
            warning: rule.warning,
            estimate: rule.estimate
        )
    }

    private static func networkRates(
        current: (in: UInt64, out: UInt64),
        previous: MetricsNetworkCounters?
    ) -> (downBps: Double, upBps: Double) {
        guard let previous else { return (0, 0) }
        // Velox 轮询间隔由前端控制；此处用固定 1.5s 估计（与 SystemMetricsController 一致）。
        let seconds = 1.5
        let down = deltaBytesPerSecond(current: current.in, previous: previous.bytesIn, seconds: seconds)
        let up = deltaBytesPerSecond(current: current.out, previous: previous.bytesOut, seconds: seconds)
        return (down, up)
    }

    private static func deltaBytesPerSecond(current: UInt64, previous: UInt64, seconds: Double) -> Double {
        guard seconds > 0, current >= previous else { return 0 }
        return Double(current - previous) / seconds
    }
}

/// CPU tick 快照，供 Velox 连续采样。
public struct MetricsCpuTicks: Sendable, Codable, Equatable {
    public let user: UInt64
    public let system: UInt64
    public let idle: UInt64
    public let nice: UInt64

    public init(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }
}
