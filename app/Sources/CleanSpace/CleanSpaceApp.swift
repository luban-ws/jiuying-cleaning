//
//  CleanSpaceApp.swift
//  CleanSpace
//
//  可执行入口：界面与业务在 CleanSpaceKit，本目标仅 @main。
//

import AppKit
import CleanSpaceKit
import SwiftUI

@main
struct CleanSpaceApp: App {
    var body: some Scene {
        // 使用 `Window`（非 `WindowGroup`）保证全局仅一扇主窗口；`openWindow(id:)` 会前置已有窗口而不会叠开多扇。
        Window("app.name", id: AppWindowSceneID.main) {
            ContentView()
                .environmentObject(SystemMetricsController.shared)
                .frame(minWidth: 1000, minHeight: 640)
                // 从终端 `swift run` / `pnpm run:app` 启动时把窗口前置，避免误以为未启动
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    SystemMetricsController.shared.start()
                }
        }
        // 与当前 macOS 标准一致：unified 工具栏（HIG + `windowToolbarStyle`）。
        // 若将来采用 `toolbarBackgroundVisibility(.hidden, for: .windowToolbar)` 等沉浸式顶栏，需配合 `WindowDragGesture` 与内容顶区布局（参见 Apple「Customizing window styles」与 Destination Video 示例）。
        .defaultSize(width: 1020, height: 720)
        .windowToolbarStyle(.unified)
        .commands {
            CleanSpaceMenuCommands()
        }

        // 仅一个菜单栏图标：仪表盘标签；点开后为监控图表 +「打开 CleanSpace」「退出」。
        MenuBarExtra {
            CleanSpaceUnifiedMenuBarExtraContent()
        } label: {
            MetricsMenuBarCompactLabel()
        }
        .menuBarExtraStyle(.window)
    }
}
