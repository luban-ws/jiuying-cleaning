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

    /// 接口累计字节单调递增；若变小则视为重置，本 interval 按 0 计，避免 UInt 下溢产生天文速率。
    private nonisolated static func deltaBytesPerSecond(current: UInt64, previous: UInt64, seconds: Double) -> Double {
        guard seconds > 0, current >= previous else { return 0 }
        return Double(current - previous) / seconds
    }

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
                // 不用 `&-`：计数器重置或回绕时无符号差会爆到近 UInt64.max，再转成 Int64 会触发运行时 trap。
                let din = Self.deltaBytesPerSecond(current: curNet.in, previous: prev.in, seconds: dt)
                let dout = Self.deltaBytesPerSecond(current: curNet.out, previous: prev.out, seconds: dt)
                networkDownBps = din
                networkUpBps = dout
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
