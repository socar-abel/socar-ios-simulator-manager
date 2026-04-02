import Foundation
import os.log

private let logger = Logger(subsystem: "com.socar.simulator-manager", category: "Environment")

public struct EnvironmentCheckUseCase: Sendable {

    private let repository: any EnvironmentRepositoryInterface

    public init(repository: any EnvironmentRepositoryInterface) {
        self.repository = repository
    }

    public func check() async -> EnvironmentStatus {
        logger.info("환경 확인 시작")

        async let xcodePath = repository.findXcodePath()
        async let xcodeVersion = repository.findXcodeVersion()
        async let devTools = repository.hasDeveloperTools()
        async let simctl = repository.isSimctlAvailable()
        async let runtimes = repository.findAvailableRuntimes()

        let path = await xcodePath
        let version = await xcodeVersion
        let hasDevTools = await devTools
        var simctlAvailable = await simctl
        let runtimeList = await runtimes

        // Xcode가 있지만 simctl이 안 되면 DEVELOPER_DIR 설정 후 재시도
        if path != nil && !simctlAvailable {
            setenv("DEVELOPER_DIR", path!, 1)
            simctlAvailable = await repository.isSimctlAvailable()
        }

        logger.info("Xcode: \(path ?? "nil"), devTools: \(hasDevTools), simctl: \(simctlAvailable), 런타임: \(runtimeList.count)개")

        return EnvironmentStatus(
            xcodeInstalled: path != nil,
            xcodePath: path,
            xcodeVersion: version,
            commandLineToolsInstalled: hasDevTools,
            simctlAvailable: simctlAvailable,
            availableRuntimes: runtimeList
        )
    }
}
