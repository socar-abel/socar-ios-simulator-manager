// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SOCARSimulatorManager",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SOCARSimulatorManager", targets: ["App"]),
    ],
    targets: [
        .target(name: "Core", path: "Sources/Core"),
        .target(name: "Domain", path: "Sources/Domain"),
        .target(
            name: "Data",
            dependencies: ["Core", "Domain"],
            path: "Sources/Data"
        ),
        .target(
            name: "Feature",
            dependencies: ["Core", "Domain"],
            path: "Sources/Feature"
        ),
        .executableTarget(
            name: "App",
            dependencies: ["Core", "Domain", "Data", "Feature"],
            path: "Sources/App",
            resources: [.process("Resources")]
        ),
    ]
)
