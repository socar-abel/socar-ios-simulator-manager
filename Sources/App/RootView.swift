import SwiftUI
import Core
import Domain
import Data
import Feature

struct RootView: View {

    @State var coordinator: AppContainer

    var body: some View {
        Group {
            if coordinator.isCheckingEnvironment {
                loadingView
            } else if let status = coordinator.environmentStatus, !status.isReady {
                OnboardingView(status: status) {
                    Task { await coordinator.retryEnvironmentCheck() }
                }
            } else if coordinator.isReady {
                MainView(coordinator: coordinator)
            }
        }
        .textSelection(.enabled)
        .frame(minWidth: 800, minHeight: 500)
        .task { await coordinator.start() }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.5)
            Text("환경을 확인하는 중...")
                .font(.headline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
