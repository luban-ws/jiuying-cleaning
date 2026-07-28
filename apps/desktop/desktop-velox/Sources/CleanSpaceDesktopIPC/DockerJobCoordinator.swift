//
//  DockerJobCoordinator.swift
//  CleanSpaceDesktopIPC
//

import CleanSpaceKit
import Foundation

public struct DockerRefreshResult: Sendable, Codable, Equatable {
    public let df: DockerDiskUsageParsed
    public let desktop: [DockerDesktopSizeRow]

    public init(df: DockerDiskUsageParsed, desktop: [DockerDesktopSizeRow]) {
        self.df = df
        self.desktop = desktop
    }
}

public struct DockerRefreshJobStatus: Sendable, Codable, Equatable {
    public let state: IPCJobState
    public let result: DockerRefreshResult?
    public let error: String?

    public init(state: IPCJobState, result: DockerRefreshResult? = nil, error: String? = nil) {
        self.state = state
        self.result = result
        self.error = error
    }
}

public struct DockerPresetJobStatus: Sendable, Codable, Equatable {
    public let state: IPCJobState
    public let result: DockerPresetRunResult?
    public let error: String?

    public init(state: IPCJobState, result: DockerPresetRunResult? = nil, error: String? = nil) {
        self.state = state
        self.result = result
        self.error = error
    }
}

public enum DockerJobEventSink {
    public nonisolated(unsafe) static var onRefreshComplete: ((DockerRefreshResult) -> Void)?
    public nonisolated(unsafe) static var onPresetComplete: ((DockerPresetRunResult) -> Void)?
    public nonisolated(unsafe) static var onError: ((IPCJobFailure) -> Void)?
}

public final class DockerJobCoordinator: @unchecked Sendable {
    public static let shared = DockerJobCoordinator()

    private enum Kind {
        case refresh
        case preset(String)
    }

    private struct Job {
        var kind: Kind
        var state: IPCJobState = .running
        var refreshResult: DockerRefreshResult?
        var presetResult: DockerPresetRunResult?
        var error: String?
    }

    private let lock = NSLock()
    private var jobs: [String: Job] = [:]
    private let workQueue = DispatchQueue(label: "cleanspace.docker.job", qos: .userInitiated)

    public func startRefresh() throws -> IPCJobHandle {
        let jobId = UUID().uuidString
        lock.lock()
        jobs[jobId] = Job(kind: .refresh)
        lock.unlock()

        workQueue.async {
            let df = CleanSpaceKitAPI.dockerDiskUsageParsed()
            let desktop = CleanSpaceKitAPI.dockerDesktopSizes()
            let result = DockerRefreshResult(df: df, desktop: desktop)
            self.lock.lock()
            self.jobs[jobId] = Job(kind: .refresh, state: .completed, refreshResult: result)
            self.lock.unlock()
            DockerJobEventSink.onRefreshComplete?(result)
        }

        return IPCJobHandle(jobId: jobId)
    }

    public func startPreset(presetId: String) throws -> IPCJobHandle {
        let jobId = UUID().uuidString
        lock.lock()
        jobs[jobId] = Job(kind: .preset(presetId))
        lock.unlock()

        workQueue.async {
            let result = CleanSpaceKitAPI.dockerRunPreset(presetId: presetId)
            self.lock.lock()
            self.jobs[jobId] = Job(kind: .preset(presetId), state: .completed, presetResult: result)
            self.lock.unlock()
            DockerJobEventSink.onPresetComplete?(result)
        }

        return IPCJobHandle(jobId: jobId)
    }

    public func pollRefresh(jobId: String) throws -> DockerRefreshJobStatus {
        lock.lock()
        guard let job = jobs[jobId], case .refresh = job.kind else {
            lock.unlock()
            throw IPCError.notFound("docker refresh job not found: \(jobId)")
        }
        let status = DockerRefreshJobStatus(state: job.state, result: job.refreshResult, error: job.error)
        lock.unlock()
        return status
    }

    public func pollPreset(jobId: String) throws -> DockerPresetJobStatus {
        lock.lock()
        guard let job = jobs[jobId], case .preset = job.kind else {
            lock.unlock()
            throw IPCError.notFound("docker preset job not found: \(jobId)")
        }
        let status = DockerPresetJobStatus(state: job.state, result: job.presetResult, error: job.error)
        lock.unlock()
        return status
    }
}
