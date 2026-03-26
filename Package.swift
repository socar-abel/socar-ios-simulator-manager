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

        .target(
            name: "ShellKit",
            path: "Core/ShellKit/Sources/ShellKit"
        ),
        .target(
            name: "RoutingKit",
            path: "Core/RoutingKit/Sources/RoutingKit"
        ),
        .target(
            name: "DesignKit",
            path: "Core/DesignKit/Sources/DesignKit"
        ),

        // MARK: - Domain

        .target(
            name: "SimulatorDomainInterface",
            path: "Domain/SimulatorDomain/Sources/SimulatorDomainInterface"
        ),
        .target(
            name: "SimulatorDomain",
            dependencies: ["SimulatorDomainInterface", "ShellKit"],
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
            dependencies: ["ShellKit"],
            path: "Domain/EnvironmentDomain/Sources/EnvironmentDomain"
        ),

        // MARK: - Feature

        .target(
            name: "DeviceFeature",
            dependencies: [
                "SimulatorDomainInterface",
                "DesignKit",
                "RoutingKit",
            ],
            path: "Feature/DeviceFeature/Sources/DeviceFeature"
        ),
        .target(
            name: "BuildFeature",
            dependencies: [
                "BuildDomainInterface",
                "SimulatorDomainInterface",
                "DesignKit",
                "RoutingKit",
            ],
            path: "Feature/BuildFeature/Sources/BuildFeature"
        ),
        .target(
            name: "SettingsFeature",
            dependencies: [
                "BuildDomainInterface",
                "EnvironmentDomain",
                "DesignKit",
            ],
            path: "Feature/SettingsFeature/Sources/SettingsFeature"
        ),

        // MARK: - App

        .executableTarget(
            name: "App",
            dependencies: [
                "RoutingKit",
                "ShellKit",
                "DesignKit",
                "SimulatorDomain",
                "BuildDomain",
                "EnvironmentDomain",
                "DeviceFeature",
                "BuildFeature",
                "SettingsFeature",
            ],
            path: "App/Sources/App"
        ),
    ]
)
