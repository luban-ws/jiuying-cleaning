//
//  RulesScanCoordinator.swift
//  CleanSpaceDesktopIPC
//
//  异步规则扫描：IPC start 立即返回，后台队列逐条扫描并通过事件/ poll 汇报进度。
//

import CleanSpaceKit
import Foundation

public struct ScanStartResult: Sendable, Codable, Equatable {
    public let jobId: String
    public let total: Int

    public init(jobId: String, total: Int) {
        self.jobId = jobId
        self.total = total
    }
}

public struct ScanProgressEvent: Sendable, Codable, Equatable {
    public let jobId: String
    public let current: Int
    public let total: Int
    public let ruleId: String?
    public let sizes: [String: Int64]
    public let processCounts: [String: Int]
    public let deniedPaths: [String]

    public init(
        jobId: String,
        current: Int,
        total: Int,
        ruleId: String?,
        sizes: [String: Int64],
        processCounts: [String: Int],
        deniedPaths: [String]
    ) {
        self.jobId = jobId
        self.current = current
        self.total = total
        self.ruleId = ruleId
        self.sizes = sizes
        self.processCounts = processCounts
        self.deniedPaths = deniedPaths
    }
}

public struct ScanCompleteEvent: Sendable, Codable, Equatable {
    public let jobId: String
    public let result: ScanRulesResult

    public init(jobId: String, result: ScanRulesResult) {
        self.jobId = jobId
        self.result = result
    }
}

public struct ScanErrorEvent: Sendable, Codable, Equatable {
    public let jobId: String
    public let message: String

    public init(jobId: String, message: String) {
        self.jobId = jobId
        self.message = message
    }
}

public struct ScanJobStatus: Sendable, Codable, Equatable {
    public enum State: String, Sendable, Codable, Equatable {
        case running
        case completed
        case failed
    }

    public let state: State
    public let current: Int
    public let total: Int
    public let currentRuleId: String?
    public let sizes: [String: Int64]
    public let processCounts: [String: Int]
    public let deniedPaths: [String]
    public let result: ScanRulesResult?
    public let error: String?

    public init(
        state: State,
        current: Int,
        total: Int,
        currentRuleId: String?,
        sizes: [String: Int64],
        processCounts: [String: Int],
        deniedPaths: [String],
        result: ScanRulesResult? = nil,
        error: String? = nil
    ) {
        self.state = state
        self.current = current
        self.total = total
        self.currentRuleId = currentRuleId
        self.sizes = sizes
        self.processCounts = processCounts
        self.deniedPaths = deniedPaths
        self.result = result
        self.error = error
    }
}

/// 宿主注入：将扫描进度推送到 WebView（Velox events）。
public enum RulesScanEventSink {
    public nonisolated(unsafe) static var onProgress: ((ScanProgressEvent) -> Void)?
    public nonisolated(unsafe) static var onComplete: ((ScanCompleteEvent) -> Void)?
    public nonisolated(unsafe) static var onError: ((ScanErrorEvent) -> Void)?
}

public final class RulesScanCoordinator: @unchecked Sendable {
    public static let shared = RulesScanCoordinator()

    private struct Job {
        var state: ScanJobStatus.State = .running
        var current: Int = 0
        var total: Int = 0
        var currentRuleId: String?
        var sizes: [String: Int64] = [:]
        var processCounts: [String: Int] = [:]
        var deniedPaths: Set<String> = []
        var result: ScanRulesResult?
        var error: String?
    }

    private let lock = NSLock()
    private var jobs: [String: Job] = [:]
    private let workQueue = DispatchQueue(label: "cleanspace.rules.scan", qos: .userInitiated)
    private var lastProgressEmit: TimeInterval = 0
    private let progressEmitMinInterval: TimeInterval = 0.08

    public func start(scope: WorkspaceScope) throws -> ScanStartResult {
        let rules = CleanSpaceKitAPI.listRules(scope: scope)
        let jobId = UUID().uuidString
        let total = rules.count

        pruneFinishedJobs()
        lock.lock()
        jobs[jobId] = Job(state: .running, total: total)
        lastProgressEmit = 0
        lock.unlock()

        let ruleIds = rules.map(\.id)
        workQueue.async {
            self.runJob(jobId: jobId, ruleIds: ruleIds)
        }

        return ScanStartResult(jobId: jobId, total: total)
    }

    public func poll(jobId: String) throws -> ScanJobStatus {
        lock.lock()
        guard let job = jobs[jobId] else {
            lock.unlock()
            throw IPCError.notFound("scan job not found: \(jobId)")
        }
        let status = Self.status(from: job)
        lock.unlock()
        return status
    }

    private func pruneFinishedJobs() {
        lock.lock()
        jobs = jobs.filter { $0.value.state == .running }
        lock.unlock()
    }

    private func runJob(jobId: String, ruleIds: [String]) {
        for (index, ruleId) in ruleIds.enumerated() {
            lock.lock()
            if jobs[jobId] == nil {
                lock.unlock()
                return
            }
            jobs[jobId]?.current = index + 1
            jobs[jobId]?.currentRuleId = ruleId
            lock.unlock()

            let partial = CleanSpaceKitAPI.scanRules(ruleIds: [ruleId])
            lock.lock()
            guard var job = jobs[jobId] else {
                lock.unlock()
                return
            }
            for (key, value) in partial.sizes {
                job.sizes[key] = value
            }
            for (key, value) in partial.processCounts {
                job.processCounts[key] = value
            }
            for path in partial.deniedPaths {
                job.deniedPaths.insert(path)
            }
            jobs[jobId] = job
            let progress = ScanProgressEvent(
                jobId: jobId,
                current: job.current,
                total: job.total,
                ruleId: ruleId,
                sizes: job.sizes,
                processCounts: job.processCounts,
                deniedPaths: job.deniedPaths.sorted()
            )
            lock.unlock()
            emitProgressThrottled(progress)
        }

        lock.lock()
        guard var job = jobs[jobId] else {
            lock.unlock()
            return
        }
        let result = ScanRulesResult(
            sizes: job.sizes,
            processCounts: job.processCounts,
            deniedPaths: job.deniedPaths.sorted()
        )
        job.state = .completed
        job.result = result
        jobs[jobId] = job
        lock.unlock()

        let complete = ScanCompleteEvent(jobId: jobId, result: result)
        RulesScanEventSink.onComplete?(complete)
    }

    private func fail(jobId: String, message: String) {
        lock.lock()
        if var job = jobs[jobId] {
            job.state = .failed
            job.error = message
            jobs[jobId] = job
        }
        lock.unlock()
        RulesScanEventSink.onError?(ScanErrorEvent(jobId: jobId, message: message))
    }

    private func emitProgressThrottled(_ progress: ScanProgressEvent) {
        let now = ProcessInfo.processInfo.systemUptime
        let isFinal = progress.current >= progress.total
        if !isFinal && now - lastProgressEmit < progressEmitMinInterval {
            return
        }
        lastProgressEmit = now
        RulesScanEventSink.onProgress?(progress)
    }

    private static func status(from job: Job) -> ScanJobStatus {
        ScanJobStatus(
            state: job.state,
            current: job.current,
            total: job.total,
            currentRuleId: job.currentRuleId,
            sizes: job.sizes,
            processCounts: job.processCounts,
            deniedPaths: job.deniedPaths.sorted(),
            result: job.result,
            error: job.error
        )
    }
}
