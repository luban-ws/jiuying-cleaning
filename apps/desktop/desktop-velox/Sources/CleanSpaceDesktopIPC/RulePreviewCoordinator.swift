//
//  RulePreviewCoordinator.swift
//  CleanSpaceDesktopIPC
//

import CleanSpaceKit
import Foundation

public struct RulePreviewJobStatus: Sendable, Codable, Equatable {
    public let state: IPCJobState
    public let result: RulePreviewResult?
    public let error: String?

    public init(state: IPCJobState, result: RulePreviewResult? = nil, error: String? = nil) {
        self.state = state
        self.result = result
        self.error = error
    }
}

public enum RulePreviewEventSink {
    public nonisolated(unsafe) static var onComplete: ((RulePreviewResult) -> Void)?
    public nonisolated(unsafe) static var onError: ((IPCJobFailure) -> Void)?
}

public final class RulePreviewCoordinator: @unchecked Sendable {
    public static let shared = RulePreviewCoordinator()

    private struct Job {
        var state: IPCJobState = .running
        var result: RulePreviewResult?
        var error: String?
    }

    private let lock = NSLock()
    private var jobs: [String: Job] = [:]
    private let workQueue = DispatchQueue(label: "cleanspace.rule.preview", qos: .userInitiated)

    public func start(ruleId: String) throws -> IPCJobHandle {
        let jobId = UUID().uuidString
        lock.lock()
        jobs[jobId] = Job()
        lock.unlock()

        workQueue.async {
            guard let preview = CleanSpaceKitAPI.previewRule(ruleId: ruleId) else {
                self.fail(jobId: jobId, message: "rule not found")
                return
            }
            self.lock.lock()
            self.jobs[jobId] = Job(state: .completed, result: preview)
            self.lock.unlock()
            RulePreviewEventSink.onComplete?(preview)
        }

        return IPCJobHandle(jobId: jobId)
    }

    public func poll(jobId: String) throws -> RulePreviewJobStatus {
        lock.lock()
        guard let job = jobs[jobId] else {
            lock.unlock()
            throw IPCError.notFound("preview job not found: \(jobId)")
        }
        let status = RulePreviewJobStatus(state: job.state, result: job.result, error: job.error)
        lock.unlock()
        return status
    }

    private func fail(jobId: String, message: String) {
        lock.lock()
        jobs[jobId] = Job(state: .failed, error: message)
        lock.unlock()
        RulePreviewEventSink.onError?(IPCJobFailure(jobId: jobId, message: message))
    }
}
