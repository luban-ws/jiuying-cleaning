import AppKit
import CleanSpaceDesktopRuntime

DevelopmentAppIcon.install(
    Bundle.module.url(
        forResource: "AppIcon",
        withExtension: "icns"
    ).flatMap(NSImage.init(contentsOf:)),
    isAppBundle: Bundle.main.bundleURL.pathExtension == "app",
    devURL: ProcessInfo.processInfo.environment["VELOX_DEV_URL"]
)

DesktopApp.run()
