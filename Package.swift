// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LunarCalendarApp",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "LunarCalendarApp",
            targets: ["LunarCalendarApp"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "LunarCalendarApp",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "LunarCalendarAppTests",
            dependencies: ["LunarCalendarApp"]
        ),
    ]
)
