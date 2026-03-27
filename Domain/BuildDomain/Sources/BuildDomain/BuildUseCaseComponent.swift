import BuildDomainInterface

public final class BuildUseCaseComponent: BuildUseCaseDependency {
    public let fileRepository: any FileRepositoryInterface

    public init(fileRepository: any FileRepositoryInterface) {
        self.fileRepository = fileRepository
    }
}
