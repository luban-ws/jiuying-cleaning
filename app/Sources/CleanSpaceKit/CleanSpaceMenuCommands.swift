//
//  CleanSpaceMenuCommands.swift
//  CleanSpaceKit
//
//  与 `Window(id:)` 配套的菜单命令：替换 `.newItem`，用于前置唯一主窗口（⌘N 与程序坞再次打开一致，不会叠开多扇）。
//

import SwiftUI

/// 主窗口 Scene 标识（须与 `Window(id:)` 一致，供 `openWindow(id:)` 使用）。
public enum AppWindowSceneID {
    /// 单一主界面窗口（磁盘 / 规则 / Docker）。
    public static let main: String = "main"
}

/// File 菜单中的「显示主窗口」及 ⌘N：前置唯一主窗口，与菜单栏「打开」、程序坞行为一致。
public struct CleanSpaceMenuCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    public init() {}

    public var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(L10n.Menu.showMainWindow) {
                openWindow(id: AppWindowSceneID.main)
            }
            .keyboardShortcut("n", modifiers: .command)
        }
    }
}
