//
//  CleanSpaceApp.swift
//  CleanSpace
//
//  可执行入口：界面与业务在 CleanSpaceKit，本目标仅 @main。
//

import CleanSpaceKit
import SwiftUI

@main
struct CleanSpaceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 960, minHeight: 640)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
