//
//  VolumeDiskAccountingTests.swift
//  CleanSpaceTests
//
//  卷已用与顶层扫描合计的差额逻辑（不跑真实磁盘枚举）。
//

@testable import CleanSpaceKit
import XCTest

final class VolumeDiskAccountingTests: XCTestCase {
    func testVolumeUsedBytes() {
        XCTAssertNil(VolumeDiskAccounting.volumeUsedBytes(total: nil, free: 100))
        XCTAssertEqual(VolumeDiskAccounting.volumeUsedBytes(total: 500, free: 100), 400)
        XCTAssertEqual(VolumeDiskAccounting.volumeUsedBytes(total: 100, free: 100), 0)
    }

    func testUnaccountedUsedBytesNonNegative() {
        XCTAssertEqual(
            VolumeDiskAccounting.unaccountedUsedBytes(volumeUsed: 469_000_000_000, topLevelSum: 132_000_000_000),
            337_000_000_000
        )
        XCTAssertEqual(
            VolumeDiskAccounting.unaccountedUsedBytes(volumeUsed: 100, topLevelSum: 500),
            0
        )
    }

    func testTopLevelFoldersSum() {
        let rows = [
            TopLevelFolderSize(name: "A", path: "/A", bytes: 10),
            TopLevelFolderSize(name: "B", path: "/B", bytes: 20),
        ]
        XCTAssertEqual(VolumeDiskAccounting.topLevelFoldersSum(rows), 30)
    }

    /// 根下两项指向同一棵树时只保留规范路径更短的外层（不依赖本机 /var 解析行为）
    func testFilterCanonicalRootDuplicatesDropsNestedSymlink() throws {
        let fm = FileManager.default
        let base = fm.temporaryDirectory.appendingPathComponent("CleanSpaceVolumeTest-\(UUID().uuidString)")
        let outer = base.appendingPathComponent("outer")
        let innerDir = outer.appendingPathComponent("inner")
        try fm.createDirectory(at: innerDir, withIntermediateDirectories: true)
        let innerLink = base.appendingPathComponent("innerlink")
        try fm.createSymbolicLink(at: innerLink, withDestinationURL: innerDir)
        let noise = base.appendingPathComponent("sibling")
        try fm.createDirectory(at: noise, withIntermediateDirectories: true)

        let candidates: [(URL, String)] = [
            (innerLink, "innerlink"),
            (outer, "outer"),
            (noise, "sibling"),
        ]
        let filtered = VolumeDiskAccounting.filterCanonicalRootDuplicates(candidates: candidates)
        let names = Set(filtered.map(\.1))
        XCTAssertEqual(names, Set(["outer", "sibling"]), "innerlink 应视为 outer 下级的重复挂载点而去掉")
        try? fm.removeItem(at: base)
    }
}
