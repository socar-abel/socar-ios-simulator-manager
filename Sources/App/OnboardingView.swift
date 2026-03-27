import SwiftUI
import Core
import Domain
import Data
import Feature

struct OnboardingView: View {

    let status: EnvironmentStatus
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64)).foregroundStyle(.orange)

            Text("환경 설정이 필요합니다")
                .font(.largeTitle).fontWeight(.bold)

            Text("이 앱은 Xcode의 시뮬레이터 도구를 사용합니다.\nXcode를 설치하고 한 번 실행하면 준비가 완료됩니다.")
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(status.issues, id: \.title) { issue in
                    issueRow(issue)
                }
            }
            .padding()
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let version = status.xcodeVersion {
                Text("현재 설치된 Xcode: \(version)")
                    .font(.caption).foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                if !status.xcodeInstalled {
                    Button {
                        NSWorkspace.shared.open(
                            URL(string: "macappstore://apps.apple.com/app/xcode/id497799835")!
                        )
                    } label: {
                        Label("App Store에서 Xcode 설치", systemImage: "arrow.down.app")
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                }

                Button("다시 확인") { onRetry() }
                    .buttonStyle(.bordered).controlSize(.large)
            }
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func issueRow(_ issue: EnvironmentIssue) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red).font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title).font(.headline)
                Text(issue.description).font(.body).foregroundStyle(.secondary)
            }
        }
    }
}
