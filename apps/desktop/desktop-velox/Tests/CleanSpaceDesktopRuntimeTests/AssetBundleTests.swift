//
//  AssetBundleTests.swift
//

import XCTest
@testable import CleanSpaceDesktopRuntime

final class AssetBundleTests: XCTestCase {
    func testMimeTypeMapping() {
        let bundle = AssetBundle()
        XCTAssertEqual(bundle.mimeType(for: "index.html"), "text/html")
        XCTAssertEqual(bundle.mimeType(for: "app.js"), "application/javascript")
        XCTAssertEqual(bundle.mimeType(for: "styles.css"), "text/css")
        XCTAssertEqual(bundle.mimeType(for: "unknown.bin"), "application/octet-stream")
    }

    func testLoadAssetNormalizesLeadingSlash() {
        let bundle = AssetBundle()
        XCTAssertNil(bundle.loadAsset(path: "/missing-file-xyz.html"))
    }
}
