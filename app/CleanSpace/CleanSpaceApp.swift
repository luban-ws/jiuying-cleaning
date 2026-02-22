//
//  CleanSpaceApp.swift
//  CleanSpace
//
//  macOS 清理应用入口：管理浏览器、Docker、AI 工具等占用空间。
//

import SwiftUI

@main
struct CleanSpaceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
