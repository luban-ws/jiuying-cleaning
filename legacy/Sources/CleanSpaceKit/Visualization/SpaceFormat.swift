//
//  SpaceFormat.swift
//  CleanSpaceKit
//
//  字节与占比格式化（图表与表格共用）。
//

import Foundation

enum SpaceFormat {
    /// 每次调用新建 formatter，避免 Swift 6 下共享 `ByteCountFormatter` 的全局可变状态诊断；体量上图表/表格调用次数可接受。
    static func bytes(_ value: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: value)
    }

    static func percent(part: Int64, of total: Int64) -> String {
        guard total > 0, part >= 0 else { return "—" }
        let p = 100.0 * Double(part) / Double(total)
        if p < 0.1, part > 0 { return "<0.1%" }
        return String(format: "%.1f%%", p)
    }
}
