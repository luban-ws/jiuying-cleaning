//
//  VolumeScanCoordinator.swift
//  CleanSpaceDesktopIPC
//

import CleanSpaceKit
import Foundation

public struct VolumeScanJobStatus: Sendable, Codable, Equatable {
    public let state: IPCJobState
    public let result: VolumeScanResult?
    public let error: String?

    public init(state: IPCJobState, result: VolumeScanResult? = nil, error: String? = nil) {
        self.state = state
        self.result = result
        self.error = error
    }
}

public enum VolumeScanEventSink {
    public nonisolated(unsafe) static var onComplete: ((VolumeScanResult) -> Void)?
    public nonisolated(unsafe) static var onError: ((IPCJobFailure) -> Void)?
}

public final class VolumeScanCoordinator: @unchecked Sendable {
    public static let shared = VolumeScanCoordinator()

    private struct Job {
        var state: IPCJobState = .running
        var result: VolumeScanResult?
        var error: String?
    }

    private let lock = NSLock()
    private var jobs: [String: Job] = [:]
    private let workQueue = DispatchQueue(label: "cleanspace.volume.scan", qos: .userInitiated)

    public func start(volumePath: String, totalBytes: Int64?, freeBytes: Int64?) throws -> IPCJobHandle {
        let jobId = UUID().uuidString
        lock.lock()
        jobs[jobId] = Job()
        lock.unlock()

        workQueue.async {
            let result = CleanSpaceKitAPI.scanVolume(
                volumePath: volumePath,
                totalBytes: totalBytes,
                freeBytes: freeBytes
            )
            self.lock.lock()
            self.jobs[jobId] = Job(state: .completed, result: result)
            self.lock.unlock()
            VolumeScanEventSink.onComplete?(result)
        }

        return IPCJobHandle(jobId: jobId)
    }

    public func poll(jobId: String) throws -> VolumeScanJobStatus {
        lock.lock()
        guard let job = jobs[jobId] else {
            lock.unlock()
            throw IPCError.notFound("volume scan job not found: \(jobId)")
        }
        let status = VolumeScanJobStatus(state: job.state, result: job.result, error: job.error)
        lock.unlock()
        return status
    }
}
