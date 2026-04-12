//
//  DockerSpecialCleanService.swift
//  CleanSpace
//
//  Docker 专项清理：按预设顺序执行多条命令（非单条 JSON 规则可比）。
//

import Foundation

/// Docker 专项预设：一键按顺序执行多步清理
enum DockerCleanPreset: String, CaseIterable, Identifiable {
    case quick = "快速"
    case standard = "标准"
    case deep = "深度"
    case desktopDataScan = "仅分析 Desktop 占用"

    var id: String { rawValue }

    var title: String { rawValue }

    var subtitle: String {
        switch self {
        case .quick:
            return "停止容器 + 构建缓存，风险低"
        case .standard:
            return "在快速基础上清理未使用镜像与网络"
        case .deep:
            return "含卷清理、system prune 与 Desktop 回收（最彻底）"
        case .desktopDataScan:
            return "仅执行 docker system df，不删除任何资源"
        }
    }

    /// 按顺序执行的 shell 命令（每步独立，前一步失败仍继续后续由调用方决定）
    var commandSteps: [String] {
        switch self {
        case .quick:
            return [
                "docker container prune -f",
                "docker builder prune -a -f"
            ]
        case .standard:
            return [
                "docker container prune -f",
                "docker builder prune -a -f",
                "docker image prune -a -f",
                "docker network prune -f"
            ]
        case .deep:
            return [
                "docker container prune -f",
                "docker builder prune -a -f",
                "docker image prune -a -f",
                "docker network prune -f",
                "docker volume prune -f",
                "docker system prune -a -f",
                "docker run --rm --privileged --pid=host docker/desktop-reclaim-space"
            ]
        case .desktopDataScan:
            return ["docker system df -v"]
        }
    }

    var isDestructive: Bool {
        self != .desktopDataScan
    }
}

enum DockerSpecialCleanService {
    /// 当前 Docker 磁盘占用概览（失败时返回说明文字）
    static func dockerSystemDf() -> String {
        let r = ShellCommandRunner.run("docker system df -v")
        if r.status == 0 { return r.output.isEmpty ? "（无输出）" : r.output }
        return "无法执行 docker（退出码 \(r.status)）：\(r.output)"
    }

    /// 顺序执行预设内所有命令，返回每步日志（单步失败仍继续后续步骤，便于一次看清全貌）
    static func runPreset(_ preset: DockerCleanPreset) -> [(command: String, success: Bool, output: String)] {
        var lines: [(String, Bool, String)] = []
        for cmd in preset.commandSteps {
            let r = ShellCommandRunner.run(cmd)
            let ok = r.status == 0
            let out = r.output.isEmpty ? (ok ? "完成" : "无输出") : r.output
            lines.append((cmd, ok, out))
        }
        return lines
    }

    /// Docker Desktop 常见数据目录占用（字节），用于「专项」展示
    static func desktopDataDirectoryBytes() -> [(label: String, path: String, bytes: Int64)] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let pairs: [(String, String)] = [
            ("Group Containers (docker)", "\(home)/Library/Group Containers/group.com.docker"),
            ("Application Support", "\(home)/Library/Application Support/Docker Desktop"),
            ("Caches", "\(home)/Library/Caches/Docker Desktop"),
            ("Containers", "\(home)/Library/Containers/com.docker.docker")
        ]
        return pairs.map { label, path in
            let url = URL(fileURLWithPath: path)
            let bytes = FileManager.default.fileExists(atPath: path) ? directorySizeBytes(url: url) : 0
            return (label, path, bytes)
        }
    }
}
