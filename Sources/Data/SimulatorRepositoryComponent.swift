import Core

/// Component DI: ShellService를 주입받아 Repository의 Dependency를 충족
public final class SimulatorRepositoryComponent: SimulatorRepositoryDependency {

    public let shell: any ShellServiceInterface

    public init(shell: any ShellServiceInterface) {
        self.shell = shell
    }
}
