//
//  MenuBarPopoverTabs.swift
//  CleanSpaceKit
//
//  菜单栏弹层内「磁盘」「工作台」等与监控并列的 Tab 内容。
//

import SwiftUI

// MARK: - 磁盘占用环图着色（与主窗口磁盘阈值观感一致：80% 黄、90% 橙）
private enum MenuBarDiskChartPalette {
    static func accent(forPercent percent: Double) -> Color {
        if percent >= 90 { return .orange }
        if percent >= 80 { return .yellow }
        return .primary
    }
}

/// 根卷已用 / 总容量与环形占比（轻量 URL 读取，不扫描目录）。
struct MenuBarDiskTabContent: View {
    @State private var snapshot: (used: Int64, total: Int64, percent: Double)?

    var body: some View {
        Group {
            if let snap = snapshot {
                HStack(alignment: .top, spacing: 12) {
                    MetricsPopoverDonutWithCenterLabel(
                        percent: snap.percent,
                        accent: MenuBarDiskChartPalette.accent(forPercent: snap.percent)
                    )
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.MenuBarPopover.diskBootTitle)
                            .font(.subheadline.weight(.semibold))
                        Text(L10n.Disk.usedOverTotal(
                            usedFormatted: SpaceFormat.bytes(snap.used),
                            totalFormatted: SpaceFormat.bytes(snap.total)
                        ))
                        .font(.callout)
                        Text(SpaceFormat.percent(part: snap.used, of: snap.total))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            } else {
                Text(L10n.MenuBarPopover.diskUnavailable)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear(perform: refreshSnapshot)
    }

    /// 弹层打开时刷新；容量变化较慢，无需高频轮询。
    private func refreshSnapshot() {
        snapshot = BootVolumeSpaceReader.snapshot()
    }
}

/// 引导用户打开主窗口使用完整扫描与规则能力。
struct MenuBarManagerTabContent: View {
    var body: some View {
        Text(L10n.MenuBarPopover.managerIntro)
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}
