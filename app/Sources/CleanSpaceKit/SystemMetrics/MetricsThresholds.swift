//
//  MetricsThresholds.swift
//  CleanSpaceKit
//
//  告警阈值与通知节流间隔（可按需改为 UserDefaults）。
//

import Foundation

enum MetricsThresholds {
    /// CPU 占用 ≥ 该百分比时触发通知（0...100）。
    static let cpuPercent: Double = 85
    /// 内存占用 ≥ 该百分比时触发通知。
    static let memoryPercent: Double = 85
    /// 任一方向上传或下载速率 ≥ 该值（字节/秒）时触发网络通知。
    static let networkBps: Double = 80 * 1024 * 1024
    /// 是否对网络速率发通知（易抖动，默认关闭；菜单栏仍显示实时速率）。
    static let notifyOnNetwork: Bool = false
    /// 同一类指标两次通知最短间隔（秒），避免刷屏。
    static let notificationCooldownSeconds: TimeInterval = 120
}
