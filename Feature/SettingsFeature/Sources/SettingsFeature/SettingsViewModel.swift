import Foundation
import EnvironmentDomain

@Observable
public final class SettingsViewModel {

    public private(set) var environmentStatus: EnvironmentStatus?

    private let environmentCheckUseCase: EnvironmentCheckUseCase

    public init(environmentCheckUseCase: EnvironmentCheckUseCase) {
        self.environmentCheckUseCase = environmentCheckUseCase
    }

    public func onAppear() async {
        environmentStatus = await environmentCheckUseCase.check()
    }
}
