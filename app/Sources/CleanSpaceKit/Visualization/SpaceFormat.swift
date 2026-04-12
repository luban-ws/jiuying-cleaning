//
//  SpaceFormat.swift
//  CleanSpaceKit
//
//  字节与占比格式化（图表与表格共用）。
//

import Foundation

enum SpaceFormat {
    static let byteFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()

    static func bytes(_ value: Int64) -> String {
        byteFormatter.string(fromByteCount: value)
    }

    static func percent(part: Int64, of total: Int64) -> String {
        guard total > 0, part >= 0 else { return "—" }
        let p = 100.0 * Double(part) / Double(total)
        if p < 0.1, part > 0 { return "<0.1%" }
        return String(format: "%.1f%%", p)
    }
}
