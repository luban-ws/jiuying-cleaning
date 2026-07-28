//
//  DockerCommandHandler.swift
//  CleanSpaceDesktopIPC
//

import CleanSpaceKit
import Foundation

public enum DockerCommandHandler {
    public static let commands: Set<String> = [
        "docker_preset_ids",
        "docker_presets",
        "docker_refresh_start",
        "docker_refresh_poll",
        "docker_run_preset_start",
        "docker_run_preset_poll",
    ]

    public static func handle(command: String, args: [String: Any]) throws -> Data {
        if IPCCommandPolicy.isDeprecatedSync(command) {
            throw IPCError.badRequest(IPCCommandPolicy.deprecatedMessage(for: command))
        }

        switch command {
        case "docker_preset_ids":
            return try IPCEncoder.encode(CleanSpaceKitAPI.dockerPresetIds())
        case "docker_presets":
            return try IPCEncoder.encode(CleanSpaceKitAPI.dockerPresets())
        case "docker_refresh_start":
            return try IPCEncoder.encode(try DockerJobCoordinator.shared.startRefresh())
        case "docker_refresh_poll":
            let jobId = try IPCArgumentParser.requiredString(args["job_id"], field: "job_id")
            return try IPCEncoder.encode(try DockerJobCoordinator.shared.pollRefresh(jobId: jobId))
        case "docker_run_preset_start":
            let presetId = try IPCArgumentParser.requiredString(args["preset_id"], field: "preset_id")
            return try IPCEncoder.encode(try DockerJobCoordinator.shared.startPreset(presetId: presetId))
        case "docker_run_preset_poll":
            let jobId = try IPCArgumentParser.requiredString(args["job_id"], field: "job_id")
            return try IPCEncoder.encode(try DockerJobCoordinator.shared.pollPreset(jobId: jobId))
        default:
            throw IPCError.notFound("Unknown docker command: \(command)")
        }
    }
}
