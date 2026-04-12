//
//  MetricsFormat.swift
//  CleanSpaceKit
//
//  工具栏与菜单中的速率 / 内存展示格式。
//

import Foundation

enum MetricsFormat {
    /// 远低于 `Int64.max` 的上限（避免 Double 舍入后 `Int64(...)` 越界 trap；正常网卡速率远小于此值）。
    private static let maxBpsSafeForInt64: Double = 8e18

    /// 字节速率（如 `12.5 MB/s`）。`bps` 异常大或非有限时钳制，避免 `Int64(...)` 越界崩溃。
    static func bytesPerSecond(_ bps: Double) -> String {
        guard bps.isFinite, !bps.isNaN else {
            return fallbackZeroPerSecond()
        }
        let clamped = min(max(0, bps), maxBpsSafeForInt64)
        let n = Int64(clamped.rounded())
        let f = ByteCountFormatter()
        f.countStyle = .file
        return "\(f.string(fromByteCount: n))/s"
    }

    private static func fallbackZeroPerSecond() -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return "\(f.string(fromByteCount: 0))/s"
    }

    static func percent0(_ v: Double) -> String {
        String(format: "%.0f%%", min(100, max(0, v)))
    }
}
