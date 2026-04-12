//
//  ShellCommandRunner.swift
//  CleanSpace
//
//  统一在子进程中执行 shell 命令（含 Docker 所需 PATH）。
//

import Foundation

enum ShellCommandRunner {
    /// GUI 应用下补齐常见 PATH，便于找到 docker
    static func environmentForSubprocess() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let extra = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
        if let path = env["PATH"], !path.isEmpty {
            env["PATH"] = "\(extra):\(path)"
        } else {
            env["PATH"] = extra
        }
        return env
    }

    /// 执行 `sh -c command`，返回 (退出码, 合并后的 stdout/stderr)
    static func run(_ command: String) -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        process.environment = environmentForSubprocess()
        process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return (process.terminationStatus, output.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            return (-1, error.localizedDescription)
        }
    }
}
