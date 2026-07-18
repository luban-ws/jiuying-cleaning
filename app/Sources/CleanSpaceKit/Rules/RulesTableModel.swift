//
//  RulesTableModel.swift
//  CleanSpaceKit
//
//  规则列表筛选与排序（纯函数，便于单测）。
//

import Foundation

/// 表格列排序键。
enum RulesTableSortKey: String, CaseIterable, Identifiable {
    case name
    case category
    case impact
    case risk

    var id: String { rawValue }
}

/// 列表筛选条件。
struct RulesTableFilter: Equatable {
    var searchText: String = ""
    /// `nil` 表示全部分类。
    var category: String?
}

enum RulesTableModel {
    /// 按搜索词与分类过滤规则。
    static func filtered(_ rules: [CleaningRule], filter: RulesTableFilter) -> [CleaningRule] {
        let query = filter.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return rules.filter { rule in
            let categoryOK = filter.category.map { rule.category == $0 } ?? true
            guard categoryOK else { return false }
            guard !query.isEmpty else { return true }
            if rule.name.localizedCaseInsensitiveContains(query) { return true }
            if let w = rule.warning, w.localizedCaseInsensitiveContains(query) { return true }
            if rule.id.localizedCaseInsensitiveContains(query) { return true }
            return CleaningRule.categoryDisplayName(rule.category)
                .localizedCaseInsensitiveContains(query)
        }
    }

    /// 排序：impact 使用扫描字节或进程数；risk 高 → 低。
    static func sorted(
        _ rules: [CleaningRule],
        by key: RulesTableSortKey,
        scannedSizes: [String: Int64],
        scannedProcessCounts: [String: Int]
    ) -> [CleaningRule] {
        rules.sorted { lhs, rhs in
            switch key {
            case .name:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .category:
                let lc = lhs.category.localizedCaseInsensitiveCompare(rhs.category)
                if lc != .orderedSame { return lc == .orderedAscending }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .impact:
                let li = impactValue(lhs, sizes: scannedSizes, processCounts: scannedProcessCounts)
                let ri = impactValue(rhs, sizes: scannedSizes, processCounts: scannedProcessCounts)
                if li != ri { return li > ri }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .risk:
                let lr = riskRank(lhs.riskLevel)
                let rr = riskRank(rhs.riskLevel)
                if lr != rr { return lr > rr }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
    }

    /// 当前筛选结果中出现的分类（保持 CategoryId.ordered 顺序）。
    static func distinctCategories(in rules: [CleaningRule]) -> [String] {
        let present = Set(rules.map(\.category))
        return CleaningRule.CategoryId.ordered.filter { present.contains($0) }
            + present.subtracting(Set(CleaningRule.CategoryId.ordered)).sorted()
    }

    private static func impactValue(
        _ rule: CleaningRule,
        sizes: [String: Int64],
        processCounts: [String: Int]
    ) -> Int64 {
        if rule.displaysScannedProcessCount {
            return Int64(processCounts[rule.id] ?? 0)
        }
        return sizes[rule.id] ?? 0
    }

    private static func riskRank(_ risk: CleaningRuleRisk) -> Int {
        switch risk {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
}
