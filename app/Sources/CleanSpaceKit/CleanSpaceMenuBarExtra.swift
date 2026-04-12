//
//  CleanSpaceMenuBarExtra.swift
//  CleanSpaceKit
//
//  菜单栏（状态栏）图标：与主窗口并存，便于在关窗后仍可从顶部打开应用。
//

import AppKit
import SwiftUI

/// 供可执行目标 `MenuBarExtra` 使用的公开文案与符号（`L10n` 仅模块内可见）。
public enum CleanSpaceMenuBarExtraChrome {
    public static let systemImageName = "internaldrive"
    public static var menuBarTitle: String { L10n.App.name }
}

/// `MenuBarExtra` 内下拉内容：依赖场景环境里的 `openWindow`（与 `WindowGroup(id:)` 一致）。
public struct CleanSpaceMenuBarExtraMenuContent: View {
    @Environment(\.openWindow) private var openWindow

    public init() {}

    public var body: some View {
        Button(L10n.Menu.openApp(L10n.App.name)) {
            openWindow(id: AppWindowSceneID.main)
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        Button(L10n.Menu.quitApp(L10n.App.name)) {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
