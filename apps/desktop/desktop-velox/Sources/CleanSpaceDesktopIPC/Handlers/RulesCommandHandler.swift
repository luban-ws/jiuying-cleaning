//
//  RulesCommandHandler.swift
//  CleanSpaceDesktopIPC
//

import CleanSpaceKit
import Foundation

public enum RulesCommandHandler {
    public static let commands: Set<String> = [
        "list_rules",
        "scan_all_rules_start",
        "scan_all_rules_poll",
        "preview_rule_start",
        "preview_rule_poll",
        "clean_rules_start",
        "clean_rules_poll",
    ]

    public static func handle(command: String, args: [String: Any]) throws -> Data {
        if IPCCommandPolicy.isDeprecatedSync(command) {
            throw IPCError.badRequest(IPCCommandPolicy.deprecatedMessage(for: command))
        }

        switch command {
        case "list_rules":
            return try IPCEncoder.encode(
                CleanSpaceKitAPI.listRules(scope: IPCArgumentParser.workspaceScope(from: args["scope"]))
            )
        case "scan_all_rules_start":
            let scope = IPCArgumentParser.workspaceScope(from: args["scope"])
            return try IPCEncoder.encode(try RulesScanCoordinator.shared.start(scope: scope))
        case "scan_all_rules_poll":
            let jobId = try IPCArgumentParser.requiredString(args["job_id"], field: "job_id")
            return try IPCEncoder.encode(try RulesScanCoordinator.shared.poll(jobId: jobId))
        case "preview_rule_start":
            let ruleId = try IPCArgumentParser.requiredString(args["rule_id"], field: "rule_id")
            return try IPCEncoder.encode(try RulePreviewCoordinator.shared.start(ruleId: ruleId))
        case "preview_rule_poll":
            let jobId = try IPCArgumentParser.requiredString(args["job_id"], field: "job_id")
            return try IPCEncoder.encode(try RulePreviewCoordinator.shared.poll(jobId: jobId))
        case "clean_rules_start":
            let ids = IPCArgumentParser.stringArray(args["rule_ids"]) ?? []
            return try IPCEncoder.encode(try RulesCleanCoordinator.shared.start(ruleIds: ids))
        case "clean_rules_poll":
            let jobId = try IPCArgumentParser.requiredString(args["job_id"], field: "job_id")
            return try IPCEncoder.encode(try RulesCleanCoordinator.shared.poll(jobId: jobId))
        default:
            throw IPCError.notFound("Unknown rules command: \(command)")
        }
    }
}
