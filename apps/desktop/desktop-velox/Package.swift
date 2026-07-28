// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CleanSpaceDesktop",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "CleanSpaceDesktop", targets: ["CleanSpaceDesktop"]),
        .library(name: "CleanSpaceDesktopIPC", targets: ["CleanSpaceDesktopIPC"]),
        .library(name: "CleanSpaceDesktopRuntime", targets: ["CleanSpaceDesktopRuntime"]),
        .library(name: "CleanSpaceKit", targets: ["CleanSpaceKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/velox-apps/velox", branch: "main"),
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
        .target(
            name: "CleanSpaceDesktopIPC",
            dependencies: [
                "CleanSpaceKit",
            ],
            path: "Sources/CleanSpaceDesktopIPC"
        ),
        .target(
            name: "CleanSpaceDesktopRuntime",
            dependencies: [
                .product(name: "VeloxRuntime", package: "velox"),
                .product(name: "VeloxRuntimeWry", package: "velox"),
                .target(name: "CleanSpaceDesktopIPC"),
            ],
            path: "Sources/CleanSpaceDesktopRuntime"
        ),
        .executableTarget(
            name: "CleanSpaceDesktop",
            dependencies: [
                .product(name: "VeloxRuntime", package: "velox"),
                .product(name: "VeloxRuntimeWry", package: "velox"),
                .target(name: "CleanSpaceDesktopRuntime"),
            ],
            path: "Sources/CleanSpaceDesktop",
            resources: [.process("Resources")],
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
            name: "CleanSpaceDesktopIPCTests",
            dependencies: ["CleanSpaceDesktopIPC"],
            path: "Tests/CleanSpaceDesktopIPCTests"
        ),
        .testTarget(
            name: "CleanSpaceDesktopRuntimeTests",
            dependencies: ["CleanSpaceDesktopRuntime"],
            path: "Tests/CleanSpaceDesktopRuntimeTests"
        ),
        .testTarget(
            name: "CleanSpaceKitTests",
            dependencies: ["CleanSpaceKit"],
            path: "Tests/CleanSpaceKitTests"
        ),
    ]
)
