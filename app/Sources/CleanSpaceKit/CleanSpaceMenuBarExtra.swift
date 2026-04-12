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

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MetricsMenuBarDetailsList()
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Button(L10n.Menu.openApp(L10n.App.name)) {
                    openWindow(id: AppWindowSceneID.main)
                    NSApp.activate(ignoringOtherApps: true)
                }
                Button(L10n.Menu.quitApp(L10n.App.name)) {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }
}
