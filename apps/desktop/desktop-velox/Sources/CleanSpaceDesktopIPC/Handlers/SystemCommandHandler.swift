//
//  SystemCommandHandler.swift
//  CleanSpaceDesktopIPC
//

import CleanSpaceKit
import Foundation

public enum SystemCommandHandler {
    public static let commands: Set<String> = [
        "open_path",
        "fda_should_show_banner",
        "fda_open_settings",
        "fda_suppress_guidance",
    ]

    public static func handle(command: String, args: [String: Any]) throws -> Data {
        switch command {
        case "open_path":
            let path = try IPCArgumentParser.requiredString(args["path"], field: "path")
            return try IPCEncoder.encode(CleanSpaceKitAPI.openPath(path))
        case "fda_should_show_banner":
            let denied = IPCArgumentParser.stringArray(args["denied_paths"]) ?? []
            return try IPCEncoder.encode(CleanSpaceKitAPI.fdaShouldShowBanner(deniedPaths: denied))
        case "fda_open_settings":
            return try IPCEncoder.encode(CleanSpaceKitAPI.fdaOpenSettings())
        case "fda_suppress_guidance":
            return try IPCEncoder.encode(CleanSpaceKitAPI.fdaSuppressGuidance())
        default:
            throw IPCError.notFound("Unknown system command: \(command)")
        }
    }
}
