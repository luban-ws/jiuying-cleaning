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
                    Text("按分类占用（扫描结果）")
                        .font(.headline)

                    HStack(alignment: .top, spacing: 28) {
                        Chart(slices) { s in
                            BarMark(
                                x: .value("字节", s.bytes),
                                y: .value("分类", s.label)
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

                        if totalScanned > 0 {
                            Chart(slices) { s in
                                SectorMark(
                                    angle: .value("占比", s.bytes),
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
                        TableColumn("分类") { (row: SpaceChartSlice) in
                            Text(row.label)
                        }
                        TableColumn("合计") { (row: SpaceChartSlice) in
                            Text(SpaceFormat.bytes(row.bytes))
                                .monospacedDigit()
                        }
                        TableColumn("占比") { (row: SpaceChartSlice) in
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
