//
//  DockerSpecialCleanService.swift
//  CleanSpace
//
//  Docker 专项清理：按预设顺序执行多条命令（非单条 JSON 规则可比）。
//

import Foundation

/// Docker 专项预设：一键按顺序执行多步清理（`rawValue` 为稳定键，供 Localizable 使用）
enum DockerCleanPreset: String, CaseIterable, Identifiable {
    case quick
    case standard
    case deep
    case desktopDataScan

    var id: String { rawValue }

    var title: String { L10n.Docker.presetTitle(rawValue) }

    var subtitle: String { L10n.Docker.presetSubtitle(rawValue) }

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

    /// 预设卡片用 SF Symbol（与风险级别大致对应，仅装饰）。
    var symbolName: String {
        switch self {
        case .quick: return "bolt.fill"
        case .standard: return "square.stack.3d.up.fill"
        case .deep: return "flame.fill"
        case .desktopDataScan: return "chart.bar.doc.horizontal"
        }
    }
}

enum DockerSpecialCleanService {
    /// 拉取 `docker system df` 摘要 + `docker system df -v` 详情，供结构化 UI 解析。
    static func dockerDiskUsageReport() -> DockerDfReport {
        let summaryRun = ShellCommandRunner.run("docker system df")
        let verboseRun = ShellCommandRunner.run("docker system df -v")
        if summaryRun.status != 0, verboseRun.status != 0 {
            let code = summaryRun.status != 0 ? summaryRun.status : verboseRun.status
            let out = [summaryRun.output, verboseRun.output].filter { !$0.isEmpty }.joined(separator: "\n")
            return DockerDfReport(
                summaryRows: [],
                detailSections: [],
                summaryCommandFailed: true,
                verboseCommandFailed: true,
                fatalErrorText: L10n.DockerService.dfFail(code: code, output: out),
                rawSummary: summaryRun.output,
                rawVerbose: verboseRun.output
            )
        }
        let summaryRows = DockerSystemDfParser.parseSummary(summaryRun.output)
        let detailSections = DockerSystemDfParser.parseVerboseSections(verboseRun.output) { key in
            L10n.Docker.dfDetailSectionTitle(key: key)
        }.filter(\.hasRenderableContent)
        return DockerDfReport(
            summaryRows: summaryRows,
            detailSections: detailSections,
            summaryCommandFailed: summaryRun.status != 0,
            verboseCommandFailed: verboseRun.status != 0,
            fatalErrorText: nil,
            rawSummary: summaryRun.output,
            rawVerbose: verboseRun.output
        )
    }

    /// 当前 Docker 磁盘占用原始文本（仅 `-v`；供脚本或其它调用方，界面优先用 `dockerDiskUsageReport()`）
    static func dockerSystemDf() -> String {
        let r = ShellCommandRunner.run("docker system df -v")
        if r.status == 0 { return r.output.isEmpty ? L10n.DockerService.dfEmpty : r.output }
        return L10n.DockerService.dfFail(code: r.status, output: r.output)
    }

    /// 顺序执行预设内所有命令，返回每步日志（单步失败仍继续后续步骤，便于一次看清全貌）。
    /// - Parameters:
    ///   - onCommandWillRun: 某条命令即将在后台线程执行前调用（用于 UI 显示当前命令）。
    ///   - onCommandDidRun: 某条命令结束后调用（用于 UI 更新进度与追加日志）。
    static func runPreset(
        _ preset: DockerCleanPreset,
        onCommandWillRun: (@Sendable (_ stepIndex: Int, _ stepCount: Int, _ command: String) -> Void)? = nil,
        onCommandDidRun: (@Sendable (_ stepIndex: Int, _ stepCount: Int, _ command: String, _ success: Bool, _ output: String) -> Void)? = nil
    ) -> [(command: String, success: Bool, output: String)] {
        let steps = preset.commandSteps
        let total = steps.count
        var lines: [(String, Bool, String)] = []
        for (i, cmd) in steps.enumerated() {
            onCommandWillRun?(i, total, cmd)
            let r = ShellCommandRunner.run(cmd)
            let ok = r.status == 0
            let out = r.output.isEmpty ? (ok ? L10n.DockerService.stepDone : L10n.DockerService.stepNoOutput) : r.output
            onCommandDidRun?(i, total, cmd, ok, out)
            lines.append((cmd, ok, out))
        }
        return lines
    }

    /// Docker Desktop 常见数据目录占用（字节），用于「专项」展示
    static func desktopDataDirectoryBytes() -> [(label: String, path: String, bytes: Int64)] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let pairs: [(String, String)] = [
            (L10n.Docker.desktopLabelGroupContainers, "\(home)/Library/Group Containers/group.com.docker"),
            (L10n.Docker.desktopLabelAppSupport, "\(home)/Library/Application Support/Docker Desktop"),
            (L10n.Docker.desktopLabelCaches, "\(home)/Library/Caches/Docker Desktop"),
            (L10n.Docker.desktopLabelContainers, "\(home)/Library/Containers/com.docker.docker")
        ]
        return pairs.map { label, path in
            let url = URL(fileURLWithPath: path)
            let bytes = FileManager.default.fileExists(atPath: path) ? directorySizeBytes(url: url) : 0
            return (label, path, bytes)
        }
    }
}
