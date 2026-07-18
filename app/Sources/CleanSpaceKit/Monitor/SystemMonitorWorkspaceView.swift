//
//  SystemMonitorWorkspaceView.swift
//  CleanSpaceKit
//
//  主窗口内的 CPU / 内存 / 网络实时监控（与菜单栏共用采样器）。
//

import SwiftUI

struct SystemMonitorWorkspaceView: View {
    @ObservedObject private var metrics = SystemMetricsController.shared

    /// 窄窗 1 列 → 中等 2 列 → 宽屏 3 列，避免固定三列挤压环形图。
    private var monitorGridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 240, maximum: 420), spacing: 16),
        ]
    }

    var body: some View {
        SelectableWorkspaceScaffold {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CSWorkspaceGuideBanner(
                        text: L10n.Monitor.intro,
                        systemImage: "waveform.path.ecg"
                    )
                    .padding(.horizontal, CS.detailHorizontalPadding)
                    .padding(.top, 16)

                    LazyVGrid(
                        columns: monitorGridColumns,
                        spacing: 16
                    ) {
                        monitorCard(
                            title: L10n.Metrics.menuCpuHeadline,
                            symbol: "cpu",
                            tint: MetricsMonitoringPalette.cpuTint(metrics.cpuPercent)
                        ) {
                            MetricsPopoverDonutWithCenterLabel(
                                percent: metrics.cpuPercent,
                                accent: MetricsMonitoringPalette.cpuTint(metrics.cpuPercent)
                            )
                            Text(L10n.Metrics.menuCpuCurrent(MetricsFormat.percent0(metrics.cpuPercent)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        monitorCard(
                            title: L10n.Metrics.menuMemoryHeadline,
                            symbol: "memorychip",
                            tint: MetricsMonitoringPalette.memoryTint(metrics.memoryPercent)
                        ) {
                            MetricsPopoverDonutWithCenterLabel(
                                percent: metrics.memoryPercent,
                                accent: MetricsMonitoringPalette.memoryTint(metrics.memoryPercent)
                            )
                            Text(
                                L10n.Metrics.menuMemoryCurrent(
                                    used: formatBytes(metrics.memoryUsedBytes),
                                    total: formatBytes(metrics.memoryTotalBytes),
                                    pct: MetricsFormat.percent0(metrics.memoryPercent)
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        }

                        monitorCard(
                            title: L10n.Metrics.menuNetworkHeadline,
                            symbol: "network",
                            tint: .accentColor
                        ) {
                            MetricsPopoverNetworkBarChart(
                                upBps: metrics.networkUpBps,
                                downBps: metrics.networkDownBps
                            )
                            Text(
                                L10n.Metrics.menuNetworkShort(
                                    up: MetricsFormat.bytesPerSecond(metrics.networkUpBps),
                                    down: MetricsFormat.bytesPerSecond(metrics.networkDownBps)
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        }
                    }
                    .padding(.horizontal, CS.detailHorizontalPadding)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(L10n.Monitor.navTitle)
        .optionalNavigationSubtitle(L10n.Monitor.navSubtitle)
        .onAppear {
            SystemMetricsController.shared.start()
        }
    }

    @ViewBuilder
    private func monitorCard<Content: View>(
        title: String,
        symbol: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(tint)
            VStack(spacing: 10) {
                content()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: CS.cornerHero, style: .continuous)
                .fill(Material.regular)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CS.cornerHero, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        }
    }

    private func formatBytes(_ n: UInt64) -> String {
        let capped = n > UInt64(Int64.max) ? Int64.max : Int64(n)
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: capped)
    }
}
