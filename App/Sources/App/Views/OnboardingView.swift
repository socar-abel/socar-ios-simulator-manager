import SwiftUI
import EnvironmentDomain

struct OnboardingView: View {

    let status: EnvironmentStatus
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64)).foregroundStyle(.orange)

            Text("환경 설정이 필요합니다")
                .font(.largeTitle).fontWeight(.bold)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(status.issues, id: \.title) { issue in
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
            .padding()
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let version = status.xcodeVersion {
                Text("현재 설치된 Xcode: \(version)")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Button("다시 확인") { onRetry() }
                .buttonStyle(.borderedProminent).controlSize(.large)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
