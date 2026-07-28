//
//  MetricsThresholdNotifier.swift
//  CleanSpaceKit
//
//  超阈值时发送本地通知（节流）；首次请求系统通知权限。
//

import Foundation
import UserNotifications

@MainActor
final class MetricsThresholdNotifier {
    static let shared = MetricsThresholdNotifier()

    private var lastSent: [String: Date] = [:]
    private var permissionRequested = false

    /// UserNotifications 要求进程具备有效 `CFBundleIdentifier`；裸 `swift run` 可执行文件若未嵌入 Info.plist 会在 `current()` 处 abort。
    private static var isUserNotificationsRuntimeSupported: Bool {
        guard let id = Bundle.main.bundleIdentifier, !id.isEmpty else { return false }
        return true
    }

    /// 在首次开始监控时调用，弹出一次授权对话框（用户拒绝则仅不再弹窗）。
    func requestPermissionIfNeeded() {
        guard Self.isUserNotificationsRuntimeSupported else { return }
        guard !permissionRequested else { return }
        permissionRequested = true
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func evaluate(cpu: Double, memoryPercent: Double, networkDownBps: Double, networkUpBps: Double) {
        if cpu >= MetricsThresholds.cpuPercent {
            notify(
                kind: "cpu",
                title: L10n.Metrics.notifCpuTitle,
                body: L10n.Metrics.notifCpuBody(pct: Int(cpu.rounded()))
            )
        }
        if memoryPercent >= MetricsThresholds.memoryPercent {
            notify(
                kind: "memory",
                title: L10n.Metrics.notifMemoryTitle,
                body: L10n.Metrics.notifMemoryBody(pct: Int(memoryPercent.rounded()))
            )
        }
        if MetricsThresholds.notifyOnNetwork {
            let peak = max(networkDownBps, networkUpBps)
            if peak >= MetricsThresholds.networkBps {
                notify(
                    kind: "network",
                    title: L10n.Metrics.notifNetworkTitle,
                    body: L10n.Metrics.notifNetworkBody(
                        down: MetricsFormat.bytesPerSecond(networkDownBps),
                        up: MetricsFormat.bytesPerSecond(networkUpBps)
                    )
                )
            }
        }
    }

    private func notify(kind: String, title: String, body: String) {
        guard Self.isUserNotificationsRuntimeSupported else { return }
        let now = Date()
        if let t = lastSent[kind], now.timeIntervalSince(t) < MetricsThresholds.notificationCooldownSeconds {
            return
        }
        lastSent[kind] = now
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.25, repeats: false)
        let id = "com.cleanspace.metrics.\(kind).\(UUID().uuidString)"
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}
