//
//  RulesScanChartBlock.swift
//  CleanSpaceKit
//
//  规则清理：按分类汇总扫描体积的条形图 + 迷你环形。
//

import Charts
import SwiftUI

struct RulesScanChartBlock: View {
    let rules: [CleaningRule]
    let scannedSizes: [String: Int64]

    private var slices: [SpaceChartSlice] {
        SpaceChartSliceBuilder.rulesCategorySlices(rules: rules, scannedSizes: scannedSizes)
    }

    private var totalScanned: Int64 {
        slices.reduce(0) { $0 + $1.bytes }
    }

    var body: some View {
        Group {
            if slices.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 28) {
                        Chart(slices) { s in
                            BarMark(
                                x: .value(L10n.Chart.axisBytes, s.bytes),
                                y: .value(L10n.Chart.axisCategory, s.label)
                            )
                            .foregroundStyle(s.color)
                            .cornerRadius(4)
                        }
                        .chartXAxis {
                            AxisMarks(position: .bottom)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { _ in
                                AxisValueLabel()
                            }
                        }
                        .frame(height: CGFloat(max(140, slices.count * 36)))
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if totalScanned > 0 {
                            Chart(slices) { s in
                                SectorMark(
                                    angle: .value(L10n.Chart.axisShare, s.bytes),
                                    innerRadius: .ratio(0.62),
                                    angularInset: 1
                                )
                                .foregroundStyle(s.color)
                                .cornerRadius(2)
                            }
                            .chartLegend(.hidden)
                            .frame(width: 140, height: 140)
                        }
                    }

                    Table(slices) {
                        TableColumn(L10n.Chart.tableCategory) { (row: SpaceChartSlice) in
                            Text(row.label)
                        }
                        TableColumn(L10n.Chart.tableSum) { (row: SpaceChartSlice) in
                            Text(SpaceFormat.bytes(row.bytes))
                                .monospacedDigit()
                        }
                        TableColumn(L10n.Chart.tablePercent) { (row: SpaceChartSlice) in
                            Text(SpaceFormat.percent(part: row.bytes, of: totalScanned))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(minHeight: CGFloat(80 + slices.count * 26))
                }
                .padding(.vertical, 6)
            }
        }
    }
}
