import SwiftUI
import Core
import Domain
import Data
import Feature

struct OnboardingView: View {

    let status: EnvironmentStatus
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 48) {
            Image(systemName: "macbook.and.iphone")
                .font(.system(size: 96)).foregroundStyle(.blue)

            VStack(spacing: 12) {
                Text("SOCAR Simulator Manager")
                    .font(.system(size: 36, weight: .bold))

                Text("환영합니다! 시작하기 전에 간단한 준비가 필요해요.")
                    .font(.title3).foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 24) {
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
            .padding(28)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if !status.xcodeInstalled {
                VStack(spacing: 16) {
                    Button {
                        NSWorkspace.shared.open(
                            URL(string: "macappstore://apps.apple.com/app/xcode/id497799835")!
                        )
                    } label: {
                        Label("App Store에서 Xcode 설치", systemImage: "arrow.down.app")
                            .font(.title2)
                            .frame(maxWidth: 480, minHeight: 64)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)

                    Text("App Store 버전이 호환되지 않는다면?")
                        .font(.body).foregroundStyle(.secondary)

                    Button {
                        NSWorkspace.shared.open(
                            URL(string: "https://xcodereleases.com")!
                        )
                    } label: {
                        Label("내 macOS에 호환되는 버전 찾아서 설치", systemImage: "magnifyingglass")
                            .font(.title2)
                            .frame(maxWidth: 480, minHeight: 64)
                    }
                    .buttonStyle(.bordered).controlSize(.large)
                }
            }

            Text("설치가 완료되면 아래 버튼을 눌러주세요.")
                .font(.title3).foregroundStyle(.secondary)

            Button {
                onRetry()
            } label: {
                Label("준비 완료! 시작하기", systemImage: "checkmark.circle")
                    .font(.title3)
                    .frame(maxWidth: 480, minHeight: 56)
            }
            .buttonStyle(.bordered).controlSize(.large)
        }
        .padding(64)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func stepRow(number: Int, title: String, description: String, isDone: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            if isDone {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green).font(.title2)
            } else {
                ZStack {
                    Circle().fill(.blue.opacity(0.15)).frame(width: 36, height: 36)
                    Text("\(number)").font(.title3).fontWeight(.semibold).foregroundStyle(.blue)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3).fontWeight(.semibold)
                    .foregroundStyle(isDone ? .secondary : .primary)
                    .strikethrough(isDone)
                Text(description)
                    .font(.body).foregroundStyle(.secondary)
            }
        }
    }
}
