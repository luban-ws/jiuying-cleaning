//
//  DockerRunLogCollector.swift
//  CleanSpaceKit
//

import Foundation

/// `dockerRunPreset` 回调日志收集（Swift 6 并发安全）。
final class DockerRunLogCollector: @unchecked Sendable {
    private let lock = NSLock()
    private(set) var log = ""
    private(set) var allOK = true

    func append(_ line: String) {
        lock.lock()
        defer { lock.unlock() }
        log += line
    }

    func markFailure() {
        lock.lock()
        defer { lock.unlock() }
        allOK = false
    }
}
