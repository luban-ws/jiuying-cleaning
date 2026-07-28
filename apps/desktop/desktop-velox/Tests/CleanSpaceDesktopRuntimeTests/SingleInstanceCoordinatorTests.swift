import Foundation
import XCTest
@testable import CleanSpaceDesktopRuntime

@MainActor
final class SingleInstanceCoordinatorTests: XCTestCase {
    func testSecondCoordinatorCannotBecomePrimaryAndRequestsWake() throws {
        let lockURL = makeLockURL()
        let primaryChannel = TestWakeChannel()
        let secondaryChannel = TestWakeChannel()
        let primary = SingleInstanceCoordinator(lockURL: lockURL, wakeChannel: primaryChannel)
        let secondary = SingleInstanceCoordinator(lockURL: lockURL, wakeChannel: secondaryChannel)

        XCTAssertEqual(try primary.start(onWake: {}), .primary)
        XCTAssertEqual(try secondary.start(onWake: {}), .secondary)
        XCTAssertEqual(primaryChannel.sendCount, 0)
        XCTAssertEqual(secondaryChannel.sendCount, 1)
    }

    func testStoppingPrimaryAllowsNextCoordinatorToBecomePrimary() throws {
        let lockURL = makeLockURL()
        let first = SingleInstanceCoordinator(lockURL: lockURL, wakeChannel: TestWakeChannel())
        let next = SingleInstanceCoordinator(lockURL: lockURL, wakeChannel: TestWakeChannel())

        XCTAssertEqual(try first.start(onWake: {}), .primary)
        first.stop()

        XCTAssertEqual(try next.start(onWake: {}), .primary)
    }

    func testPrimaryChannelInvokesWakeHandler() throws {
        let channel = TestWakeChannel()
        let coordinator = SingleInstanceCoordinator(lockURL: makeLockURL(), wakeChannel: channel)
        var wakeCount = 0

        XCTAssertEqual(try coordinator.start(onWake: { wakeCount += 1 }), .primary)
        channel.receiveWakeRequest()

        XCTAssertEqual(wakeCount, 1)
    }

    func testDistributedChannelDeliversWakeRequest() async {
        let notificationName = Notification.Name(
            "me.systembug.cleaning.test.\(UUID().uuidString)"
        )
        let channel = DistributedSingleInstanceWakeChannel(notificationName: notificationName)
        let received = expectation(description: "收到第二实例唤醒请求")

        channel.startObserving {
            received.fulfill()
        }
        channel.sendWakeRequest()

        await fulfillment(of: [received], timeout: 2)
        channel.stopObserving()
    }

    private func makeLockURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("instance.lock")
    }
}

private final class TestWakeChannel: SingleInstanceWakeChannel {
    private var handler: (() -> Void)?
    private(set) var sendCount = 0

    func startObserving(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    func sendWakeRequest() {
        sendCount += 1
    }

    func stopObserving() {
        handler = nil
    }

    func receiveWakeRequest() {
        handler?()
    }
}
