import SwiftUI
import Core
import Domain
import Data
import Feature

struct OnboardingView: View {

    let status: EnvironmentStatus
    let onRetry: () -> Void
    @State private var currentPage = 0
    @State private var isSettingUp = false
    @State private var showFailAlert = false
    @State private var failMessage = ""
    @State private var recommendedXcodeVersion: String?
    @State private var recommendedXcodeDownloadURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            // 페이지 인디케이터
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index == currentPage ? Color.blue : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 24)

            // 페이지 컨텐츠
            TabView(selection: $currentPage) {
                page1.tag(0)
                page2.tag(1)
                page3.tag(2)
            }
            .tabViewStyle(.automatic)

            // 네비게이션 버튼
            HStack {
                if currentPage > 0 {
                    Button {
                        withAnimation { currentPage -= 1 }
                    } label: {
                        Label("이전", systemImage: "chevron.left")
                            .font(.body)
                            .frame(minWidth: 100, minHeight: 40)
                    }
                    .buttonStyle(.bordered).controlSize(.large)
                } else {
                    Spacer().frame(width: 100)
                }

                Spacer()

                Text("\(currentPage + 1) / 3")
                    .font(.callout).foregroundStyle(.secondary)

                Spacer()

                if currentPage < 2 {
                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        Label("다음", systemImage: "chevron.right")
                            .font(.body)
                            .frame(minWidth: 100, minHeight: 40)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                } else {
                    Spacer().frame(width: 100)
                }
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await fetchRecommendedXcode() }
        .alert("설정 실패", isPresented: $showFailAlert) {
            Button("확인") {}
        } message: {
            Text(failMessage)
        }
    }

    // MARK: - Page 1: 사전 준비 안내

    private var page1: some View {
        ScrollView {
            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    Image(systemName: "macbook.and.iphone")
                        .font(.system(size: 80)).foregroundStyle(.blue)
                    Text("SOCAR Simulator Manager")
                        .font(.system(size: 32, weight: .bold))
                    Text("환영합니다! 시작하기 전에 간단한 준비가 필요해요.")
                        .font(.title3).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 8) {
                        Image(systemName: "list.clipboard")
                            .foregroundStyle(.blue).font(.title3)
                        Text("사전 준비 안내")
                            .font(.title3).fontWeight(.semibold)
                    }

                    stepRow(
                        number: 1,
                        title: "Xcode 설치",
                        description: "시뮬레이터를 사용하려면 Xcode가 필요해요.\n(Command Line Tools만으로는 부족합니다)",
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
                .frame(maxWidth: 550, alignment: .leading)
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(48)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Page 2: Xcode 설치하기

    private var page2: some View {
        ScrollView {
            VStack(spacing: 32) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.app")
                        .foregroundStyle(.blue).font(.title3)
                    Text("Xcode 설치하기")
                        .font(.title2).fontWeight(.semibold)
                }

                // 추천 Xcode 다운로드
                VStack(spacing: 16) {
                    if let version = recommendedXcodeVersion, let downloadURL = recommendedXcodeDownloadURL {
                        Button {
                            NSWorkspace.shared.open(downloadURL)
                        } label: {
                            Label("Xcode \(version) 다운로드", systemImage: "arrow.down.circle.fill")
                                .font(.title3)
                                .frame(maxWidth: 420, minHeight: 56)
                        }
                        .buttonStyle(.borderedProminent).controlSize(.large)

                        Text("당신의 macOS(\(ProcessInfo.processInfo.operatingSystemVersionString))에 호환되는 최신 버전입니다.\nApple ID 로그인이 필요할 수 있습니다.")
                            .font(.body).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Button {
                            NSWorkspace.shared.open(URL(string: "https://xcodereleases.com")!)
                        } label: {
                            Label("내 macOS에 맞는 Xcode 찾아서 설치", systemImage: "safari")
                                .font(.title3)
                                .frame(maxWidth: 420, minHeight: 56)
                        }
                        .buttonStyle(.borderedProminent).controlSize(.large)

                        Text("당신의 macOS는 \(ProcessInfo.processInfo.operatingSystemVersionString) 입니다.")
                            .font(.body).foregroundStyle(.secondary)
                    }
                }

                Divider().frame(maxWidth: 500)

                // 설치 안내
                VStack(alignment: .leading, spacing: 14) {
                    Label("다운로드한 .xip 파일을 더블클릭하면 Xcode가 설치됩니다.", systemImage: "1.circle.fill")
                        .font(.body)
                    Label("Xcode가 Downloads 폴더에 있다면, Applications 폴더로 드래그해서 옮겨주세요.", systemImage: "2.circle.fill")
                        .font(.body)
                    Label("Xcode를 한 번 실행하여 라이선스 동의 + 추가 컴포넌트 설치를 완료해주세요.", systemImage: "3.circle.fill")
                        .font(.body)
                }
                .foregroundStyle(.secondary)
                .padding(24)
                .frame(maxWidth: 550, alignment: .leading)
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications"))
                } label: {
                    Label("Applications 폴더 열기", systemImage: "folder")
                        .font(.callout)
                }
                .buttonStyle(.bordered).controlSize(.regular)
            }
            .padding(48)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Page 3: Xcode 설치 및 라이선스 동의를 완료하셨나요?

    private var page3: some View {
        ScrollView {
            VStack(spacing: 32) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal")
                        .foregroundStyle(.blue).font(.title3)
                    Text("Xcode 설치 및 라이선스 동의를 완료하셨나요?")
                        .font(.title2).fontWeight(.semibold)
                }

                if status.xcodeInstalled && !status.simctlAvailable {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Xcode 초기 설정이 필요합니다", systemImage: "exclamationmark.triangle.fill")
                            .font(.body).fontWeight(.medium).foregroundStyle(.orange)
                        Text("Xcode를 한 번 실행해서 라이선스 동의 + 추가 컴포넌트 설치를 완료해주세요.")
                            .font(.body).foregroundStyle(.secondary)
                        Text("이미 했는데 안 되면, 아래 '시작하기' 버튼을 눌러주세요.")
                            .font(.body).foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .frame(maxWidth: 500, alignment: .leading)
                    .background(.orange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    isSettingUp = true
                    Task { await configureXcodeAndRetry() }
                } label: {
                    if isSettingUp {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: 420, minHeight: 56)
                    } else {
                        Label("준비 완료! 시작하기", systemImage: "checkmark.circle")
                            .font(.title3)
                            .frame(maxWidth: 420, minHeight: 56)
                    }
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(isSettingUp)

                Text("Xcode 설치 후 라이선스 동의를 완료해도 시작이 안된다면,\n이 앱을 종료하고 다시 시작해주세요.")
                    .font(.callout).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(48)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Recommended Xcode

    private func fetchRecommendedXcode() async {
        guard let url = URL(string: "https://xcodereleases.com/data.json") else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }

        struct XcodeRelease: Codable {
            struct Version: Codable {
                let number: String
                let release: ReleaseType?
            }
            struct ReleaseType: Codable {
                let release: Bool?
                let beta: Int?
                let rc: Int?
            }
            struct Links: Codable {
                struct Download: Codable { let url: String? }
                let download: Download?
            }
            let name: String?
            let version: Version
            let requires: String?
            let links: Links?
        }

        guard let releases = try? JSONDecoder().decode([XcodeRelease].self, from: data) else { return }

        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let macOSVersion = "\(osVersion.majorVersion).\(osVersion.minorVersion)"

        // macOS 호환 + 정식 Release + Apple Silicon 우선
        for xcode in releases {
            guard xcode.version.release?.release == true,
                  let requires = xcode.requires,
                  compareMacOSVersions(macOSVersion, isAtLeast: requires),
                  xcode.name?.contains("Apple Silicon") == true
            else { continue }

            // download.developer.apple.com → developer.apple.com/services-account/download?path= 변환
            var downloadURL: URL?
            if let rawURL = xcode.links?.download?.url,
               let path = rawURL.split(separator: "download.developer.apple.com").last {
                downloadURL = URL(string: "https://developer.apple.com/services-account/download?path=\(path)")
            }

            await MainActor.run {
                recommendedXcodeVersion = xcode.version.number
                recommendedXcodeDownloadURL = downloadURL
            }
            return
        }
    }

    private func compareMacOSVersions(_ current: String, isAtLeast required: String) -> Bool {
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        let requiredParts = required.split(separator: ".").compactMap { Int($0) }
        let major1 = currentParts.first ?? 0
        let minor1 = currentParts.count > 1 ? currentParts[1] : 0
        let major2 = requiredParts.first ?? 0
        let minor2 = requiredParts.count > 1 ? requiredParts[1] : 0
        return (major1, minor1) >= (major2, minor2)
    }

    // MARK: - Actions

    private func configureXcodeAndRetry() async {
        guard let xcodePath = findXcodeDevPath() else {
            isSettingUp = false
            failMessage = "Xcode를 찾을 수 없습니다.\n/Applications 폴더에 Xcode를 설치해주세요."
            showFailAlert = true
            return
        }

        setenv("DEVELOPER_DIR", xcodePath, 1)

        if !status.simctlAvailable {
            let xcodeAppPath = xcodePath
                .replacingOccurrences(of: "/Contents/Developer", with: "")
            NSWorkspace.shared.open(URL(fileURLWithPath: xcodeAppPath))

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

    // MARK: - Components

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
