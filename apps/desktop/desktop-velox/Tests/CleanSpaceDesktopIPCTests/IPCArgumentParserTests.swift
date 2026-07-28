//
//  IPCArgumentParserTests.swift
//

import XCTest
@testable import CleanSpaceDesktopIPC

final class IPCArgumentParserTests: XCTestCase {
    func testWorkspaceScopeDefaultsToRules() {
        XCTAssertEqual(IPCArgumentParser.workspaceScope(from: nil), .rules)
        XCTAssertEqual(IPCArgumentParser.workspaceScope(from: "invalid"), .rules)
    }

    func testWorkspaceScopeParsesPerformance() {
        XCTAssertEqual(IPCArgumentParser.workspaceScope(from: "performance"), .performance)
    }

    func testRequiredStringRejectsEmpty() {
        XCTAssertThrowsError(try IPCArgumentParser.requiredString("", field: "rule_id")) { error in
            XCTAssertEqual(error as? IPCError, .badRequest("rule_id required"))
        }
    }

    func testStringArrayPassthrough() {
        XCTAssertEqual(IPCArgumentParser.stringArray(["a", "b"]), ["a", "b"])
        XCTAssertNil(IPCArgumentParser.stringArray(42))
    }
}
