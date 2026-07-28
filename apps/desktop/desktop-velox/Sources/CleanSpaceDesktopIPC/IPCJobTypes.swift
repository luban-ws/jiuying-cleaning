//
//  IPCJobTypes.swift
//  CleanSpaceDesktopIPC
//

import Foundation

public struct IPCJobHandle: Sendable, Codable, Equatable {
    public let jobId: String

    public init(jobId: String) {
        self.jobId = jobId
    }
}

public enum IPCJobState: String, Sendable, Codable, Equatable {
    case running
    case completed
    case failed
}

public struct IPCJobFailure: Sendable, Codable, Equatable {
    public let jobId: String
    public let message: String

    public init(jobId: String, message: String) {
        self.jobId = jobId
        self.message = message
    }
}
