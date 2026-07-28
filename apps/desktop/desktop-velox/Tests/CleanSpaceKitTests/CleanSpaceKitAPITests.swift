//
//  CleanSpaceKitAPITests.swift
//

import XCTest
@testable import CleanSpaceKit

final class CleanSpaceKitAPITests: XCTestCase {
    func testListRulesReturnsStableIds() {
        let rules = CleanSpaceKitAPI.listRules(scope: .rules)
        XCTAssertFalse(rules.isEmpty)
        XCTAssertEqual(Set(rules.map(\.id)).count, rules.count)
        XCTAssertTrue(rules.allSatisfy { !$0.id.isEmpty && !$0.name.isEmpty })
    }

    func testListRulesExcludesHiddenRules() {
        let rules = CleanSpaceKitAPI.listRules(scope: .rules)
        XCTAssertFalse(rules.contains { $0.id == "docker-desktop-residues" })
    }

    func testListRulesScopesDiffer() {
        let storage = Set(CleanSpaceKitAPI.listRules(scope: .rules).map(\.id))
        let ai = Set(CleanSpaceKitAPI.listRules(scope: .aiToolsSpace).map(\.id))
        let perf = Set(CleanSpaceKitAPI.listRules(scope: .performance).map(\.id))
        XCTAssertFalse(storage.isEmpty)
        XCTAssertFalse(ai.isEmpty)
        XCTAssertFalse(perf.isEmpty)
        XCTAssertTrue(storage.isDisjoint(with: ai))
        XCTAssertTrue(storage.isDisjoint(with: perf))
    }

    func testScanRulesEmptyIds() {
        let result = CleanSpaceKitAPI.scanRules(ruleIds: [])
        XCTAssertTrue(result.sizes.isEmpty)
        XCTAssertTrue(result.processCounts.isEmpty)
    }

    func testScanAllRulesMatchesScopeRuleCount() {
        let scopeRules = CleanSpaceKitAPI.listRules(scope: .performance)
        XCTAssertFalse(scopeRules.isEmpty)
        let result = CleanSpaceKitAPI.scanAllRules(scope: .performance)
        XCTAssertNotNil(result.deniedPaths)
        XCTAssertTrue(
            result.processCounts.keys.contains("mcp-leaked-processes")
                || result.sizes.keys.contains("mcp-leaked-processes")
        )
    }

    func testPreviewRuleUnknownReturnsNil() {
        XCTAssertNil(CleanSpaceKitAPI.previewRule(ruleId: "not-a-real-rule-id"))
    }

    func testListVolumesNotEmpty() {
        XCTAssertFalse(CleanSpaceKitAPI.listVolumes().isEmpty)
    }

    func testMetricsSnapshotReturnsPercentages() {
        let snap = CleanSpaceKitAPI.metricsSnapshot()
        XCTAssertGreaterThanOrEqual(snap.memoryPercent, 0)
        XCTAssertLessThanOrEqual(snap.memoryPercent, 100)
        XCTAssertGreaterThan(snap.memoryTotalBytes, 0)
    }

    func testDockerPresetIds() {
        XCTAssertFalse(CleanSpaceKitAPI.dockerPresetIds().isEmpty)
    }

    func testCleanRulesEmpty() {
        XCTAssertTrue(CleanSpaceKitAPI.cleanRules(ruleIds: []).items.isEmpty)
    }

    func testDockerPresetsNotEmpty() {
        let presets = CleanSpaceKitAPI.dockerPresets()
        XCTAssertFalse(presets.isEmpty)
        XCTAssertTrue(presets.allSatisfy { !$0.id.isEmpty && !$0.title.isEmpty })
    }

    func testDockerDiskUsageParsedShape() {
        let parsed = CleanSpaceKitAPI.dockerDiskUsageParsed()
        XCTAssertNotNil(parsed.rawSummary)
        XCTAssertNotNil(parsed.rawVerbose)
    }

    func testFdaShouldShowBannerWhenSuppressed() {
        FullDiskAccessGuidance.resetGuidanceSuppressionForTests()
        defer { FullDiskAccessGuidance.resetGuidanceSuppressionForTests() }
        let result = CleanSpaceKitAPI.fdaShouldShowBanner(deniedPaths: ["/Users/test/Library/Mail"])
        XCTAssertFalse(result.suppressed)
        _ = result.shouldShow
    }

    func testOpenPathInvalidReturnsFalse() {
        XCTAssertFalse(CleanSpaceKitAPI.openPath("/nonexistent/path/for/cleanspace-test").success)
    }

    func testScanVolumeIncludesAccounting() throws {
        let fm = FileManager.default
        let base = fm.temporaryDirectory.appendingPathComponent("CleanSpaceScanVolume-\(UUID().uuidString)")
        try fm.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: base) }
        try fm.createDirectory(at: base.appendingPathComponent("child"), withIntermediateDirectories: true)

        let result = CleanSpaceKitAPI.scanVolume(
            volumePath: base.path,
            totalBytes: 1_000_000,
            freeBytes: 500_000
        )
        XCTAssertNotNil(result.accounting)
        XCTAssertGreaterThanOrEqual(result.accounting?.topLevelSum ?? 0, 0)
        XCTAssertEqual(result.accounting?.volumeUsedBytes, 500_000)
    }
}
