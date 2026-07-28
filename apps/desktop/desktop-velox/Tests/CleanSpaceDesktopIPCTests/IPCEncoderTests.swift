//
//  IPCEncoderTests.swift
//

import CleanSpaceKit
import XCTest
@testable import CleanSpaceDesktopIPC

final class IPCEncoderTests: XCTestCase {
    func testEncodeWrapsResultKey() throws {
        struct Payload: Encodable, Equatable { let ok: Bool }
        let data = try IPCEncoder.encode(Payload(ok: true))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let result = json?["result"] as? [String: Bool]
        XCTAssertEqual(result?["ok"], true)
    }

    func testDecodeMetricsTicks() throws {
        let dict: [String: Any] = ["user": 1, "system": 2, "idle": 3, "nice": 4]
        let ticks = IPCEncoder.decode(MetricsCpuTicks.self, from: dict)
        XCTAssertEqual(ticks?.user, 1)
        XCTAssertEqual(ticks?.idle, 3)
    }
}
