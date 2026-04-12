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

/// 对单条 dir 规则，解析出所有要扫描/删除的绝对路径
private func resolvePaths(for rule: CleaningRule) -> [String] {
    guard rule.type == .dir, let paths = rule.paths else { return [] }
    var result: [String] = []
    for p in paths {
        let base = expandingTilde(in: p.base)
        for d in p.dirs {
            if d == "*" {
                guard let contents = try? FileManager.default.contentsOfDirectory(atPath: base) else { continue }
                result.append(contentsOf: contents.map { (base as NSString).appendingPathComponent($0) })
            } else {
                result.append((base as NSString).appendingPathComponent(d))
            }
        }
    }
    return result
}

/// 递归计算目录占用字节（仅统计文件）
func directorySizeBytes(url: URL) -> Int64 {
    let fm = FileManager.default
    guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles]) else { return 0 }
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
    switch rule.type {
    case .dir:
        let urls = resolvePaths(for: rule).map { URL(fileURLWithPath: $0) }
        var total: Int64 = 0
        for url in urls {
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else { continue }
            total += directorySizeBytes(url: url)
        }
        return total
    case .command:
        return nil
    }
}

/// 执行单条规则清理
func cleanRule(_ rule: CleaningRule) -> (success: Bool, message: String) {
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
            return (true, "已删除 \(deleted) 项")
        }
        return (false, "部分失败：\(errors.prefix(2).joined(separator: " "))")
    case .command:
        guard let cmd = rule.command else { return (false, "缺少 command") }
        let r = ShellCommandRunner.run(cmd)
        if r.status == 0 {
            return (true, r.output.isEmpty ? "已执行" : r.output)
        }
        return (false, "退出码 \(r.status)：\(r.output)")
    }
}
