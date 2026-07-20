//
//  MetricsMenuBarCharts.swift
//  CleanSpaceKit
//
//  菜单栏弹层内的 Charts：CPU / 内存环形占比、网络上下行对比柱图（与磁盘页 SectorMark 风格一致）。
//

import Charts
import SwiftUI

// MARK: - 环形占比 + 中心百分比（菜单栏弹层）
struct MetricsPopoverDonutWithCenterLabel: View {
    let percent: Double
    let accent: Color
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            MetricsPopoverPercentDonut(percent: percent, accent: accent, size: size)
            Text(MetricsFormat.percent0(percent))
                .font(.system(size: size <= 40 ? 9 : 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.85)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 环形占比（0–100%）
struct MetricsPopoverPercentDonut: View {
    let percent: Double
    let accent: Color
    var size: CGFloat = 80

    private var clamped: Double { min(max(percent, 0), 100) }
    private var lineWidth: CGFloat { size * 0.21 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.primary.opacity(0.12),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                )
            Circle()
                .trim(from: 0.0, to: CGFloat(clamped / 100.0))
                .stroke(
                    accent,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))
        }
        .padding(lineWidth / 2)
        .frame(width: size, height: size)
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
