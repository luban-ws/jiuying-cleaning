//
//  BootVolumeSpaceReader.swift
//  CleanSpaceKit
//
//  轻量读取根卷容量（URL 资源值），供菜单栏「磁盘」页展示，不触发完整目录扫描。
//

import Foundation

enum BootVolumeSpaceReader {
    /// 根卷已用字节、总字节、占用百分比 0…100（基于 `volumeAvailableCapacityForImportantUsage`）。
    static func snapshot(rootURL: URL = URL(fileURLWithPath: "/")) -> (used: Int64, total: Int64, percent: Double)? {
        guard let vals = try? rootURL.resourceValues(forKeys: [
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeTotalCapacityKey,
        ]),
            let total = vals.volumeTotalCapacity, total > 0,
            let avail = vals.volumeAvailableCapacityForImportantUsage
        else {
            return nil
        }
        let used = Int64(total) - Int64(avail)
        guard used >= 0 else { return nil }
        let pct = Double(used) * 100 / Double(total)
        return (used, Int64(total), min(100, max(0, pct)))
    }
}
