//
//  SystemMetricsController.swift
//  CleanSpaceKit
//
//  定时采样 CPU / 内存 / 网络速率，供工具栏与阈值通知使用。
//

import Foundation
import SwiftUI

@MainActor
public final class SystemMetricsController: ObservableObject {
    /// 全局唯一采样器：避免多窗口或多处 `@StateObject` 重复定时器与通知。
    public static let shared = SystemMetricsController()

    @Published public private(set) var cpuPercent: Double = 0
    @Published public private(set) var memoryPercent: Double = 0
    @Published public private(set) var memoryUsedBytes: UInt64 = 0
    @Published public private(set) var memoryTotalBytes: UInt64 = 0
    @Published public private(set) var networkUpBps: Double = 0
    @Published public private(set) var networkDownBps: Double = 0

    private var cpuPrevious: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)?
    private var netPrevious: (in: UInt64, out: UInt64, time: Date)?
    private var timer: Timer?

    private init() {}

    public func start() {
        MetricsThresholdNotifier.shared.requestPermissionIfNeeded()
        timer?.invalidate()
        cpuPrevious = HostMachineStats.cpuLoadTicks()
        let n = Date()
        let net = NetworkInterfaceCounters.totalBytesInOut()
        netPrevious = (net.in, net.out, n)
        let t = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        if let cur = HostMachineStats.cpuLoadTicks(), let prev = cpuPrevious {
            cpuPercent = HostMachineStats.cpuPercentSince(previous: prev, current: cur)
            cpuPrevious = cur
        } else if let cur = HostMachineStats.cpuLoadTicks() {
            cpuPrevious = cur
        }

        let mem = HostMachineStats.memoryUsage()
        memoryUsedBytes = mem.usedBytes
        memoryTotalBytes = mem.totalBytes
        memoryPercent = mem.percent

        let t = Date()
        let curNet = NetworkInterfaceCounters.totalBytesInOut()
        if let prev = netPrevious {
            let dt = t.timeIntervalSince(prev.time)
            if dt > 0.2 {
                let din = Double(curNet.in &- prev.in) / dt
                let dout = Double(curNet.out &- prev.out) / dt
                networkDownBps = max(0, din)
                networkUpBps = max(0, dout)
            }
        }
        netPrevious = (curNet.in, curNet.out, t)

        MetricsThresholdNotifier.shared.evaluate(
            cpu: cpuPercent,
            memoryPercent: memoryPercent,
            networkDownBps: networkDownBps,
            networkUpBps: networkUpBps
        )
    }
}
