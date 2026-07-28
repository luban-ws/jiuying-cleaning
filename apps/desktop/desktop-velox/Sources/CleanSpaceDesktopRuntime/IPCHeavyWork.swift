//
//  IPCHeavyWork.swift
//  CleanSpaceDesktopRuntime
//
//  主线程 IPC：仅 instant 命令在后台队列执行并泵送 RunLoop；禁止长任务 sync。
//

import CleanSpaceDesktopIPC
import Foundation

enum IPCHeavyWork {
    static func run<T>(_ work: @escaping () throws -> T) throws -> T {
        if !Thread.isMainThread {
            return try work()
        }
        let box = WorkBox(work: work)
        DispatchQueue.global(qos: .userInitiated).async {
            box.finish()
        }
        return try box.waitPumpingRunLoop()
    }

    private final class WorkBox<T>: @unchecked Sendable {
        private let lock = NSLock()
        private var finished = false
        private var result: T?
        private var thrown: Error?
        private let work: () throws -> T

        init(work: @escaping () throws -> T) {
            self.work = work
        }

        func finish() {
            do {
                let value = try work()
                lock.lock()
                result = value
                finished = true
                lock.unlock()
            } catch {
                lock.lock()
                thrown = error
                finished = true
                lock.unlock()
            }
        }

        func waitPumpingRunLoop() throws -> T {
            while true {
                lock.lock()
                let done = finished
                let value = result
                let error = thrown
                lock.unlock()

                if done {
                    if let error {
                        throw error
                    }
                    return value!
                }

                RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
            }
        }
    }
}
