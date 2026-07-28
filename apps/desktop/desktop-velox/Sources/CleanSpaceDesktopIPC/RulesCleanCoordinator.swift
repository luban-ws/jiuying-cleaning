//
//  RulesCleanCoordinator.swift
//  CleanSpaceDesktopIPC
//

import CleanSpaceKit
import Foundation

public struct RulesCleanJobStatus: Sendable, Codable, Equatable {
    public let state: IPCJobState
    public let current: Int
    public let total: Int
    public let currentRuleId: String?
    public let result: CleanRulesResult?
    public let error: String?

    public init(
        state: IPCJobState,
        current: Int,
        total: Int,
        currentRuleId: String?,
        result: CleanRulesResult? = nil,
        error: String? = nil
    ) {
        self.state = state
        self.current = current
        self.total = total
        self.currentRuleId = currentRuleId
        self.result = result
        self.error = error
    }
}

public struct RulesCleanProgressEvent: Sendable, Codable, Equatable {
    public let jobId: String
    public let current: Int
    public let total: Int
    public let ruleId: String?
    public let partial: CleanRulesResult

    public init(jobId: String, current: Int, total: Int, ruleId: String?, partial: CleanRulesResult) {
        self.jobId = jobId
        self.current = current
        self.total = total
        self.ruleId = ruleId
        self.partial = partial
    }
}

public enum RulesCleanEventSink {
    public nonisolated(unsafe) static var onProgress: ((RulesCleanProgressEvent) -> Void)?
    public nonisolated(unsafe) static var onComplete: ((CleanRulesResult) -> Void)?
    public nonisolated(unsafe) static var onError: ((IPCJobFailure) -> Void)?
}

public final class RulesCleanCoordinator: @unchecked Sendable {
    public static let shared = RulesCleanCoordinator()

    private struct Job {
        var state: IPCJobState = .running
        var current: Int = 0
        var total: Int = 0
        var currentRuleId: String?
        var items: [CleanRulesResult.Item] = []
        var result: CleanRulesResult?
        var error: String?
    }

    private let lock = NSLock()
    private var jobs: [String: Job] = [:]
    private let workQueue = DispatchQueue(label: "cleanspace.rules.clean", qos: .userInitiated)
    private var lastProgressEmit: TimeInterval = 0
    private let progressEmitMinInterval: TimeInterval = 0.08

    public func start(ruleIds: [String]) throws -> ScanStartResult {
        let jobId = UUID().uuidString
        let total = ruleIds.count
        lock.lock()
        jobs[jobId] = Job(total: total)
        lastProgressEmit = 0
        lock.unlock()

        workQueue.async {
            self.runJob(jobId: jobId, ruleIds: ruleIds)
        }

        return ScanStartResult(jobId: jobId, total: total)
    }

    public func poll(jobId: String) throws -> RulesCleanJobStatus {
        lock.lock()
        guard let job = jobs[jobId] else {
            lock.unlock()
            throw IPCError.notFound("clean job not found: \(jobId)")
        }
        let status = Self.status(from: job)
        lock.unlock()
        return status
    }

    private func runJob(jobId: String, ruleIds: [String]) {
        var items: [CleanRulesResult.Item] = []
        for (index, ruleId) in ruleIds.enumerated() {
            lock.lock()
            if jobs[jobId] == nil {
                lock.unlock()
                return
            }
            jobs[jobId]?.current = index + 1
            jobs[jobId]?.currentRuleId = ruleId
            lock.unlock()

            let partial = CleanSpaceKitAPI.cleanRules(ruleIds: [ruleId])
            items.append(contentsOf: partial.items)

            let progress = CleanRulesResult(items: items)
            emitProgress(
                RulesCleanProgressEvent(
                    jobId: jobId,
                    current: index + 1,
                    total: ruleIds.count,
                    ruleId: ruleId,
                    partial: progress
                )
            )
        }

        let final = CleanRulesResult(items: items)
        lock.lock()
        jobs[jobId] = Job(
            state: .completed,
            current: ruleIds.count,
            total: ruleIds.count,
            result: final
        )
        lock.unlock()
        RulesCleanEventSink.onComplete?(final)
    }

    private func emitProgress(_ event: RulesCleanProgressEvent) {
        let now = ProcessInfo.processInfo.systemUptime
        let isFinal = event.current >= event.total
        if !isFinal && now - lastProgressEmit < progressEmitMinInterval {
            return
        }
        lastProgressEmit = now
        RulesCleanEventSink.onProgress?(event)
    }

    private static func status(from job: Job) -> RulesCleanJobStatus {
        RulesCleanJobStatus(
            state: job.state,
            current: job.current,
            total: job.total,
            currentRuleId: job.currentRuleId,
            result: job.result,
            error: job.error
        )
    }
}
