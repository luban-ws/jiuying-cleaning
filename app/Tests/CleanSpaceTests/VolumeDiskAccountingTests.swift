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

    /// `/var` 与 `/private` 同时出现在根列表时，规范路径去重后只保留外层
    func testFilterCanonicalRootDuplicatesDropsNestedSymlink() {
        let privateURL = URL(fileURLWithPath: "/private")
        let varURL = URL(fileURLWithPath: "/var")
        let apps = URL(fileURLWithPath: "/Applications")
        let candidates: [(URL, String)] = [
            (varURL, "var"),
            (privateURL, "private"),
            (apps, "Applications"),
        ]
        let filtered = VolumeDiskAccounting.filterCanonicalRootDuplicates(candidates: candidates)
        let names = Set(filtered.map(\.1))
        XCTAssertTrue(names.contains("Applications"))
        XCTAssertTrue(names.contains("private") || names.contains("var"))
        XCTAssertEqual(filtered.count, 2, "var 与 private 应合并为一条")
    }
}
