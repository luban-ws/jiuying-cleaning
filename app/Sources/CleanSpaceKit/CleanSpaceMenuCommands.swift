//
//  CleanSpaceMenuCommands.swift
//  CleanSpaceKit
//
//  与 `WindowGroup(id:)` 配套的菜单命令：恢复「新建窗口」，避免空替换 `.newItem` 导致 Dock / 再次打开无法呈现主窗口。
//

import SwiftUI

/// 主窗口 Scene 标识（须与 `WindowGroup(id:)` 一致，供 `openWindow(id:)` 使用）。
public enum AppWindowSceneID {
    /// 单一主界面窗口（磁盘 / 规则 / Docker）。
    public static let main: String = "main"
}

/// File 菜单中的「新建窗口」及 ⌘N，与程序坞在无窗口时再次打开等行为对齐。
public struct CleanSpaceMenuCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    public init() {}

    public var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(L10n.Menu.newMainWindow) {
                openWindow(id: AppWindowSceneID.main)
            }
            .keyboardShortcut("n", modifiers: .command)
        }
    }
}
