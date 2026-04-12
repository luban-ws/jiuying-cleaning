//
//  SpaceChartSlices.swift
//  CleanSpaceKit
//
//  为磁盘/规则视图构建图表切片数据（纯函数 + 调色板）。
//

import SwiftUI

/// 单块扇区或图例项
struct SpaceChartSlice: Identifiable, Equatable {
    let id: String
    let label: String
    let bytes: Int64
    let color: Color
}

enum SpaceVisualizationPalette {
    /// 磁盘分布：区分度高、适合浅色/深色自适应的固定调色
    static let diskSpectrum: [Color] = [
        Color(red: 0.25, green: 0.52, blue: 0.96),
        Color(red: 0.20, green: 0.78, blue: 0.55),
        Color(red: 0.98, green: 0.62, blue: 0.28),
        Color(red: 0.72, green: 0.45, blue: 0.98),
        Color(red: 0.98, green: 0.36, blue: 0.48),
        Color(red: 0.42, green: 0.68, blue: 0.88),
        Color(red: 0.88, green: 0.76, blue: 0.32),
        Color(red: 0.55, green: 0.55, blue: 0.58),
    ]

    static func diskColor(at index: Int) -> Color {
        diskSpectrum[index % diskSpectrum.count]
    }
}

enum SpaceChartSliceBuilder {
    /// 整卷：可用 vs 已用（用于环形概览）
    static func volumeFreeUsedSlices(total: Int64?, free: Int64?) -> [SpaceChartSlice]? {
        guard let t = total, let f = free, t > 0 else { return nil }
        let used = max(0, t - f)
        let avail = max(0, f)
        if used == 0, avail == 0 { return nil }
        return [
            SpaceChartSlice(id: "used", label: "已用", bytes: used, color: SpaceVisualizationPalette.diskColor(at: 0)),
            SpaceChartSlice(id: "free", label: "可用", bytes: avail, color: SpaceVisualizationPalette.diskColor(at: 1)),
        ]
    }

    /// 顶层目录 + 可选「其他顶层」+「未由扫描计入」
    static func topLevelBreakdownSlices(
        rows: [TopLevelFolderSize],
        unaccountedBytes: Int64,
        maxTopNames: Int = 5
    ) -> [SpaceChartSlice] {
        let sorted = rows.sorted { $0.bytes > $1.bytes }
        var slices: [SpaceChartSlice] = []
        var idx = 0

        let head = Array(sorted.prefix(maxTopNames))
        let tail = Array(sorted.dropFirst(maxTopNames))
        let tailSum = tail.reduce(Int64(0)) { $0 + $1.bytes }

        for row in head where row.bytes > 0 {
            slices.append(
                SpaceChartSlice(id: row.path, label: row.name, bytes: row.bytes, color: SpaceVisualizationPalette.diskColor(at: idx))
            )
            idx += 1
        }

        if tailSum > 0 {
            slices.append(
                SpaceChartSlice(
                    id: "other-toplevel",
                    label: "其余顶层项（\(tail.count)）",
                    bytes: tailSum,
                    color: SpaceVisualizationPalette.diskColor(at: idx)
                )
            )
            idx += 1
        }

        if unaccountedBytes > 0 {
            slices.append(
                SpaceChartSlice(
                    id: "unaccounted",
                    label: "未由扫描计入",
                    bytes: unaccountedBytes,
                    color: Color.secondary.opacity(0.85)
                )
            )
        }

        return slices
    }

    /// 规则扫描：按分类汇总可计量体积（仅 type == .dir 且有扫描值）
    static func rulesCategorySlices(
        rules: [CleaningRule],
        scannedSizes: [String: Int64]
    ) -> [SpaceChartSlice] {
        var byCat: [String: Int64] = [:]
        for rule in rules where rule.type == .dir {
            guard let b = scannedSizes[rule.id], b > 0 else { continue }
            byCat[rule.category, default: 0] += b
        }
        let pairs = byCat.keys.sorted().map { key -> (String, String, Int64) in
            (key, CleaningRule.categoryDisplayName(key), byCat[key]!)
        }
        .sorted { $0.2 > $1.2 }

        return pairs.enumerated().map { i, t in
            SpaceChartSlice(
                id: t.0,
                label: t.1,
                bytes: t.2,
                color: SpaceVisualizationPalette.diskColor(at: i)
            )
        }
    }
}
