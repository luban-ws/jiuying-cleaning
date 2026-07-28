//
//  DesktopApp.swift
//  CleanSpaceDesktopRuntime
//

import CleanSpaceDesktopIPC
import Foundation
import VeloxRuntime
import VeloxRuntimeWry
#if os(macOS)
import AppKit
#endif

public enum DesktopApp {
  private static let mainWindowLabel = "main"
  #if os(macOS)
  @MainActor private static var singleInstanceCoordinator: SingleInstanceCoordinator?
  #endif

  @MainActor public static func run() {
    guard Thread.isMainThread else {
      fatalError("CleanSpaceDesktop must run on the main thread")
    }

    #if os(macOS)
    guard acquireSingleInstance() else {
      return
    }

    #endif

    let projectRoot = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()

    var config: VeloxConfig
    do {
      config = try VeloxConfig.load(from: projectRoot)
    } catch {
      fatalError("Failed to load velox.json: \(error)")
    }

    if let devURL = ProcessInfo.processInfo.environment["VELOX_DEV_URL"], !devURL.isEmpty {
      for index in config.app.windows.indices {
        config.app.windows[index].url = devURL
      }
      print("[desktop] Dev server: \(devURL)")
    }

    let eventManager = VeloxEventManager()
    wireScanEventSink(eventManager: eventManager)

    let assets = AssetBundle()
    let appHandler: VeloxRuntimeWry.CustomProtocol.Handler = { request in
      guard let url = URL(string: request.url) else {
        return VeloxRuntimeWry.CustomProtocol.Response(
          status: 400,
          headers: ["Content-Type": "text/plain"],
          body: Data("Invalid URL".utf8)
        )
      }
      if let asset = assets.loadAsset(path: url.path) {
        return VeloxRuntimeWry.CustomProtocol.Response(
          status: 200,
          headers: ["Content-Type": asset.mimeType],
          mimeType: asset.mimeType,
          body: asset.data
        )
      }
      return VeloxRuntimeWry.CustomProtocol.Response(
        status: 404,
        headers: ["Content-Type": "text/plain"],
        body: Data("Asset not found: \(url.path)".utf8)
      )
    }

    do {
      try VeloxAppBuilder(config: config, eventManager: eventManager)
        .registerProtocol("ipc") { request in
          IPCHTTP.handleInvoke(request: request)
        }
        .registerProtocol("app", handler: appHandler)
        .run { event in
          switch event {
          case .windowCloseRequested, .userExit:
            return .exit
          default:
            return .wait
          }
        }
    } catch {
      fatalError("Failed to start app: \(error)")
    }
  }

  #if os(macOS)
  @MainActor private static func acquireSingleInstance() -> Bool {
    let coordinator = SingleInstanceCoordinator.live()
    do {
      let role = try coordinator.start {
        activateMainWindow()
      }
      guard role == .primary else {
        return false
      }
      singleInstanceCoordinator = coordinator
      return true
    } catch {
      fatalError("Failed to establish single-instance lifecycle: \(error)")
    }
  }

  @MainActor private static func activateMainWindow() {
    NSApp.unhide(nil)
    NSApp.activate()

    let window = NSApp.mainWindow
      ?? NSApp.keyWindow
      ?? NSApp.windows.first(where: \.canBecomeMain)
    if window?.isMiniaturized == true {
      window?.deminiaturize(nil)
    }
    window?.makeKeyAndOrderFront(nil)
  }
  #endif

  private static func wireScanEventSink(eventManager: VeloxEventManager) {
    RulesScanEventSink.onProgress = { progress in
      DispatchQueue.main.async {
        try? eventManager.emitTo(mainWindowLabel, event: "scan_progress", payload: progress)
      }
    }
    RulesScanEventSink.onComplete = { complete in
      DispatchQueue.main.async {
        try? eventManager.emitTo(mainWindowLabel, event: "scan_complete", payload: complete)
      }
    }
    RulesScanEventSink.onError = { error in
      DispatchQueue.main.async {
        try? eventManager.emitTo(mainWindowLabel, event: "scan_error", payload: error)
      }
    }

    RulesCleanEventSink.onProgress = { progress in
      DispatchQueue.main.async {
        try? eventManager.emitTo(mainWindowLabel, event: "clean_progress", payload: progress)
      }
    }
    RulesCleanEventSink.onComplete = { result in
      DispatchQueue.main.async {
        try? eventManager.emitTo(mainWindowLabel, event: "clean_complete", payload: result)
      }
    }
    RulesCleanEventSink.onError = { error in
      DispatchQueue.main.async {
        try? eventManager.emitTo(mainWindowLabel, event: "clean_error", payload: error)
      }
    }

    RulePreviewEventSink.onComplete = { preview in
      DispatchQueue.main.async {
        try? eventManager.emitTo(mainWindowLabel, event: "preview_complete", payload: preview)
      }
    }
    RulePreviewEventSink.onError = { error in
      DispatchQueue.main.async {
        try? eventManager.emitTo(mainWindowLabel, event: "preview_error", payload: error)
      }
    }

    VolumeScanEventSink.onComplete = { result in
      DispatchQueue.main.async {
        try? eventManager.emitTo(mainWindowLabel, event: "volume_scan_complete", payload: result)
      }
    }
    VolumeScanEventSink.onError = { error in
      DispatchQueue.main.async {
        try? eventManager.emitTo(mainWindowLabel, event: "volume_scan_error", payload: error)
      }
    }

    DockerJobEventSink.onRefreshComplete = { result in
      DispatchQueue.main.async {
        try? eventManager.emitTo(mainWindowLabel, event: "docker_refresh_complete", payload: result)
      }
    }
    DockerJobEventSink.onPresetComplete = { result in
      DispatchQueue.main.async {
        try? eventManager.emitTo(mainWindowLabel, event: "docker_preset_complete", payload: result)
      }
    }
    DockerJobEventSink.onError = { error in
      DispatchQueue.main.async {
        try? eventManager.emitTo(mainWindowLabel, event: "docker_job_error", payload: error)
      }
    }
  }
}
