//
//  SpaceVisualizationTests.swift
//  CleanSpaceTests
//
//  图表数据构建与格式化（无 UI）。
//

@testable import CleanSpaceKit
import XCTest

final class SpaceVisualizationTests: XCTestCase {
    func testSpaceFormatPercent() {
        XCTAssertEqual(SpaceFormat.percent(part: 25, of: 100), "25.0%")
        XCTAssertEqual(SpaceFormat.percent(part: 0, of: 100), "0.0%")
        XCTAssertEqual(SpaceFormat.percent(part: 1, of: 0), "—")
    }

    /// `disk.used_over_total_format` 由 .strings 控制顺序与分隔符；此处只校验占位符被替换。
    func testDiskUsedOverTotalFormatSubstitutesBothValues() {
        let line = L10n.Disk.usedOverTotal(usedFormatted: "10 B", totalFormatted: "20 B")
        XCTAssertTrue(line.contains("10 B"))
        XCTAssertTrue(line.contains("20 B"))
    }

    func testTopLevelBreakdownMergesTailAndUnaccounted() {
        let rows = [
            TopLevelFolderSize(name: "A", path: "/A", bytes: 100),
            TopLevelFolderSize(name: "B", path: "/B", bytes: 80),
            TopLevelFolderSize(name: "C", path: "/C", bytes: 60),
            TopLevelFolderSize(name: "D", path: "/D", bytes: 40),
            TopLevelFolderSize(name: "E", path: "/E", bytes: 30),
            TopLevelFolderSize(name: "F", path: "/F", bytes: 20),
            TopLevelFolderSize(name: "G", path: "/G", bytes: 10),
        ]
        let slices = SpaceChartSliceBuilder.topLevelBreakdownSlices(rows: rows, unaccountedBytes: 500, maxTopNames: 5)
        let ids = slices.map(\.id)
        // 断言稳定 `id`，避免随系统语言/本地化文案变化导致测试失败
        XCTAssertTrue(ids.contains("unaccounted"))
        XCTAssertTrue(ids.contains("other-toplevel"))
        XCTAssertEqual(slices.first { $0.id == "/A" }?.bytes, 100)
    }

    func testRulesCategorySlicesAggregates() throws {
        let json = """
        [{"id":"a","category":"browser","name":"X","type":"dir","paths":[{"base":"/tmp","dirs":["*"]}]}]
        """.data(using: .utf8)!
        let rules = try JSONDecoder().decode([CleaningRule].self, from: json)
        let sizes = ["a": Int64(42)]
        let slices = SpaceChartSliceBuilder.rulesCategorySlices(rules: rules, scannedSizes: sizes)
        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices.first?.bytes, 42)
    }
}
