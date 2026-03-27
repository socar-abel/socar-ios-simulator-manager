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
            Image(systemName: "macbook.and.iphone")
                .font(.system(size: 64)).foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("SOCAR Simulator Manager")
                    .font(.largeTitle).fontWeight(.bold)

                Text("환영합니다! 시작하기 전에 간단한 준비가 필요해요.")
                    .font(.body).foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                stepRow(
                    number: 1,
                    title: "Xcode 설치",
                    description: "시뮬레이터를 사용하려면 Xcode가 필요해요.",
                    isDone: status.xcodeInstalled
                )
                stepRow(
                    number: 2,
                    title: "Xcode 한 번 실행",
                    description: "설치 후 Xcode를 한 번 열어서 초기 설정을 완료해주세요.",
                    isDone: status.xcodeInstalled && status.commandLineToolsInstalled
                )
            }
            .padding(20)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if !status.xcodeInstalled {
                VStack(spacing: 12) {
                    Button {
                        NSWorkspace.shared.open(
                            URL(string: "macappstore://apps.apple.com/app/xcode/id497799835")!
                        )
                    } label: {
                        Label("App Store에서 Xcode 설치", systemImage: "arrow.down.app")
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)

                    Button {
                        NSWorkspace.shared.open(
                            URL(string: "https://xcodereleases.com")!
                        )
                    } label: {
                        Label("App Store 버전이 호환되지 않는다면?", systemImage: "questionmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Text("설치가 완료되면 아래 버튼을 눌러주세요.")
                .font(.callout).foregroundStyle(.secondary)

            Button {
                onRetry()
            } label: {
                Label("준비 완료! 시작하기", systemImage: "checkmark.circle")
            }
            .buttonStyle(.bordered).controlSize(.large)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func stepRow(number: Int, title: String, description: String, isDone: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if isDone {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green).font(.title3)
            } else {
                ZStack {
                    Circle().fill(.blue.opacity(0.15)).frame(width: 28, height: 28)
                    Text("\(number)").font(.callout).fontWeight(.semibold).foregroundStyle(.blue)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(isDone ? .secondary : .primary)
                    .strikethrough(isDone)
                Text(description)
                    .font(.body).foregroundStyle(.secondary)
            }
        }
    }
}
