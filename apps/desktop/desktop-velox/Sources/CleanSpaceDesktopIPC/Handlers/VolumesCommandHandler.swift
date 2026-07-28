//
//  VolumesCommandHandler.swift
//  CleanSpaceDesktopIPC
//

import CleanSpaceKit
import Foundation

public enum VolumesCommandHandler {
    public static let commands: Set<String> = [
        "list_volumes",
        "scan_volume_start",
        "scan_volume_poll",
    ]

    public static func handle(command: String, args: [String: Any]) throws -> Data {
        if IPCCommandPolicy.isDeprecatedSync(command) {
            throw IPCError.badRequest(IPCCommandPolicy.deprecatedMessage(for: command))
        }

        switch command {
        case "list_volumes":
            return try IPCEncoder.encode(CleanSpaceKitAPI.listVolumes())
        case "scan_volume_start":
            let path = try IPCArgumentParser.requiredString(args["volume_path"], field: "volume_path")
            let total = IPCArgumentParser.optionalInt64(args["total_bytes"])
            let free = IPCArgumentParser.optionalInt64(args["free_bytes"])
            return try IPCEncoder.encode(
                try VolumeScanCoordinator.shared.start(volumePath: path, totalBytes: total, freeBytes: free)
            )
        case "scan_volume_poll":
            let jobId = try IPCArgumentParser.requiredString(args["job_id"], field: "job_id")
            return try IPCEncoder.encode(try VolumeScanCoordinator.shared.poll(jobId: jobId))
        default:
            throw IPCError.notFound("Unknown volumes command: \(command)")
        }
    }
}
