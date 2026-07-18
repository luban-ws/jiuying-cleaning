//
//  RulesTableModelTests.swift
//  CleanSpaceTests
//

import Foundation
import Testing
@testable import CleanSpaceKit

@Suite struct RulesTableModelTests {
    private func sampleRules() -> [CleaningRule] {
        [
            CleaningRule(
                id: "a-cache",
                category: CleaningRule.CategoryId.browser,
                name: "Safari caches",
                type: .dir,
                risk: .low
            ),
            CleaningRule(
                id: "b-mcp",
                category: CleaningRule.CategoryId.performance,
                name: "MCP leak",
                type: .command,
                risk: .medium
            ),
            CleaningRule(
                id: "c-system",
                category: CleaningRule.CategoryId.system,
                name: "System logs",
                type: .dir,
                risk: .high,
                warning: "Large folder"
            ),
        ]
    }

    @Test func filterBySearchMatchesNameAndWarning() {
        let rules = sampleRules()
        let byName = RulesTableModel.filtered(
            rules,
            filter: RulesTableFilter(searchText: "safari", category: nil)
        )
        #expect(byName.count == 1)
        #expect(byName[0].id == "a-cache")

        let byWarning = RulesTableModel.filtered(
            rules,
            filter: RulesTableFilter(searchText: "large", category: nil)
        )
        #expect(byWarning.count == 1)
        #expect(byWarning[0].id == "c-system")
    }

    @Test func filterByCategory() {
        let rules = sampleRules()
        let browserOnly = RulesTableModel.filtered(
            rules,
            filter: RulesTableFilter(searchText: "", category: CleaningRule.CategoryId.browser)
        )
        #expect(browserOnly.count == 1)
        #expect(browserOnly[0].category == CleaningRule.CategoryId.browser)
    }

    @Test func sortByImpactUsesScannedBytes() {
        let rules = sampleRules().filter { $0.type == .dir }
        let sizes: [String: Int64] = ["a-cache": 500, "c-system": 9_000]
        let sorted = RulesTableModel.sorted(
            rules,
            by: .impact,
            scannedSizes: sizes,
            scannedProcessCounts: [:]
        )
        #expect(sorted.map(\CleaningRule.id) == ["c-system", "a-cache"])
    }

    @Test func sortByRiskHighFirst() {
        let rules = sampleRules()
        let sorted = RulesTableModel.sorted(
            rules,
            by: .risk,
            scannedSizes: [:],
            scannedProcessCounts: [:]
        )
        #expect(sorted.first?.riskLevel == .high)
    }

    @Test("RulesUnifiedTableLayout minimumWidth behaves deterministically")
    func tableLayoutMinimumWidth() {
        let minW1 = RulesUnifiedTableLayout.minimumWidth(
            showCategoryColumn: true,
            showTypeColumn: true,
            compactItemColumn: false
        )
        // 52 (clean) + 180 (item) + 108 (size) + 56 (risk) + 72 (type) + 88 (category) + 24 = 580
        #expect(minW1 == 580)

        let minW2 = RulesUnifiedTableLayout.minimumWidth(
            showCategoryColumn: false,
            showTypeColumn: false,
            compactItemColumn: true
        )
        // 52 (clean) + 220 (compact item) + 108 (size) + 56 (risk) + 0 + 0 + 24 = 460
        #expect(minW2 == 460)
    }
}
