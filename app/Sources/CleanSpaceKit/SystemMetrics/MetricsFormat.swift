//
//  MetricsFormat.swift
//  CleanSpaceKit
//
//  工具栏与菜单中的速率 / 内存展示格式。
//

import Foundation

enum MetricsFormat {
    /// 字节速率（如 `12.5 MB/s`）。
    static func bytesPerSecond(_ bps: Double) -> String {
        let n = max(0, Int64(bps.rounded()))
        let f = ByteCountFormatter()
        f.countStyle = .file
        return "\(f.string(fromByteCount: n))/s"
    }

    static func percent0(_ v: Double) -> String {
        String(format: "%.0f%%", min(100, max(0, v)))
    }
}
