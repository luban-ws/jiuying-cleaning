//
//  DockerDesktopChartBlock.swift
//  CleanSpaceKit
//
//  Docker Desktop 各目录占用：水平条形图 + 简要表。
//

import Charts
import SwiftUI

private struct DockerChartRow: Identifiable {
    let id: Int
    let label: String
    let bytes: Int64
}

struct DockerDesktopChartBlock: View {
    /// (显示名, 副标题/路径提示, 字节)
    let rows: [(String, String, Int64)]

    private var chartRows: [DockerChartRow] {
        rows.enumerated().compactMap { i, r in
            guard r.2 > 0 else { return nil }
            return DockerChartRow(id: i, label: r.0, bytes: r.2)
        }
    }

    private var total: Int64 {
        chartRows.reduce(0) { $0 + $1.bytes }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if chartRows.isEmpty {
                EmptyView()
            } else {
                Chart(chartRows) { row in
                    BarMark(
                        x: .value(L10n.Chart.axisBytes, row.bytes),
                        y: .value(L10n.Chart.axisDirectory, row.label)
                    )
                    .foregroundStyle(SpaceVisualizationPalette.diskColor(at: row.id))
                    .cornerRadius(3)
                }
                .chartXAxis { AxisMarks(position: .bottom) }
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: CGFloat(max(100, chartRows.count * 32)))

                Table(chartRows) {
                    TableColumn(L10n.Chart.axisDirectory) { (row: DockerChartRow) in
                        Text(row.label)
                    }
                    TableColumn(L10n.Disk.tableSize) { (row: DockerChartRow) in
                        Text(SpaceFormat.bytes(row.bytes))
                            .monospacedDigit()
                    }
                    TableColumn(L10n.Chart.tablePercent) { (row: DockerChartRow) in
                        Text(SpaceFormat.percent(part: row.bytes, of: max(total, 1)))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minHeight: CGFloat(60 + chartRows.count * 24))
            }
        }
    }
}
