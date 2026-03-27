
/// Component DI: Repository를 주입받아 UseCase의 Dependency를 충족
public final class SimulatorUseCaseComponent<Repository: SimulatorRepositoryInterface>: SimulatorUseCaseDependency {

    public let repository: any SimulatorRepositoryInterface

    public init(repository: Repository) {
        self.repository = repository
    }
}
