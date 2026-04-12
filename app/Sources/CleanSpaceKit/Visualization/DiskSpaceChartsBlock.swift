//
//  DiskSpaceChartsBlock.swift
//  CleanSpaceKit
//
//  磁盘页：环形概览、顶层分布图与空间明细表。
//

import Charts
import SwiftUI

struct DiskSpaceChartsBlock: View {
    let totalBytes: Int64?
    let freeBytes: Int64?
    let topFolders: [TopLevelFolderSize]
    let unaccountedBytes: Int64
    let onOpenPath: (String) -> Void

    private var overviewSlices: [SpaceChartSlice]? {
        SpaceChartSliceBuilder.volumeFreeUsedSlices(total: totalBytes, free: freeBytes)
    }

    private var breakdownSlices: [SpaceChartSlice] {
        SpaceChartSliceBuilder.topLevelBreakdownSlices(rows: topFolders, unaccountedBytes: unaccountedBytes)
    }

    private var breakdownTotal: Int64 {
        let sumFolders = topFolders.reduce(Int64(0)) { $0 + $1.bytes }
        return sumFolders + unaccountedBytes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let slices = overviewSlices, !slices.isEmpty {
                overviewSection(slices: slices)
            }

            if !topFolders.isEmpty {
                breakdownSection(slices: breakdownSlices)
                spaceTableSection
            }
        }
    }

    private func overviewSection(slices: [SpaceChartSlice]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("整卷空间")
                .font(.headline)
            HStack(alignment: .top, spacing: 24) {
                Chart(slices) { s in
                    SectorMark(
                        angle: .value("容量", s.bytes),
                        innerRadius: .ratio(0.58),
                        angularInset: 1.2
                    )
                    .foregroundStyle(s.color)
                    .cornerRadius(2)
                }
                .chartLegend(position: .trailing, alignment: .center)
                .frame(width: 200, height: 200)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(slices) { s in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(s.color)
                                .frame(width: 8, height: 8)
                            Text(s.label)
                                .font(.subheadline)
                            Spacer(minLength: 8)
                            Text(SpaceFormat.bytes(s.bytes))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: 280, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
    }

    private func breakdownSection(slices: [SpaceChartSlice]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("顶层与对账分布")
                .font(.headline)
            if slices.isEmpty {
                Text("暂无正值可绘制。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .top, spacing: 24) {
                    Chart(slices) { s in
                        SectorMark(
                            angle: .value("估算", s.bytes),
                            innerRadius: .ratio(0.52),
                            angularInset: 1.0
                        )
                        .foregroundStyle(s.color)
                        .cornerRadius(2)
                    }
                    .chartLegend(.hidden)
                    .frame(width: 200, height: 200)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(slices) { s in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Circle()
                                    .fill(s.color)
                                    .frame(width: 8, height: 8)
                                Text(s.label)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 4)
                                VStack(alignment: .trailing, spacing: 0) {
                                    Text(SpaceFormat.bytes(s.bytes))
                                        .font(.caption.monospacedDigit())
                                    if breakdownTotal > 0 {
                                        Text(SpaceFormat.percent(part: s.bytes, of: breakdownTotal))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 320, alignment: .leading)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var spaceTableSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("空间明细表")
                .font(.headline)
            Table(topFolders.sorted { $0.bytes > $1.bytes }) {
                TableColumn("文件夹") { row in
                    Text(row.name)
                        .font(.body)
                }
                .width(min: 120, ideal: 160)
                TableColumn("大小") { row in
                    Text(SpaceFormat.bytes(row.bytes))
                        .monospacedDigit()
                        .foregroundStyle(row.bytes > 0 ? .primary : .secondary)
                }
                .width(100)
                TableColumn("占扫描合计") { row in
                    let sum = topFolders.reduce(Int64(0)) { $0 + $1.bytes }
                    Text(SpaceFormat.percent(part: row.bytes, of: max(sum, 1)))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .width(88)
                TableColumn("") { row in
                    Button("访达") {
                        onOpenPath(row.path)
                    }
                    .buttonStyle(.borderless)
                }
                .width(52)
            }
            .frame(minHeight: min(CGFloat(120 + topFolders.count * 28), 320))
        }
    }
}
