//
//  MetricsMenuBarCharts.swift
//  CleanSpaceKit
//
//  菜单栏弹层内的 Charts：CPU / 内存环形占比、网络上下行对比柱图（与磁盘页 SectorMark 风格一致）。
//

import Charts
import SwiftUI

// MARK: - 环形占比（0–100%）
struct MetricsPopoverPercentDonut: View {
    let percent: Double
    let accent: Color

    private var clamped: Double { min(max(percent, 0), 100) }
    private var free: Double { 100 - clamped }

    var body: some View {
        Chart {
            SectorMark(
                angle: .value(MetricsChartSeries.usedId, clamped),
                innerRadius: .ratio(0.58),
                angularInset: 1.2
            )
            .foregroundStyle(accent)
            .cornerRadius(2)
            SectorMark(
                angle: .value(MetricsChartSeries.freeId, free),
                innerRadius: .ratio(0.58),
                angularInset: 1.2
            )
            .foregroundStyle(Color.primary.opacity(0.12))
            .cornerRadius(2)
        }
        .chartLegend(.hidden)
        .chartPlotStyle { plot in
            plot.frame(width: MetricsChartLayout.donutSize, height: MetricsChartLayout.donutSize)
        }
        .frame(width: MetricsChartLayout.donutSize, height: MetricsChartLayout.donutSize)
    }
}

// MARK: - 网络上下行对比
struct MetricsPopoverNetworkBarChart: View {
    let upBps: Double
    let downBps: Double

    private var ceiling: Double {
        let m = max(upBps, downBps, 1)
        return m * 1.12
    }

    var body: some View {
        Chart {
            BarMark(
                x: .value("dir", L10n.Metrics.chartNetworkAxisUpload),
                y: .value(MetricsChartSeries.throughputId, upBps)
            )
            .foregroundStyle(Color.accentColor.opacity(0.9))
            .cornerRadius(4)
            BarMark(
                x: .value("dir", L10n.Metrics.chartNetworkAxisDownload),
                y: .value(MetricsChartSeries.throughputId, downBps)
            )
            .foregroundStyle(Color.accentColor.opacity(0.45))
            .cornerRadius(4)
        }
        .chartYScale(domain: 0...ceiling)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .frame(width: MetricsChartLayout.networkChartWidth, height: MetricsChartLayout.networkChartHeight)
    }
}

// MARK: - 布局与 Chart 内部 series 标识（非用户可见文案）
private enum MetricsChartLayout {
    static let donutSize: CGFloat = 80
    static let networkChartWidth: CGFloat = 112
    static let networkChartHeight: CGFloat = 88
}

private enum MetricsChartSeries {
    static let usedId = "used"
    static let freeId = "free"
    static let throughputId = "bps"
}
