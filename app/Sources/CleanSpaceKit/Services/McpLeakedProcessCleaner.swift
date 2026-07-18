//
//  McpLeakedProcessCleaner.swift
//  CleanSpaceKit
//
//  检测并结束重复泄漏的 MCP `npm exec` 子进程（如 chrome-devtools-mcp、Playwright 等）。
//  扫描阶段汇总 RSS；清理阶段对匹配 PID 发送 SIGTERM。
//

import Foundation

/// 单条待清理的 MCP 相关进程。
struct McpLeakedProcess: Equatable, Sendable {
    let pid: Int32
    let commandLine: String
    let rssBytes: Int64
}

enum McpLeakedProcessCleaner {
    /// 与 `cleaning-rules.json` 中规则 `id` 一致。
    static let ruleId = "mcp-leaked-processes"

    /// `pgrep -lf` 行中命令需包含以下子串之一才视为可清理的 MCP 泄漏。
    static let matchSubstrings: [String] = [
        "npm exec chrome-devtools-mcp",
        "npm exec @playwright/mcp",
        "npm exec obsidian-mcp-server",
        "npm exec spec-workflow-mcp",
        "npm exec electron-mcp-server",
    ]

    /// 永不结束的进程命令特征（如 Cursor 语言服务）。
    static let allowlistSubstrings: [String] = [
        "typescript-language-server",
    ]

    // MARK: - 纯函数（可单元测试）

    /// 解析 `pgrep -lf` 单行：`"<pid> <command...>"`。
    static func parsePgrepLine(_ line: String) -> (pid: Int32, commandLine: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count == 2, let pid = Int32(parts[0]) else { return nil }
        return (pid, String(parts[1]))
    }

    /// 判断命令行是否为应清理的泄漏 MCP 进程。
    static func isLeakedMcpCommandLine(_ commandLine: String) -> Bool {
        let lower = commandLine.lowercased()
        guard lower.contains("npm exec") else { return false }
        guard !allowlistSubstrings.contains(where: { lower.contains($0.lowercased()) }) else { return false }
        return matchSubstrings.contains { lower.contains($0.lowercased()) }
    }

    /// 从 `pgrep -lf` 输出筛选泄漏进程（不含 RSS）。
    static func leakedProcesses(fromPgrepOutput output: String) -> [(pid: Int32, commandLine: String)] {
        output
            .split(separator: "\n", omittingEmptySubsequences: false)
            .compactMap { line -> (pid: Int32, commandLine: String)? in
                guard let parsed = parsePgrepLine(String(line)) else { return nil }
                return isLeakedMcpCommandLine(parsed.commandLine) ? parsed : nil
            }
    }

    /// 解析 `ps -o rss= -p …` 输出为字节（macOS `rss` 列为 KB）。
    static func rssBytes(fromPsRssOutput output: String, pageSizeKB: Int64 = 1) -> Int64 {
        let kb = output
            .split(whereSeparator: \.isWhitespace)
            .compactMap { Int64($0) }
            .reduce(0, +)
        return kb * pageSizeKB * 1024
    }

    // MARK: - 运行时扫描 / 清理

    /// 列出当前匹配且未在白名单中的 MCP 泄漏进程。
    static func listLeakedProcesses() -> [McpLeakedProcess] {
        let listing = ShellCommandRunner.run("pgrep -lf 'npm exec' 2>/dev/null || true")
        let candidates = leakedProcesses(fromPgrepOutput: listing.output)
        guard !candidates.isEmpty else { return [] }

        let pidList = candidates.map { String($0.pid) }.joined(separator: ",")
        let rssResult = ShellCommandRunner.run("ps -o rss= -p \(pidList) 2>/dev/null || true")
        let perPidKB = rssResult.output
            .split(whereSeparator: \.isNewline)
            .compactMap { Int64($0.trimmingCharacters(in: .whitespaces)) }

        return candidates.enumerated().map { index, item in
            let kb = index < perPidKB.count ? perPidKB[index] : 0
            return McpLeakedProcess(pid: item.pid, commandLine: item.commandLine, rssBytes: kb * 1024)
        }
    }

    /// 扫描：返回匹配进程 RSS 之和（无匹配时为 0）。
    static func scanTotalRSSBytes() -> Int64 {
        listLeakedProcesses().reduce(0) { $0 + $1.rssBytes }
    }

    /// 结束泄漏进程；返回 (成功数, 失败数)。
    @discardableResult
    static func terminateLeakedProcesses() -> (killed: Int, failed: Int) {
        let targets = listLeakedProcesses()
        guard !targets.isEmpty else { return (0, 0) }

        var killed = 0
        var failed = 0
        for process in targets {
            let result = ShellCommandRunner.run("kill -TERM \(process.pid) 2>/dev/null")
            if result.status == 0 {
                killed += 1
            } else {
                failed += 1
            }
        }
        return (killed, failed)
    }

    /// 清理结果文案（供 `cleanRule` 使用）。
    static func cleanOutcome() -> (success: Bool, message: String) {
        let before = listLeakedProcesses()
        guard !before.isEmpty else {
            return (true, L10n.Clean.mcpNoneFound)
        }
        let outcome = terminateLeakedProcesses()
        if outcome.failed == 0 {
            return (true, L10n.Clean.mcpKilled(outcome.killed))
        }
        if outcome.killed > 0 {
            return (false, L10n.Clean.mcpPartial(killed: outcome.killed, failed: outcome.failed))
        }
        return (false, L10n.Clean.mcpKillFailed)
    }

    /// 后台列举泄漏进程（供预览 / 分析，勿在主线程 `body` 内同步调用 `listLeakedProcesses`）。
    static func listLeakedProcessesInBackground() async -> [McpLeakedProcess] {
        await Task.detached(priority: .userInitiated) {
            listLeakedProcesses()
        }.value
    }

    /// 后台执行清理并返回结果文案。
    static func cleanOutcomeInBackground() async -> (success: Bool, message: String) {
        await Task.detached(priority: .userInitiated) {
            cleanOutcome()
        }.value
    }
}
