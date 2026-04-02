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
                Button {
                    NSWorkspace.shared.open(
                        URL(string: "https://xcodereleases.com")!
                    )
                } label: {
                    Label("내 macOS에 맞는 Xcode 찾아서 설치", systemImage: "arrow.down.app")
                        .font(.title3)
                        .frame(maxWidth: 384, minHeight: 51)
                }
                .buttonStyle(.borderedProminent).controlSize(.large)

                Text("당신의 macOS는 \(ProcessInfo.processInfo.operatingSystemVersionString) 입니다.")
                    .font(.callout).foregroundStyle(.secondary)
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

            Text("Xcode 설치 후 라이선스 동의를 완료해도 시작이 안된다면,\n이 앱을 종료하고 다시 시작해주세요.")
                .font(.caption).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(64)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func configureXcodeAndRetry() async {
        if let xcodePath = findXcodeDevPath() {
            // 1) DEVELOPER_DIR 환경변수 설정 — sudo 필요 없이 xcrun simctl 동작
            setenv("DEVELOPER_DIR", xcodePath, 1)

            // 2) Xcode가 한번도 실행된 적 없으면 열어서 라이선스 동의 유도
            if !status.simctlAvailable {
                let xcodeAppPath = xcodePath
                    .replacingOccurrences(of: "/Contents/Developer", with: "")
                NSWorkspace.shared.open(URL(fileURLWithPath: xcodeAppPath))

                // Xcode 초기 설정 완료 대기 (최대 5분)
                for _ in 0..<150 {
                    try? await Task.sleep(for: .seconds(2))
                    if let result = try? await ShellService.execute(
                        executable: "/usr/bin/xcrun",
                        arguments: ["simctl", "help"],
                        timeout: 5
                    ), result.isSuccess {
                        break
                    }
                }
            }
        }
        isSettingUp = false
        onRetry()
    }

    private func findXcodeDevPath() -> String? {
        let defaultPath = "/Applications/Xcode.app/Contents/Developer"
        if FileManager.default.fileExists(atPath: defaultPath) { return defaultPath }

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
