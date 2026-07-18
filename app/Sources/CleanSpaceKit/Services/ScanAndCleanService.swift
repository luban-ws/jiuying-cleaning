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

/// 列出目录内容；权限拒绝写入 `report`（RFC 004 主触发证据）。
private func contentsOfDirectoryCapturingDenial(at path: String, report: inout AccessDenialReport) -> [String] {
    do {
        return try FileManager.default.contentsOfDirectory(atPath: path)
    } catch {
        report.recordDenial(at: path, error: error)
        return []
    }
}

/// 对已存在的目录主动探测枚举权限（捕获 TCC 拒绝，避免静默得到 0 字节）。
private func probeDirectoryAccess(at path: String, report: inout AccessDenialReport) {
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else { return }
    _ = contentsOfDirectoryCapturingDenial(at: path, report: &report)
}

/// 对单条 dir 规则解析路径，并收集枚举时的权限拒绝。
func resolvePathsWithAccessReport(for rule: CleaningRule) -> (paths: [String], accessDenial: AccessDenialReport) {
    guard rule.type == .dir, let paths = rule.paths else {
        return ([], .empty)
    }
    var result: [String] = []
    var report = AccessDenialReport.empty
    for p in paths {
        let originalBase = expandingTilde(in: p.base)
        let bases = expandBasePaths(base: originalBase)
        for base in bases {
            for d in p.dirs {
                if d == "*" {
                    let contents = contentsOfDirectoryCapturingDenial(at: base, report: &report)
                    result.append(contentsOf: contents.map { (base as NSString).appendingPathComponent($0) })
                } else if d.contains("*") {
                    let parts = d.components(separatedBy: "/")
                    var currentPaths = [base]
                    for part in parts {
                        var nextPaths: [String] = []
                        for curr in currentPaths {
                            if part == "*" {
                                let contents = contentsOfDirectoryCapturingDenial(at: curr, report: &report)
                                nextPaths.append(contentsOf: contents.map { (curr as NSString).appendingPathComponent($0) })
                            } else {
                                let nextPath = (curr as NSString).appendingPathComponent(part)
                                nextPaths.append(nextPath)
                            }
                        }
                        currentPaths = nextPaths
                    }
                    result.append(contentsOf: currentPaths)
                } else {
                    let full = (base as NSString).appendingPathComponent(d)
                    result.append(full)
                    probeDirectoryAccess(at: full, report: &report)
                }
            }
        }
    }
    return (result, report)
}

/// 对单条 dir 规则，解析出所有要扫描/删除的绝对路径（`dir` + `paths`；`command` 规则返回空数组）。
func resolvePaths(for rule: CleaningRule) -> [String] {
    resolvePathsWithAccessReport(for: rule).paths
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

/// 递归计算目录占用字节，并在无法创建 enumerator 时探测权限拒绝。
func directorySizeBytesWithAccessReport(
    url: URL,
    enumeratorOptions: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
) -> (bytes: Int64, accessDenial: AccessDenialReport) {
    let fm = FileManager.default
    var report = AccessDenialReport.empty
    guard let enumerator = fm.enumerator(
        at: url,
        includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
        options: enumeratorOptions
    ) else {
        // enumerator 为 nil 时主动枚举一次，以拿到可判定的 errno/Cocoa 错误
        do {
            _ = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        } catch {
            report.recordDenial(at: url.path, error: error)
        }
        return (0, report)
    }
    var total: Int64 = 0
    for case let fileURL as URL in enumerator {
        guard let resource = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
              resource.isDirectory == false,
              let size = resource.fileSize else { continue }
        total += Int64(size)
    }
    return (total, report)
}

/// 递归计算目录占用字节（仅统计文件；`options` 默认可跳过隐藏项以贴近访达部分视图）
func directorySizeBytes(url: URL, enumeratorOptions: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]) -> Int64 {
    directorySizeBytesWithAccessReport(url: url, enumeratorOptions: enumeratorOptions).bytes
}

/// 单条规则扫描结果（体积 + RFC 004 权限拒绝证据）。
struct RuleScanOutcome: Sendable {
    var bytes: Int64?
    var accessDenial: AccessDenialReport
}

/// 扫描单条规则占用，并收集权限拒绝路径。
func scanRuleWithAccessReport(_ rule: CleaningRule) -> RuleScanOutcome {
    if rule.id == McpLeakedProcessCleaner.ruleId {
        return RuleScanOutcome(bytes: McpLeakedProcessCleaner.scanTotalRSSBytes(), accessDenial: .empty)
    }
    switch rule.type {
    case .dir:
        let resolved = resolvePathsWithAccessReport(for: rule)
        var report = resolved.accessDenial
        var total: Int64 = 0
        for path in resolved.paths {
            let url = URL(fileURLWithPath: path)
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
            if isDir.boolValue {
                let sized = directorySizeBytesWithAccessReport(url: url)
                total += sized.bytes
                report.merge(sized.accessDenial)
            } else {
                do {
                    let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
                    if let size = attrs[.size] as? Int64 {
                        total += size
                    }
                } catch {
                    report.recordDenial(at: url.path, error: error)
                }
            }
        }
        return RuleScanOutcome(bytes: total, accessDenial: report)
    case .command:
        return RuleScanOutcome(bytes: nil, accessDenial: .empty)
    }
}

/// 扫描单条规则占用（dir 为实际字节，command 返回 nil 表示用 estimate）
func scanRule(_ rule: CleaningRule) -> Int64? {
    scanRuleWithAccessReport(rule).bytes
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
