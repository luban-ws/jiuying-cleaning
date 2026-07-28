//
//  IPCCommandRouterTests.swift
//

import XCTest
@testable import CleanSpaceDesktopIPC

final class IPCCommandRouterTests: XCTestCase {
    func testKnownCommandsIncludesCoreSet() {
        XCTAssertTrue(IPCCommandRouter.knownCommands.contains("list_rules"))
        XCTAssertTrue(IPCCommandRouter.knownCommands.contains("list_volumes"))
        XCTAssertTrue(IPCCommandRouter.knownCommands.contains("metrics_snapshot"))
        XCTAssertTrue(IPCCommandRouter.knownCommands.contains("docker_refresh_start"))
        XCTAssertTrue(IPCCommandRouter.knownCommands.contains("scan_volume_start"))
    }

    func testUnknownCommandReturnsNotFound() {
        XCTAssertThrowsError(try IPCCommandRouter.handle(command: "nope", args: [:])) { error in
            XCTAssertEqual(error as? IPCError, .notFound("Unknown command: nope"))
        }
    }

    func testListRulesReturnsJSONEnvelope() throws {
        let data = try IPCCommandRouter.handle(command: "list_rules", args: ["scope": "rules"])
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let result = json?["result"] as? [[String: Any]]
        XCTAssertFalse(result?.isEmpty ?? true)
    }

    func testDeprecatedSyncCommandsReturnBadRequest() {
        let deprecated = [
            "scan_all_rules",
            "scan_rules",
            "clean_rules",
            "preview_rule",
            "scan_volume",
            "docker_disk_usage_parsed",
            "docker_run_preset",
        ]
        for command in deprecated {
            XCTAssertThrowsError(try IPCCommandRouter.handle(command: command, args: [:])) { error in
                guard let ipcError = error as? IPCError else {
                    XCTFail("expected IPCError for \(command)")
                    return
                }
                switch ipcError {
                case .badRequest:
                    break
                default:
                    XCTFail("expected badRequest for \(command)")
                }
            }
        }
    }

    func testScanAllRulesStartReturnsImmediately() throws {
        let data = try IPCCommandRouter.handle(command: "scan_all_rules_start", args: ["scope": "rules"])
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let result = json?["result"] as? [String: Any]
        XCTAssertNotNil(result?["jobId"])
        XCTAssertNotNil(result?["total"])
    }

    func testScanAllRulesPollReturnsStatus() throws {
        let startData = try IPCCommandRouter.handle(command: "scan_all_rules_start", args: ["scope": "rules"])
        let startJson = try JSONSerialization.jsonObject(with: startData) as? [String: Any]
        let start = startJson?["result"] as? [String: Any]
        let jobId = start?["jobId"] as? String
        XCTAssertNotNil(jobId)

        let pollData = try IPCCommandRouter.handle(command: "scan_all_rules_poll", args: ["job_id": jobId!])
        let pollJson = try JSONSerialization.jsonObject(with: pollData) as? [String: Any]
        let status = pollJson?["result"] as? [String: Any]
        XCTAssertNotNil(status?["state"])
    }

    func testPreviewRuleStartRequiresId() {
        XCTAssertThrowsError(try IPCCommandRouter.handle(command: "preview_rule_start", args: [:])) { error in
            XCTAssertEqual(error as? IPCError, .badRequest("rule_id required"))
        }
    }

    func testScanVolumeStartReturnsJobHandle() throws {
        let data = try IPCCommandRouter.handle(
            command: "scan_volume_start",
            args: ["volume_path": "/"]
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let result = json?["result"] as? [String: Any]
        XCTAssertNotNil(result?["jobId"])
    }

    func testDockerRefreshStartReturnsJobHandle() throws {
        let data = try IPCCommandRouter.handle(command: "docker_refresh_start", args: [:])
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let result = json?["result"] as? [String: Any]
        XCTAssertNotNil(result?["jobId"])
    }

    func testDockerPresetIdsReturnsArray() throws {
        let data = try IPCCommandRouter.handle(command: "docker_preset_ids", args: [:])
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let result = json?["result"] as? [String]
        XCTAssertFalse(result?.isEmpty ?? true)
    }
}
