//
//  MetricsMenuBarViews.swift
//  CleanSpaceKit
//
//  系统菜单栏：单一仪表盘图标 + 弹层内图表与文案（CPU/内存环形图、网络柱图）。
//

import SwiftUI

// MARK: - 阈值着色（弹层图表与菜单栏单图标聚合态共用）
enum MetricsMonitoringPalette {
    private static func stressLevel(value: Double, threshold: Double) -> Int {
        if value >= threshold { return 2 }
        if value >= threshold * 0.85 { return 1 }
        return 0
    }

    private static func networkStressLevel(peakBps: Double) -> Int {
        guard MetricsThresholds.notifyOnNetwork else { return 0 }
        if peakBps >= MetricsThresholds.networkBps { return 2 }
        if peakBps >= MetricsThresholds.networkBps * 0.85 { return 1 }
        return 0
    }

    /// 菜单栏仅一枚图标时：取 CPU / 内存 / 网络（若开启网络通知）中最严峻的着色。
    static func aggregateMenuBarTint(cpu: Double, memory: Double, peakNetBps: Double) -> Color {
        let m = max(
            stressLevel(value: cpu, threshold: MetricsThresholds.cpuPercent),
            stressLevel(value: memory, threshold: MetricsThresholds.memoryPercent),
            networkStressLevel(peakBps: peakNetBps)
        )
        if m >= 2 { return .orange }
        if m >= 1 { return .yellow }
        return .primary
    }

    static func cpuTint(_ value: Double) -> Color {
        switch stressLevel(value: value, threshold: MetricsThresholds.cpuPercent) {
        case 2: return .orange
        case 1: return .yellow
        default: return .primary
        }
    }

    static func memoryTint(_ value: Double) -> Color {
        switch stressLevel(value: value, threshold: MetricsThresholds.memoryPercent) {
        case 2: return .orange
        case 1: return .yellow
        default: return .primary
        }
    }
}

// MARK: - 下拉详情块（纯数据，便于预览与复用）
private enum MetricsMonitoringDetailBlocks {
    @ViewBuilder
    static func cpu(cpuPercent: Double) -> some View {
        Text(L10n.Metrics.menuCpuHeadline)
            .font(.headline)
        Text(L10n.Metrics.menuCpuCurrent(MetricsFormat.percent0(cpuPercent)))
        Text(L10n.Metrics.menuThresholdCpu(Int(MetricsThresholds.cpuPercent)))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    static func memory(usedBytes: UInt64, totalBytes: UInt64, memoryPercent: Double) -> some View {
        Text(L10n.Metrics.menuMemoryHeadline)
            .font(.headline)
        Text(L10n.Metrics.menuMemoryCurrent(
            used: formatBytes(usedBytes),
            total: formatBytes(totalBytes),
            pct: MetricsFormat.percent0(memoryPercent)
        ))
        Text(L10n.Metrics.menuThresholdMemory(Int(MetricsThresholds.memoryPercent)))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    static func network(upBps: Double, downBps: Double) -> some View {
        Text(L10n.Metrics.menuNetworkHeadline)
            .font(.headline)
        Text(L10n.Metrics.menuNetworkUp(MetricsFormat.bytesPerSecond(upBps)))
        Text(L10n.Metrics.menuNetworkDown(MetricsFormat.bytesPerSecond(downBps)))
        if MetricsThresholds.notifyOnNetwork {
            Text(L10n.Metrics.menuThresholdNetwork(MetricsFormat.bytesPerSecond(MetricsThresholds.networkBps)))
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text(L10n.Metrics.menuNetworkNotifyOff)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private static func formatBytes(_ n: UInt64) -> String {
        let capped = n > UInt64(Int64.max) ? Int64.max : Int64(n)
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: capped)
    }
}

// MARK: - 菜单栏上显示的紧凑一行（实时刷新）
public struct MetricsMenuBarCompactLabel: View {
    @ObservedObject private var metrics = SystemMetricsController.shared

    public init() {}

    public var body: some View {
        let peakNet = max(metrics.networkDownBps, metrics.networkUpBps)
        let netShort = L10n.Metrics.menuNetworkShort(
            up: MetricsFormat.bytesPerSecond(metrics.networkUpBps),
            down: MetricsFormat.bytesPerSecond(metrics.networkDownBps)
        )
        // 单图标：仪表盘符号 + 聚合着色；详情与图表在弹层内。
        Image(systemName: MetricsMenuBarMonitorSymbol.systemName)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(MetricsMonitoringPalette.aggregateMenuBarTint(
                cpu: metrics.cpuPercent,
                memory: metrics.memoryPercent,
                peakNetBps: peakNet
            ))
            .imageScale(.small)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.Metrics.menuBarAccessibilityLabel)
        .accessibilityValue(
            L10n.Metrics.menuBarAccessibilityValue(
                cpu: MetricsFormat.percent0(metrics.cpuPercent),
                memory: MetricsFormat.percent0(metrics.memoryPercent),
                network: netShort
            )
        )
        .help(
            L10n.Metrics.menuBarHelpLive(
                cpu: MetricsFormat.percent0(metrics.cpuPercent),
                memory: MetricsFormat.percent0(metrics.memoryPercent),
                network: netShort
            )
        )
        // 采样与主窗口解耦：仅使用菜单栏时也要 `start()`（`start()` 内可重复调用）。
        .onAppear {
            SystemMetricsController.shared.start()
        }
    }
}

// MARK: - 点击菜单栏图标后的详情面板
public struct MetricsMenuBarDetailsList: View {
    @ObservedObject private var metrics = SystemMetricsController.shared

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                MetricsPopoverPercentDonut(
                    percent: metrics.cpuPercent,
                    accent: MetricsMonitoringPalette.cpuTint(metrics.cpuPercent)
                )
                VStack(alignment: .leading, spacing: 4) {
                    MetricsMonitoringDetailBlocks.cpu(cpuPercent: metrics.cpuPercent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            HStack(alignment: .top, spacing: 14) {
                MetricsPopoverPercentDonut(
                    percent: metrics.memoryPercent,
                    accent: MetricsMonitoringPalette.memoryTint(metrics.memoryPercent)
                )
                VStack(alignment: .leading, spacing: 4) {
                    MetricsMonitoringDetailBlocks.memory(
                        usedBytes: metrics.memoryUsedBytes,
                        totalBytes: metrics.memoryTotalBytes,
                        memoryPercent: metrics.memoryPercent
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            HStack(alignment: .top, spacing: 14) {
                MetricsPopoverNetworkBarChart(upBps: metrics.networkUpBps, downBps: metrics.networkDownBps)
                VStack(alignment: .leading, spacing: 4) {
                    MetricsMonitoringDetailBlocks.network(upBps: metrics.networkUpBps, downBps: metrics.networkDownBps)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 320, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }
}

/// 菜单栏系统监控使用的单一 SF Symbol 名称（避免在代码中散落字符串）。
public enum MetricsMenuBarMonitorSymbol {
    public static let systemName = "gauge.with.needle.fill"
}
