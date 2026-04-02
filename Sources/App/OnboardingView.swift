import SwiftUI
import Core
import Domain
import Data
import Feature

struct OnboardingView: View {

    let status: EnvironmentStatus
    let onRetry: () -> Void
    @State private var isSettingUp = false
    @State private var showFailAlert = false
    @State private var failMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // 헤더
                VStack(spacing: 12) {
                    Image(systemName: "macbook.and.iphone")
                        .font(.system(size: 80)).foregroundStyle(.blue)
                    Text("SOCAR Simulator Manager")
                        .font(.system(size: 36, weight: .bold))
                    Text("환영합니다! 시작하기 전에 간단한 준비가 필요해요.")
                        .font(.title3).foregroundStyle(.secondary)
                }

                // 섹션 1: 사전 준비 안내
                sectionCard(title: "사전 준비 안내", icon: "list.clipboard") {
                    VStack(alignment: .leading, spacing: 20) {
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
                }

                // 섹션 2: Xcode 설치하기 (Xcode 미설치 시) 또는 초기 설정 안내 (설치 후)
                if !status.xcodeInstalled {
                    sectionCard(title: "Xcode 설치하기", icon: "arrow.down.app") {
                        VStack(spacing: 16) {
                            Button {
                                NSWorkspace.shared.open(
                                    URL(string: "https://xcodereleases.com")!
                                )
                            } label: {
                                Label("내 macOS에 맞는 Xcode 찾아서 설치", systemImage: "safari")
                                    .font(.title3)
                                    .frame(maxWidth: 384, minHeight: 48)
                            }
                            .buttonStyle(.borderedProminent).controlSize(.large)

                            Text("당신의 macOS는 \(ProcessInfo.processInfo.operatingSystemVersionString) 입니다.")
                                .font(.body).foregroundStyle(.secondary)

                            Divider()

                            VStack(alignment: .leading, spacing: 10) {
                                Label("다운로드한 .xip 파일을 더블클릭하면 Xcode가 설치됩니다.", systemImage: "1.circle")
                                    .font(.body).foregroundStyle(.secondary)
                                Label("Xcode가 Downloads 폴더에 있다면, Applications 폴더로 드래그해서 옮겨주세요.", systemImage: "2.circle")
                                    .font(.body).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications"))
                            } label: {
                                Label("Applications 폴더 열기", systemImage: "folder")
                                    .font(.callout)
                            }
                            .buttonStyle(.bordered).controlSize(.regular)
                        }
                    }
                } else if !status.simctlAvailable {
                    sectionCard(title: "Xcode 초기 설정이 필요합니다", icon: "exclamationmark.triangle.fill", iconColor: .orange) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Xcode를 한 번 실행해서 라이선스 동의 + 추가 컴포넌트 설치를 완료해주세요.")
                                .font(.body).foregroundStyle(.secondary)
                            Text("이미 했는데 안 되면, 아래 '시작하기' 버튼을 눌러주세요. (자동으로 설정합니다)")
                                .font(.body).foregroundStyle(.secondary)
                        }
                    }
                }

                // 섹션 3: Xcode 설치를 완료하셨나요?
                sectionCard(title: "Xcode 설치를 완료하셨나요?", icon: "checkmark.seal") {
                    VStack(spacing: 16) {
                        Button {
                            isSettingUp = true
                            Task { await configureXcodeAndRetry() }
                        } label: {
                            if isSettingUp {
                                ProgressView()
                                    .controlSize(.small)
                                    .frame(maxWidth: 384, minHeight: 48)
                            } else {
                                Label("준비 완료! 시작하기", systemImage: "checkmark.circle")
                                    .font(.title3)
                                    .frame(maxWidth: 384, minHeight: 48)
                            }
                        }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                        .disabled(isSettingUp)

                        Text("Xcode 설치 후 라이선스 동의를 완료해도 시작이 안된다면,\n이 앱을 종료하고 다시 시작해주세요.")
                            .font(.callout).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(48)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("설정 실패", isPresented: $showFailAlert) {
            Button("확인") {}
        } message: {
            Text(failMessage)
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color = .blue,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.title3)
                Text(title)
                    .font(.title3).fontWeight(.semibold)
            }
            content()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func configureXcodeAndRetry() async {
        guard let xcodePath = findXcodeDevPath() else {
            isSettingUp = false
            failMessage = "Xcode를 찾을 수 없습니다.\n/Applications 폴더에 Xcode를 설치해주세요."
            showFailAlert = true
            return
        }

        // DEVELOPER_DIR 환경변수 설정 — sudo 필요 없이 xcrun simctl 동작
        setenv("DEVELOPER_DIR", xcodePath, 1)

        // Xcode가 한번도 실행된 적 없으면 열어서 라이선스 동의 유도
        if !status.simctlAvailable {
            let xcodeAppPath = xcodePath
                .replacingOccurrences(of: "/Contents/Developer", with: "")
            NSWorkspace.shared.open(URL(fileURLWithPath: xcodeAppPath))

            // Xcode 초기 설정 완료 대기 (최대 5분)
            var simctlReady = false
            for _ in 0..<150 {
                try? await Task.sleep(for: .seconds(2))
                if let result = try? await ShellService.execute(
                    executable: "/usr/bin/xcrun",
                    arguments: ["simctl", "help"],
                    timeout: 5
                ), result.isSuccess {
                    simctlReady = true
                    break
                }
            }

            if !simctlReady {
                isSettingUp = false
                failMessage = "Xcode 초기 설정이 아직 완료되지 않았습니다.\nXcode를 실행하여 라이선스 동의와 추가 컴포넌트 설치를 완료한 후, 이 앱을 다시 시작해주세요."
                showFailAlert = true
                return
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
