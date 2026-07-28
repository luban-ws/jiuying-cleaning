// swift-tools-version: 6.0
// CleanSpace：SwiftPM 构建，仅需 Swift 工具链（无需打开 Xcode.app）。
import PackageDescription

let package = Package(
    name: "CleanSpace",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "CleanSpace", targets: ["CleanSpace"]),
        .library(name: "CleanSpaceKit", targets: ["CleanSpaceKit"]),
    ],
    targets: [
        .target(
            name: "CleanSpaceKit",
            dependencies: [],
            path: "Sources/CleanSpaceKit",
            resources: [
                .process("Resources"),
            ]
        ),
        .executableTarget(
            name: "CleanSpace",
            dependencies: ["CleanSpaceKit"],
            path: "Sources/CleanSpace",
            // 将 Support/Info.plist 嵌入 Mach-O，使 `swift run` 下也有 CFBundleIdentifier；否则 UNUserNotificationCenter 会 abort。
            linkerSettings: [
                .unsafeFlags(
                    [
                        "-Xlinker", "-sectcreate",
                        "-Xlinker", "__TEXT",
                        "-Xlinker", "__info_plist",
                        "-Xlinker", "Support/Info.plist",
                    ],
                    .when(platforms: [.macOS])
                ),
            ]
        ),
        .testTarget(
            name: "CleanSpaceTests",
            dependencies: ["CleanSpaceKit"],
            path: "Tests/CleanSpaceTests"
        ),
    ]
)
