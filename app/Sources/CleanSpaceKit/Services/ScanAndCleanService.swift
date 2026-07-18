//
//  ScanAndCleanService.swift
//  CleanSpace
//
//  按 RFC 规则执行扫描（计算占用）与清理（删目录或执行命令）。
//

import Foundation

/// 将路径中的 ~ 展开为用户主目录
private func expandingTilde(in path: String) -> String {
    (path as NSString).expandingTildeInPath
}

/// 检查基础路径是否形如 profile 路径，若是则展开为所有发现的 profiles。
private func expandBasePaths(base: String) -> [String] {
    let baseURL = URL(fileURLWithPath: base).standardized
    let lastComponent = baseURL.lastPathComponent
    
    let isProfileShape = lastComponent == "Default" ||
                         lastComponent == "Guest Profile" ||
                         lastComponent == "System Profile" ||
                         (lastComponent.hasPrefix("Profile ") && Int(lastComponent.dropFirst("Profile ".count)) != nil)
    
    if isProfileShape {
        let appRootURL = baseURL.deletingLastPathComponent()
        let discoveredProfiles = ChromiumProfileDiscoverer.discoverProfiles(in: appRootURL.path)
        if !discoveredProfiles.isEmpty {
            return discoveredProfiles.map { appRootURL.appendingPathComponent($0).path }
        }
    }
    
    return [base]
}

/// 对单条 dir 规则，解析出所有要扫描/删除的绝对路径（`dir` + `paths`；`command` 规则返回空数组）。
func resolvePaths(for rule: CleaningRule) -> [String] {
    guard rule.type == .dir, let paths = rule.paths else { return [] }
    var result: [String] = []
    for p in paths {
        let originalBase = expandingTilde(in: p.base)
        let bases = expandBasePaths(base: originalBase)
        for base in bases {
            for d in p.dirs {
                if d == "*" {
                    guard let contents = try? FileManager.default.contentsOfDirectory(atPath: base) else { continue }
                    result.append(contentsOf: contents.map { (base as NSString).appendingPathComponent($0) })
                } else if d.contains("*") {
                    let parts = d.components(separatedBy: "/")
                    var currentPaths = [base]
                    for part in parts {
                        var nextPaths: [String] = []
                        for curr in currentPaths {
                            if part == "*" {
                                if let contents = try? FileManager.default.contentsOfDirectory(atPath: curr) {
                                    nextPaths.append(contentsOf: contents.map { (curr as NSString).appendingPathComponent($0) })
                                }
                            } else {
                                let nextPath = (curr as NSString).appendingPathComponent(part)
                                nextPaths.append(nextPath)
                            }
                        }
                        currentPaths = nextPaths
                    }
                    result.append(contentsOf: currentPaths)
                } else {
                    result.append((base as NSString).appendingPathComponent(d))
                }
            }
        }
    }
    return result
}

/// 演练用：目录规则为「将作用的目标路径 + 是否已存在于磁盘」；命令规则为将执行的 shell（若无则为空）。
enum RuleDryRunPayload: Sendable {
    case directory(targets: [(path: String, exists: Bool)])
    case commandLine(String)
    case processes([(pid: Int32, commandLine: String)])
    case noCommand
}

/// 不读文件体积、不删文件；供「预览」面板展示即将清理的对象。
/// MCP 进程列表须在后台加载，不可在 SwiftUI `body` 中同步调用（会阻塞主线程并触发 AttributeGraph 崩溃）。
func ruleDryRunPayload(for rule: CleaningRule) -> RuleDryRunPayload {
    if rule.id == McpLeakedProcessCleaner.ruleId {
        return .noCommand
    }
    switch rule.type {
    case .dir:
        let paths = resolvePaths(for: rule)
        let fm = FileManager.default
        let targets = paths.map { ($0, fm.fileExists(atPath: $0)) }
        return .directory(targets: targets)
    case .command:
        guard let cmd = rule.command, !cmd.isEmpty else { return .noCommand }
        return .commandLine(cmd)
    }
}

/// 递归计算目录占用字节（仅统计文件；`options` 默认可跳过隐藏项以贴近访达部分视图）
func directorySizeBytes(url: URL, enumeratorOptions: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]) -> Int64 {
    let fm = FileManager.default
    guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: enumeratorOptions) else { return 0 }
    var total: Int64 = 0
    for case let fileURL as URL in enumerator {
        guard let resource = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
              resource.isDirectory == false,
              let size = resource.fileSize else { continue }
        total += Int64(size)
    }
    return total
}

/// 扫描单条规则占用（dir 为实际字节，command 返回 nil 表示用 estimate）
func scanRule(_ rule: CleaningRule) -> Int64? {
    if rule.id == McpLeakedProcessCleaner.ruleId {
        return McpLeakedProcessCleaner.scanTotalRSSBytes()
    }
    switch rule.type {
    case .dir:
        let urls = resolvePaths(for: rule).map { URL(fileURLWithPath: $0) }
        var total: Int64 = 0
        for url in urls {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
            if isDir.boolValue {
                total += directorySizeBytes(url: url)
            } else {
                if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = attrs[.size] as? Int64 {
                    total += size
                }
            }
        }
        return total
    case .command:
        return nil
    }
}

/// 执行单条规则清理
func cleanRule(_ rule: CleaningRule) -> (success: Bool, message: String) {
    if rule.id == McpLeakedProcessCleaner.ruleId {
        return McpLeakedProcessCleaner.cleanOutcome()
    }
    let fm = FileManager.default
    switch rule.type {
    case .dir:
        let paths = resolvePaths(for: rule)
        var deleted: Int = 0
        var errors: [String] = []
        for path in paths {
            guard fm.fileExists(atPath: path) else { continue }
            do {
                try fm.removeItem(atPath: path)
                deleted += 1
            } catch {
                errors.append("\(path): \(error.localizedDescription)")
            }
        }
        if errors.isEmpty {
            return (true, L10n.Clean.deleted(deleted))
        }
        return (false, L10n.Clean.partialFail(errors.prefix(2).joined(separator: " ")))
    case .command:
        guard let cmd = rule.command else { return (false, L10n.Clean.missingCommand) }
        let r = ShellCommandRunner.run(cmd)
        if r.status == 0 {
            return (true, r.output.isEmpty ? L10n.Clean.executed : r.output)
        }
        return (false, L10n.Clean.exitCode(r.status, r.output))
    }
}
