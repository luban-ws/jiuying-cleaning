//
//  IPCCommandPolicy.swift
//  CleanSpaceDesktopIPC
//
//  长耗时命令仅允许 start/poll；同步阻塞 API 不得从 IPC 直接暴露。
//

import Foundation

public enum IPCCommandPolicy {
    /// 仅内存/快速读取；可在 IPC 线程同步执行（仍经 IPCHTTP 后台队列）。
    public static let instantCommands: Set<String> = [
        "list_rules",
        "list_volumes",
        "docker_preset_ids",
        "docker_presets",
        "metrics_snapshot",
        "open_path",
        "fda_should_show_banner",
        "fda_open_settings",
        "fda_suppress_guidance",
        "scan_all_rules_start",
        "scan_all_rules_poll",
        "clean_rules_start",
        "clean_rules_poll",
        "preview_rule_start",
        "preview_rule_poll",
        "scan_volume_start",
        "scan_volume_poll",
        "docker_refresh_start",
        "docker_refresh_poll",
        "docker_run_preset_start",
        "docker_run_preset_poll",
    ]

    /// 已废弃的同步阻塞命令（返回 badRequest）。
    public static let deprecatedSyncCommands: Set<String> = [
        "scan_rules",
        "scan_all_rules",
        "clean_rules",
        "preview_rule",
        "scan_volume",
        "docker_disk_usage",
        "docker_disk_usage_parsed",
        "docker_desktop_sizes",
        "docker_run_preset",
    ]

    public static func deprecatedMessage(for command: String) -> String {
        switch command {
        case "scan_rules", "scan_all_rules":
            return "use scan_all_rules_start + scan_all_rules_poll"
        case "clean_rules":
            return "use clean_rules_start + clean_rules_poll"
        case "preview_rule":
            return "use preview_rule_start + preview_rule_poll"
        case "scan_volume":
            return "use scan_volume_start + scan_volume_poll"
        case "docker_disk_usage", "docker_disk_usage_parsed", "docker_desktop_sizes":
            return "use docker_refresh_start + docker_refresh_poll"
        case "docker_run_preset":
            return "use docker_run_preset_start + docker_run_preset_poll"
        default:
            return "command is synchronous-only and disabled; use async start/poll pair"
        }
    }

    public static func isInstant(_ command: String) -> Bool {
        instantCommands.contains(command)
    }

    public static func isDeprecatedSync(_ command: String) -> Bool {
        deprecatedSyncCommands.contains(command)
    }
}
