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
        async let runtimes = repository.findAvailableRuntimes()

        let path = await xcodePath
        let version = await xcodeVersion
        let runtimeList = await runtimes

        logger.info("Xcode: \(path ?? "nil"), 런타임: \(runtimeList.count)개")

        return EnvironmentStatus(
            xcodeInstalled: path != nil,
            xcodePath: path,
            xcodeVersion: version,
            commandLineToolsInstalled: path != nil,
            availableRuntimes: runtimeList
        )
    }
}
