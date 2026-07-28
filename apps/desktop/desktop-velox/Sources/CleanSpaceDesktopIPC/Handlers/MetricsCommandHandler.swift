//
//  MetricsCommandHandler.swift
//  CleanSpaceDesktopIPC
//

import CleanSpaceKit
import Foundation

public enum MetricsCommandHandler {
    public static let commands: Set<String> = ["metrics_snapshot"]

    private struct MetricsSnapshotPayload: Encodable {
        let snapshot: MetricsSnapshot
        let ticks: MetricsCpuTicks
        let network: MetricsNetworkCounters
    }

    public static func handle(command: String, args: [String: Any]) throws -> Data {
        guard command == "metrics_snapshot" else {
            throw IPCError.notFound("Unknown metrics command: \(command)")
        }
        let ticksJSON = args["previous_ticks"] as? [String: Any]
        let netJSON = args["previous_network"] as? [String: Any]
        let previousTicks = ticksJSON.flatMap { IPCEncoder.decode(MetricsCpuTicks.self, from: $0) }
        let previousNetwork = netJSON.flatMap { IPCEncoder.decode(MetricsNetworkCounters.self, from: $0) }
        if previousTicks != nil || previousNetwork != nil {
            let triple = CleanSpaceKitAPI.metricsSnapshot(
                previousTicks: previousTicks,
                previousNetwork: previousNetwork
            )
            return try IPCEncoder.encode(
                MetricsSnapshotPayload(snapshot: triple.snapshot, ticks: triple.ticks, network: triple.network)
            )
        }
        let triple = CleanSpaceKitAPI.metricsSnapshot(previousTicks: nil, previousNetwork: nil)
        return try IPCEncoder.encode(
            MetricsSnapshotPayload(snapshot: triple.snapshot, ticks: triple.ticks, network: triple.network)
        )
    }
}
