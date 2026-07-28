//
//  CleanSpaceMenuBarExtra.swift
//  CleanSpaceKit
//
//  单一菜单栏项：弹层内为系统监控图表与文案，底部提供打开主窗口 / 退出（不再使用第二个 MenuBarExtra）。
//

import AppKit
import SwiftUI

/// 合并监控详情与应用操作，供 `MenuBarExtra` 的 `.window` 内容使用（依赖 `openWindow` 环境）。
public struct CleanSpaceUnifiedMenuBarExtraContent: View {
    @Environment(\.openWindow) private var openWindow

    private enum PopoverTab: String, CaseIterable, Hashable {
        case monitor
        case disk
        case manager
    }

    @State private var tab: PopoverTab = .monitor

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker(selection: $tab) {
                Text(L10n.MenuBarPopover.tabMonitor).tag(PopoverTab.monitor)
                Text(L10n.MenuBarPopover.tabDisk).tag(PopoverTab.disk)
                Text(L10n.MenuBarPopover.tabManager).tag(PopoverTab.manager)
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Group {
                switch tab {
                case .monitor:
                    MetricsMenuBarDetailsList()
                case .disk:
                    MenuBarDiskTabContent()
                case .manager:
                    MenuBarManagerTabContent()
                }
            }
            .frame(minWidth: 300, alignment: .leading)

            Divider()

            HStack(spacing: 8) {
                Button(L10n.Menu.openApp(L10n.App.name)) {
                    openWindow(id: AppWindowSceneID.main)
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .frame(maxWidth: .infinity)

                Button(L10n.Menu.quitApp(L10n.App.name)) {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}
