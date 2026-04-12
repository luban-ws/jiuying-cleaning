//
//  CleaningRuleDecodingTests.swift
//  CleanSpaceTests
//
//  校验规则 JSON 与 CleaningRule 模型一致（不依赖 GUI）。
//

@testable import CleanSpaceKit
import XCTest

final class CleaningRuleDecodingTests: XCTestCase {
    /// 最小合法规则片段：dir + paths
    func testDecodeDirRule() throws {
        let json = """
        {
          "id": "trash",
          "category": "system",
          "name": "废纸篓",
          "type": "dir",
          "risk": "low",
          "paths": [
            { "base": "~/.Trash", "dirs": ["*"] }
          ]
        }
        """.data(using: .utf8)!
        let rule = try JSONDecoder().decode(CleaningRule.self, from: json)
        XCTAssertEqual(rule.id, "trash")
        XCTAssertEqual(rule.type, .dir)
        XCTAssertEqual(rule.riskLevel, .low)
        XCTAssertEqual(rule.paths?.count, 1)
        XCTAssertEqual(rule.paths?.first?.base, "~/.Trash")
    }

    /// 命令类规则可解码
    func testDecodeCommandRule() throws {
        let json = """
        {
          "id": "docker-prune",
          "category": "docker",
          "name": "清理",
          "type": "command",
          "command": "docker system prune -f",
          "estimate": "视镜像数量而定"
        }
        """.data(using: .utf8)!
        let rule = try JSONDecoder().decode(CleaningRule.self, from: json)
        XCTAssertEqual(rule.type, .command)
        XCTAssertEqual(rule.command, "docker system prune -f")
    }

    /// 缺省 risk 时视为 low
    func testRiskDefaultsToLow() throws {
        let json = """
        {
          "id": "x",
          "category": "custom",
          "name": "Test",
          "type": "dir",
          "paths": [{ "base": "/tmp", "dirs": ["*"] }]
        }
        """.data(using: .utf8)!
        let rule = try JSONDecoder().decode(CleaningRule.self, from: json)
        XCTAssertEqual(rule.riskLevel, .low)
    }
}
