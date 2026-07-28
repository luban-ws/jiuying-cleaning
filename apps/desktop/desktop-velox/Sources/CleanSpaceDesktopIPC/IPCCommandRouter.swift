//
//  IPCCommandRouter.swift
//  CleanSpaceDesktopIPC
//

import Foundation

public enum IPCCommandRouter {
    public static let knownCommands: Set<String> =
        RulesCommandHandler.commands
        .union(VolumesCommandHandler.commands)
        .union(MetricsCommandHandler.commands)
        .union(DockerCommandHandler.commands)
        .union(SystemCommandHandler.commands)

    public static func handle(command: String, args: [String: Any]) throws -> Data {
        if IPCCommandPolicy.isDeprecatedSync(command) {
            throw IPCError.badRequest(IPCCommandPolicy.deprecatedMessage(for: command))
        }
        if RulesCommandHandler.commands.contains(command) {
            return try RulesCommandHandler.handle(command: command, args: args)
        }
        if VolumesCommandHandler.commands.contains(command) {
            return try VolumesCommandHandler.handle(command: command, args: args)
        }
        if MetricsCommandHandler.commands.contains(command) {
            return try MetricsCommandHandler.handle(command: command, args: args)
        }
        if DockerCommandHandler.commands.contains(command) {
            return try DockerCommandHandler.handle(command: command, args: args)
        }
        if SystemCommandHandler.commands.contains(command) {
            return try SystemCommandHandler.handle(command: command, args: args)
        }
        throw IPCError.notFound("Unknown command: \(command)")
    }
}
