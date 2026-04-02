import SwiftUI
import Core
import Domain
import Data
import Feature

struct OnboardingView: View {

    let status: EnvironmentStatus
    let onRetry: () -> Void
    @State private var isSettingUp = false

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
                    description: "시뮬레이터를 사용하려면 Xcode가 필요해요. (Command Line Tools만으로는 부족합니다)",
                    isDone: status.xcodeInstalled
                )
                stepRow(
                    number: 2,
                    title: "Xcode 한 번 실행",
                    description: "설치 후 Xcode를 한 번 열어서 라이선스 동의 + 초기 설정을 완료해주세요.",
                    isDone: status.xcodeInstalled && status.simctlAvailable
                )
            }
            .padding(28)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Xcode는 있지만 simctl이 안 되는 경우 (경로 미설정 또는 라이선스 미동의)
            if status.xcodeInstalled && !status.simctlAvailable {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Xcode 초기 설정이 필요합니다")
                            .font(.body).fontWeight(.medium)
                    }
                    Text("Xcode를 한 번 실행해서 라이선스 동의 + 추가 컴포넌트 설치를 완료해주세요.")
                        .font(.callout).foregroundStyle(.secondary)
                    Text("이미 했는데 안 되면, 아래 '시작하기' 버튼을 눌러주세요. (자동으로 설정합니다)")
                        .font(.callout).foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        let cmd = "sudo xcode-select -s \(status.xcodePath ?? "/Applications/Xcode.app/Contents/Developer")"
                        Text(cmd)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.primary)
                            .padding(8)
                            .background(.background.tertiary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(cmd, forType: .string)
                        } label: {
                            Label("복사", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.orange.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if !status.xcodeInstalled {
                VStack(spacing: 16) {
                    Button {
                        NSWorkspace.shared.open(
                            URL(string: "macappstore://apps.apple.com/app/xcode/id497799835")!
                        )
                    } label: {
                        Label("App Store에서 Xcode 설치", systemImage: "arrow.down.app")
                            .font(.title3)
                            .frame(maxWidth: 384, minHeight: 51)
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
                            .font(.title3)
                            .frame(maxWidth: 384, minHeight: 51)
                    }
                    .buttonStyle(.bordered).controlSize(.large)
                }
            }

            Text("Xcode 설치 후 아래 버튼을 눌러주세요.")
                .font(.title3).foregroundStyle(.secondary)

            Button {
                isSettingUp = true
                Task {
                    await configureXcodeAndRetry()
                }
            } label: {
                if isSettingUp {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: 384, minHeight: 51)
                } else {
                    Label("준비 완료! 시작하기", systemImage: "checkmark.circle")
                        .font(.title3)
                        .frame(maxWidth: 384, minHeight: 51)
                }
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            .disabled(isSettingUp)
        }
        .padding(64)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func configureXcodeAndRetry() async {
        // /Applications 에서 Xcode*.app 을 찾아서 xcode-select -s 실행
        if let xcodePath = findXcodeDevPath() {
            let script = "do shell script \"xcode-select -s \(xcodePath)\" with administrator privileges"
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
            }
        }
        isSettingUp = false
        onRetry()
    }

    private func findXcodeDevPath() -> String? {
        // 기본 경로 먼저
        let defaultPath = "/Applications/Xcode.app/Contents/Developer"
        if FileManager.default.fileExists(atPath: defaultPath) { return defaultPath }

        // Xcode*.app 검색
        guard let apps = try? FileManager.default.contentsOfDirectory(atPath: "/Applications") else { return nil }
        for app in apps where app.hasPrefix("Xcode") && app.hasSuffix(".app") {
            let devPath = "/Applications/\(app)/Contents/Developer"
            if FileManager.default.fileExists(atPath: devPath) { return devPath }
        }
        return nil
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
