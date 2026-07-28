import AppKit
import XCTest
@testable import CleanSpaceDesktopRuntime

@MainActor
final class DevelopmentAppIconTests: XCTestCase {
    func testBareVeloxDevelopmentInstallsDockIcon() {
        let application = NSApplication.shared
        let originalIcon = application.applicationIconImage
        let developmentIcon = NSImage(size: NSSize(width: 32, height: 32))
        defer {
            application.applicationIconImage = originalIcon
        }

        let installed = DevelopmentAppIcon.install(
            developmentIcon,
            isAppBundle: false,
            devURL: "http://localhost:5188",
            application: application
        )

        XCTAssertTrue(installed)
        XCTAssertEqual(application.applicationIconImage.size, developmentIcon.size)
    }

    func testAppBundleKeepsInfoPlistIconOwnership() {
        let application = NSApplication.shared
        let originalIcon = application.applicationIconImage
        let bundleIcon = NSImage(size: NSSize(width: 32, height: 32))
        let developmentIcon = NSImage(size: NSSize(width: 64, height: 64))
        application.applicationIconImage = bundleIcon
        defer {
            application.applicationIconImage = originalIcon
        }

        let installed = DevelopmentAppIcon.install(
            developmentIcon,
            isAppBundle: true,
            devURL: "http://localhost:5188",
            application: application
        )

        XCTAssertFalse(installed)
        XCTAssertEqual(application.applicationIconImage.size, bundleIcon.size)
    }
}
