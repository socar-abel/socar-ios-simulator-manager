import BuildDomainInterface

public final class BuildUseCaseComponent: BuildUseCaseDependency {
    public let buildRepository: any BuildRepositoryInterface
    public let fileRepository: any FileRepositoryInterface

    public init(
        buildRepository: any BuildRepositoryInterface,
        fileRepository: any FileRepositoryInterface
    ) {
        self.buildRepository = buildRepository
        self.fileRepository = fileRepository
    }
}
