// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SOCARSimulatorManager",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SOCARSimulatorManager", targets: ["App"]),
    ],
    targets: [
        // MARK: - Core

        .target(name: "Shell", path: "Core/Shell/Sources/Shell"),
        .target(name: "Routing", path: "Core/Routing/Sources/Routing"),
        .target(name: "Design", path: "Core/Design/Sources/Design"),

        // MARK: - Domain (Interfaces + UseCases)

        .target(
            name: "SimulatorDomainInterface",
            path: "Domain/SimulatorDomain/Sources/SimulatorDomainInterface"
        ),
        .target(
            name: "SimulatorDomain",
            dependencies: ["SimulatorDomainInterface"],
            path: "Domain/SimulatorDomain/Sources/SimulatorDomain"
        ),
        .target(
            name: "BuildDomainInterface",
            path: "Domain/BuildDomain/Sources/BuildDomainInterface"
        ),
        .target(
            name: "BuildDomain",
            dependencies: ["BuildDomainInterface"],
            path: "Domain/BuildDomain/Sources/BuildDomain"
        ),
        .target(
            name: "EnvironmentDomain",
            path: "Domain/EnvironmentDomain/Sources/EnvironmentDomain"
        ),

        // MARK: - Data (Repository Implementations)

        .target(
            name: "SimulatorData",
            dependencies: ["SimulatorDomainInterface", "Shell"],
            path: "Data/SimulatorData/Sources/SimulatorData"
        ),
        .target(
            name: "BuildData",
            dependencies: ["BuildDomainInterface"],
            path: "Data/BuildData/Sources/BuildData"
        ),
        .target(
            name: "EnvironmentData",
            dependencies: ["EnvironmentDomain", "Shell"],
            path: "Data/EnvironmentData/Sources/EnvironmentData"
        ),

        // MARK: - Feature

        .target(
            name: "DeviceFeature",
            dependencies: ["SimulatorDomainInterface", "Design", "Routing"],
            path: "Feature/DeviceFeature/Sources/DeviceFeature"
        ),
        .target(
            name: "BuildFeature",
            dependencies: ["BuildDomainInterface", "SimulatorDomainInterface", "Design", "Routing"],
            path: "Feature/BuildFeature/Sources/BuildFeature"
        ),
        .target(
            name: "SettingsFeature",
            dependencies: ["EnvironmentDomain", "Design"],
            path: "Feature/SettingsFeature/Sources/SettingsFeature"
        ),
        .target(
            name: "IOSVersionFeature",
            dependencies: ["SimulatorDomainInterface", "Design"],
            path: "Feature/IOSVersionFeature/Sources/IOSVersionFeature"
        ),

        // MARK: - App

        .executableTarget(
            name: "App",
            dependencies: [
                "Routing", "Shell", "Design",
                "SimulatorDomain", "SimulatorData",
                "BuildDomain", "BuildData",
                "EnvironmentDomain", "EnvironmentData",
                "DeviceFeature", "BuildFeature", "SettingsFeature", "IOSVersionFeature",
            ],
            path: "App/Sources/App"
        ),
    ]
)
