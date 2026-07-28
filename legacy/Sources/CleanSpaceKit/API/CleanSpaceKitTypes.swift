//
//  CleanSpaceKitTypes.swift
//  CleanSpaceKit
//
//  Velox / 外部宿主 IPC 用 DTO（Codable，不含 SwiftUI）。
//

import Foundation

/// 规则工作区范围（与 ContentView 侧栏一致）。
public enum WorkspaceScope: String, Codable, Sendable, CaseIterable {
    case rules
    case aiToolsSpace = "ai_tools_space"
    case performance
}

/// 规则列表行。
public struct RuleSummary: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let category: String
    public let risk: String
    public let type: String
    public let warning: String?
    public let estimate: String?

    public init(
        id: String,
        name: String,
        category: String,
        risk: String,
        type: String,
        warning: String?,
        estimate: String?
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.risk = risk
        self.type = type
        self.warning = warning
        self.estimate = estimate
    }
}

/// 批量扫描结果。
public struct ScanRulesResult: Sendable, Codable, Equatable {
    public let sizes: [String: Int64]
    public let processCounts: [String: Int]
    public let deniedPaths: [String]

    public init(sizes: [String: Int64], processCounts: [String: Int], deniedPaths: [String]) {
        self.sizes = sizes
        self.processCounts = processCounts
        self.deniedPaths = deniedPaths
    }
}

/// 单条规则预览。
public struct RulePreviewResult: Sendable, Codable, Equatable {
    public let kind: String
    public let directoryTargets: [RulePreviewDirectoryTarget]?
    public let commandLine: String?
    public let processes: [RulePreviewProcess]?

    public init(
        kind: String,
        directoryTargets: [RulePreviewDirectoryTarget]? = nil,
        commandLine: String? = nil,
        processes: [RulePreviewProcess]? = nil
    ) {
        self.kind = kind
        self.directoryTargets = directoryTargets
        self.commandLine = commandLine
        self.processes = processes
    }
}

public struct RulePreviewDirectoryTarget: Sendable, Codable, Equatable {
    public let path: String
    public let exists: Bool

    public init(path: String, exists: Bool) {
        self.path = path
        self.exists = exists
    }
}

public struct RulePreviewProcess: Sendable, Codable, Equatable {
    public let pid: Int32
    public let commandLine: String

    public init(pid: Int32, commandLine: String) {
        self.pid = pid
        self.commandLine = commandLine
    }
}

/// 清理结果（按规则 id）。
public struct CleanRulesResult: Sendable, Codable, Equatable {
    public struct Item: Sendable, Codable, Equatable {
        public let ruleId: String
        public let success: Bool
        public let message: String

        public init(ruleId: String, success: Bool, message: String) {
            self.ruleId = ruleId
            self.success = success
            self.message = message
        }
    }

    public let items: [Item]

    public init(items: [Item]) {
        self.items = items
    }
}

/// 已挂载卷摘要。
public struct VolumeSummary: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let path: String
    public let totalBytes: Int64?
    public let freeBytes: Int64?

    public init(id: String, name: String, path: String, totalBytes: Int64?, freeBytes: Int64?) {
        self.id = id
        self.name = name
        self.path = path
        self.totalBytes = totalBytes
        self.freeBytes = freeBytes
    }
}

/// 卷顶层目录扫描结果。
public struct VolumeScanResult: Sendable, Codable, Equatable {
    public let folders: [TopLevelFolderSummary]
    public let deniedPaths: [String]
    public let accounting: VolumeAccounting?

    public init(
        folders: [TopLevelFolderSummary],
        deniedPaths: [String],
        accounting: VolumeAccounting? = nil
    ) {
        self.folders = folders
        self.deniedPaths = deniedPaths
        self.accounting = accounting
    }
}

/// 卷扫描与系统「已用」对账（`VolumeDiskAccounting` 封装）。
public struct VolumeAccounting: Sendable, Codable, Equatable {
    public let volumeUsedBytes: Int64?
    public let topLevelSum: Int64
    public let unaccountedBytes: Int64?

    public init(volumeUsedBytes: Int64?, topLevelSum: Int64, unaccountedBytes: Int64?) {
        self.volumeUsedBytes = volumeUsedBytes
        self.topLevelSum = topLevelSum
        self.unaccountedBytes = unaccountedBytes
    }
}

public struct TopLevelFolderSummary: Sendable, Codable, Equatable, Identifiable {
    public let name: String
    public let path: String
    public let bytes: Int64

    public var id: String { path }

    public init(name: String, path: String, bytes: Int64) {
        self.name = name
        self.path = path
        self.bytes = bytes
    }
}

/// 一次性系统指标快照（无定时器）。
public struct MetricsSnapshot: Sendable, Codable, Equatable {
    public let cpuPercent: Double
    public let memoryPercent: Double
    public let memoryUsedBytes: UInt64
    public let memoryTotalBytes: UInt64
    public let networkUpBps: Double
    public let networkDownBps: Double

    public init(
        cpuPercent: Double,
        memoryPercent: Double,
        memoryUsedBytes: UInt64,
        memoryTotalBytes: UInt64,
        networkUpBps: Double = 0,
        networkDownBps: Double = 0
    ) {
        self.cpuPercent = cpuPercent
        self.memoryPercent = memoryPercent
        self.memoryUsedBytes = memoryUsedBytes
        self.memoryTotalBytes = memoryTotalBytes
        self.networkUpBps = networkUpBps
        self.networkDownBps = networkDownBps
    }
}

/// 网络接口累计字节（供 Velox 连续采样）。
public struct MetricsNetworkCounters: Sendable, Codable, Equatable {
    public let bytesIn: UInt64
    public let bytesOut: UInt64

    public init(bytesIn: UInt64, bytesOut: UInt64) {
        self.bytesIn = bytesIn
        self.bytesOut = bytesOut
    }
}

/// Docker `system df` 原始输出（结构化解析留在 SwiftUI 路径，Velox 先展示文本）。
public struct DockerDiskUsageResult: Sendable, Codable, Equatable {
    public let summaryOutput: String
    public let verboseOutput: String
    public let failed: Bool

    public init(summaryOutput: String, verboseOutput: String, failed: Bool) {
        self.summaryOutput = summaryOutput
        self.verboseOutput = verboseOutput
        self.failed = failed
    }
}

public struct DockerDesktopSizeRow: Sendable, Codable, Equatable, Identifiable {
    public let label: String
    public let path: String
    public let bytes: Int64

    public var id: String { path }

    public init(label: String, path: String, bytes: Int64) {
        self.label = label
        self.path = path
        self.bytes = bytes
    }
}

public struct DockerPresetRunResult: Sendable, Codable, Equatable {
    public let log: String
    public let success: Bool

    public init(log: String, success: Bool) {
        self.log = log
        self.success = success
    }
}

/// Docker 预设卡片元数据（文案由 Kit L10n 提供）。
public struct DockerPresetSummary: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let isDestructive: Bool

    public init(id: String, title: String, subtitle: String, isDestructive: Bool) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
    }
}

/// `docker system df` 结构化解析结果。
public struct DockerDiskUsageParsed: Sendable, Codable, Equatable {
    public let summaryRows: [DockerDfSummaryRowDTO]
    public let detailSections: [DockerDfDetailSectionDTO]
    public let summaryCommandFailed: Bool
    public let verboseCommandFailed: Bool
    public let fatalErrorText: String?
    public let rawSummary: String
    public let rawVerbose: String

    public init(
        summaryRows: [DockerDfSummaryRowDTO],
        detailSections: [DockerDfDetailSectionDTO],
        summaryCommandFailed: Bool,
        verboseCommandFailed: Bool,
        fatalErrorText: String?,
        rawSummary: String,
        rawVerbose: String
    ) {
        self.summaryRows = summaryRows
        self.detailSections = detailSections
        self.summaryCommandFailed = summaryCommandFailed
        self.verboseCommandFailed = verboseCommandFailed
        self.fatalErrorText = fatalErrorText
        self.rawSummary = rawSummary
        self.rawVerbose = rawVerbose
    }
}

public struct DockerDfSummaryRowDTO: Sendable, Codable, Equatable, Identifiable {
    public let resourceType: String
    public let total: String
    public let active: String
    public let size: String
    public let reclaimable: String

    public var id: String { resourceType }

    public init(resourceType: String, total: String, active: String, size: String, reclaimable: String) {
        self.resourceType = resourceType
        self.total = total
        self.active = active
        self.size = size
        self.reclaimable = reclaimable
    }
}

public struct DockerDfDetailSectionDTO: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let prefixLines: [String]
    public let columnTitles: [String]
    public let rows: [[String]]
    public let orphanLines: [String]

    public init(
        id: String,
        title: String,
        prefixLines: [String],
        columnTitles: [String],
        rows: [[String]],
        orphanLines: [String]
    ) {
        self.id = id
        self.title = title
        self.prefixLines = prefixLines
        self.columnTitles = columnTitles
        self.rows = rows
        self.orphanLines = orphanLines
    }
}

public struct OpenPathResult: Sendable, Codable, Equatable {
    public let success: Bool

    public init(success: Bool) {
        self.success = success
    }
}

public struct FdaBannerResult: Sendable, Codable, Equatable {
    public let shouldShow: Bool
    public let suppressed: Bool

    public init(shouldShow: Bool, suppressed: Bool) {
        self.shouldShow = shouldShow
        self.suppressed = suppressed
    }
}

public struct FdaSuppressResult: Sendable, Codable, Equatable {
    public let success: Bool

    public init(success: Bool) {
        self.success = success
    }
}
