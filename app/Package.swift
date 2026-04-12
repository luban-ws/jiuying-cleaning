// swift-tools-version: 5.9
// CleanSpace：SwiftPM 构建，仅需 Swift 工具链（无需打开 Xcode.app）。
import PackageDescription

let package = Package(
    name: "CleanSpace",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CleanSpace", targets: ["CleanSpace"]),
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
            path: "Sources/CleanSpace"
        ),
        .testTarget(
            name: "CleanSpaceTests",
            dependencies: ["CleanSpaceKit"],
            path: "Tests/CleanSpaceTests"
        ),
    ]
)
