//
//  DockerSystemDfParsing.swift
//  CleanSpaceKit
//
//  将 `docker system df` / `docker system df -v` 的列对齐文本解析为表格数据，供 SwiftUI 展示。
//

import Foundation

// MARK: - 模型

/// 摘要表一行（TYPE / TOTAL / ACTIVE / SIZE / RECLAIMABLE）。
struct DockerDfSummaryRow: Identifiable, Equatable {
    var id: String { resourceType }
    let resourceType: String
    let total: String
    let active: String
    let size: String
    let reclaimable: String
}

/// 详细区块（如 Images space usage 下的子表）。
struct DockerDfDetailSection: Identifiable, Equatable {
    let id: String
    /// 展示用标题（已本地化或短键）
    let title: String
    /// 表头前的简短行（如 Build cache 的 `0B` 总量提示）
    let prefixLines: [String]
    let columnTitles: [String]
    let rows: [[String]]
    /// 与表头列数不一致的数据行
    let orphanLines: [String]

    /// 是否值得单独渲染一块（避免空白 Docker 区块占位）。
    var hasRenderableContent: Bool {
        !prefixLines.isEmpty || !columnTitles.isEmpty || !orphanLines.isEmpty
    }
}

/// UI 层使用的完整报告（由两次 docker 调用拼出）。
struct DockerDfReport: Equatable {
    var summaryRows: [DockerDfSummaryRow]
    var detailSections: [DockerDfDetailSection]
    /// 摘要命令失败（verbose 仍可能有内容）
    var summaryCommandFailed: Bool
    /// 详细命令失败
    var verboseCommandFailed: Bool
    /// 完全失败时的单条说明（含退出码）
    var fatalErrorText: String?
    var rawSummary: String
    var rawVerbose: String

    static let empty = DockerDfReport(
        summaryRows: [],
        detailSections: [],
        summaryCommandFailed: false,
        verboseCommandFailed: false,
        fatalErrorText: nil,
        rawSummary: "",
        rawVerbose: ""
    )
}

// MARK: - 解析（纯函数，便于单测）

enum DockerSystemDfParser {
    /// 按「两个及以上空白」分列，与 docker CLI 表格一致。
    static func splitColumns(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        guard let re = try? NSRegularExpression(pattern: #"\s{2,}"#, options: []) else {
            return [trimmed]
        }
        let ns = trimmed as NSString
        let full = NSRange(location: 0, length: ns.length)
        var parts: [String] = []
        var lastEnd = 0
        re.enumerateMatches(in: trimmed, options: [], range: full) { match, _, _ in
            guard let match else { return }
            if match.range.location > lastEnd {
                let r = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let piece = ns.substring(with: r).trimmingCharacters(in: .whitespacesAndNewlines)
                if !piece.isEmpty { parts.append(piece) }
            }
            lastEnd = match.range.location + match.range.length
        }
        if lastEnd < ns.length {
            let tail = ns.substring(from: lastEnd).trimmingCharacters(in: .whitespacesAndNewlines)
            if !tail.isEmpty { parts.append(tail) }
        }
        return parts
    }

    private static let summaryTypePrefixes: [String] = ["Local Volumes", "Build Cache", "Containers", "Images"]

    static func parseSummary(_ text: String) -> [DockerDfSummaryRow] {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        guard let headerIdx = lines.firstIndex(where: isSummaryHeaderLine) else { return [] }
        var rows: [DockerDfSummaryRow] = []
        for line in lines.dropFirst(headerIdx + 1) {
            if line.isEmpty { break }
            guard let row = parseSummaryDataRow(line) else { break }
            rows.append(row)
        }
        return rows
    }

    private static func isSummaryHeaderLine(_ line: String) -> Bool {
        let u = line.uppercased()
        return u.contains("TYPE") && u.contains("TOTAL") && u.contains("ACTIVE")
            && u.contains("SIZE") && u.contains("RECLAIMABLE")
    }

    private static func parseSummaryDataRow(_ line: String) -> DockerDfSummaryRow? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let prefix = summaryTypePrefixes.first(where: { trimmed.hasPrefix($0) }) else { return nil }
        let rest = String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        let cols = splitColumns(rest)
        guard cols.count >= 4 else { return nil }
        let reclaimable = cols.dropFirst(3).joined(separator: "  ")
        return DockerDfSummaryRow(
            resourceType: prefix,
            total: cols[0],
            active: cols[1],
            size: cols[2],
            reclaimable: reclaimable
        )
    }

    // 修复：上面 parseSummaryDataLine 递归错误，应删除重复命名
    // Swift 会报错 - I need to remove the erroneous private func parseSummaryDataLine that calls itself

    static func parseVerboseSections(_ text: String, titleForKey: (String) -> String) -> [DockerDfDetailSection] {
        let lines = text.components(separatedBy: .newlines)
        var sections: [DockerDfDetailSection] = []
        var i = 0
        while i < lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if let kind = matchSectionStart(trimmed) {
                switch kind {
                case let .standard(key):
                    i += 1
                    let body = collectBody(lines: lines, start: &i)
                    sections.append(parseDetailSection(idKey: key, title: titleForKey(key), rawLines: body))
                    continue
                case let .buildCache(remainder):
                    var body: [String] = []
                    if !remainder.isEmpty {
                        body.append(remainder)
                    }
                    i += 1
                    while i < lines.count {
                        let t2 = lines[i].trimmingCharacters(in: .whitespaces)
                        if matchSectionStart(t2) != nil { break }
                        body.append(lines[i])
                        i += 1
                    }
                    sections.append(parseDetailSection(idKey: "build_cache", title: titleForKey("build_cache"), rawLines: body))
                    continue
                }
            } else {
                i += 1
            }
        }
        return sections
    }

    private enum SectionStart: Equatable {
        case standard(key: String)
        case buildCache(remainder: String)
    }

    private static func matchSectionStart(_ line: String) -> SectionStart? {
        if line == "Images space usage:" { return .standard(key: "images") }
        if line == "Containers space usage:" { return .standard(key: "containers") }
        if line == "Local Volumes space usage:" { return .standard(key: "volumes") }
        if line.hasPrefix("Build cache usage:") {
            let rest = String(line.dropFirst("Build cache usage:".count)).trimmingCharacters(in: .whitespaces)
            return .buildCache(remainder: rest)
        }
        return nil
    }

    private static func collectBody(lines: [String], start i: inout Int) -> [String] {
        var body: [String] = []
        while i < lines.count {
            let t = lines[i].trimmingCharacters(in: .whitespaces)
            if matchSectionStart(t) != nil { break }
            body.append(lines[i])
            i += 1
        }
        return body
    }

    static func parseDetailSection(idKey: String, title: String, rawLines: [String]) -> DockerDfDetailSection {
        let trimmed = rawLines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var nonEmpty = trimmed.filter { !$0.isEmpty }
        guard !nonEmpty.isEmpty else {
            return DockerDfDetailSection(id: idKey, title: title, prefixLines: [], columnTitles: [], rows: [], orphanLines: [])
        }

        /// `Build cache usage: 0B` 等会先出现单列行，再跟真正的表头。
        var prefixLines: [String] = []
        while let first = nonEmpty.first {
            let cols = splitColumns(first)
            if cols.count >= 2 { break }
            prefixLines.append(first)
            nonEmpty = Array(nonEmpty.dropFirst())
        }

        guard !nonEmpty.isEmpty else {
            return DockerDfDetailSection(id: idKey, title: title, prefixLines: prefixLines, columnTitles: [], rows: [], orphanLines: [])
        }

        if nonEmpty.count == 1, splitColumns(nonEmpty[0]).count <= 1 {
            return DockerDfDetailSection(
                id: idKey,
                title: title,
                prefixLines: prefixLines,
                columnTitles: [],
                rows: [],
                orphanLines: nonEmpty
            )
        }

        let headerCols = splitColumns(nonEmpty[0])
        guard headerCols.count >= 2 else {
            return DockerDfDetailSection(
                id: idKey,
                title: title,
                prefixLines: prefixLines,
                columnTitles: [],
                rows: [],
                orphanLines: nonEmpty
            )
        }

        var rows: [[String]] = []
        var orphans: [String] = []
        for line in nonEmpty.dropFirst() {
            let cols = splitColumns(line)
            if cols.count == headerCols.count {
                rows.append(cols)
            } else if cols.isEmpty {
                continue
            } else {
                orphans.append(line)
            }
        }

        return DockerDfDetailSection(
            id: idKey,
            title: title,
            prefixLines: prefixLines,
            columnTitles: headerCols,
            rows: rows,
            orphanLines: orphans
        )
    }
}
