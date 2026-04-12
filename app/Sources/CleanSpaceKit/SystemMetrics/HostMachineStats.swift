//
//  HostMachineStats.swift
//  CleanSpaceKit
//
//  通过 Mach host 接口读取 CPU tick 与内存页统计（与活动监视器同量级数据源，非精确一致）。
//

import Darwin
import Foundation

enum HostMachineStats {
    /// 当前累计 CPU tick（user / system / idle / nice）。
    static func cpuLoadTicks() -> (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)? {
        var load = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &load) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return nil }
        return (
            UInt64(load.cpu_ticks.0),
            UInt64(load.cpu_ticks.1),
            UInt64(load.cpu_ticks.2),
            UInt64(load.cpu_ticks.3)
        )
    }

    /// 根据相邻两次 tick 差分估算 CPU 占用率 0...100（user+system 占全部增量比例）。
    static func cpuPercentSince(previous: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64), current: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)) -> Double {
        let du = current.user &- previous.user
        let ds = current.system &- previous.system
        let di = current.idle &- previous.idle
        let dn = current.nice &- previous.nice
        let active = du &+ ds
        let total = du &+ ds &+ di &+ dn
        guard total > 0 else { return 0 }
        return min(100, max(0, Double(active) * 100 / Double(total)))
    }

    /// 估算已用物理内存与占比（active + wired + compressor 页，与系统「内存压力」展示接近）。
    static func memoryUsage() -> (usedBytes: UInt64, totalBytes: UInt64, percent: Double) {
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else {
            return (0, totalBytes, 0)
        }
        var pageSize: vm_size_t = 0
        guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS, pageSize > 0 else {
            return (0, totalBytes, 0)
        }
        let page = UInt64(pageSize)
        let usedPages = UInt64(stats.active_count) &+ UInt64(stats.wire_count) &+ UInt64(stats.compressor_page_count)
        let used = min(totalBytes, usedPages &* page)
        let pct = totalBytes > 0 ? min(100, max(0, Double(used) * 100 / Double(totalBytes))) : 0
        return (used, totalBytes, pct)
    }
}
