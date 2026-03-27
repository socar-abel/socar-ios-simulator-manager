import SwiftUI
import Core
import Domain
import Data
import Feature

struct OnboardingView: View {

    let status: EnvironmentStatus
    let onRetry: () -> Void

    @State private var compatibleXcode: CompatibleXcode?
    @State private var isLoadingXcode = false

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

            if !status.xcodeInstalled {
                xcodeDownloadSection
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
                    .buttonStyle(.bordered).controlSize(.large)
                }

                Button("다시 확인") { onRetry() }
                    .buttonStyle(.bordered).controlSize(.large)
            }
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if !status.xcodeInstalled {
                await findCompatibleXcode()
            }
        }
    }

    // MARK: - Xcode Download Section

    private var xcodeDownloadSection: some View {
        VStack(spacing: 12) {
            if isLoadingXcode {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8)
                    Text("호환 가능한 Xcode 버전을 찾는 중...")
                        .font(.callout).foregroundStyle(.secondary)
                }
            } else if let xcode = compatibleXcode {
                VStack(spacing: 8) {
                    Text("이 Mac(macOS \(xcode.macOSVersion))에 호환되는 최신 버전:")
                        .font(.caption).foregroundStyle(.secondary)

                    Button {
                        if let url = URL(string: xcode.downloadURL) {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Label("Xcode \(xcode.version) 다운로드", systemImage: "arrow.down.circle.fill")
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)

                    Text("Apple ID 로그인이 필요합니다. 다운로드 후 .xip 파일을 더블클릭하여 설치하세요.")
                        .font(.caption2).foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Helpers

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

    private func findCompatibleXcode() async {
        isLoadingXcode = true
        defer { isLoadingXcode = false }

        guard let url = URL(string: "https://xcodereleases.com/data.json") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let releases = try JSONDecoder().decode([XcodeRelease].self, from: data)

            let macVersion = ProcessInfo.processInfo.operatingSystemVersion
            let macVersionString = "\(macVersion.majorVersion).\(macVersion.minorVersion)"

            // 정식 릴리즈 중 현재 macOS와 호환되는 최신 버전
            for release in releases {
                guard release.version.release.release == true else { continue }
                guard let downloadURL = release.links.download?.url else { continue }

                let requires = release.requires
                let reqParts = requires.split(separator: ".").compactMap { Int($0) }
                let reqMajor = reqParts.first ?? 0
                let reqMinor = reqParts.count > 1 ? reqParts[1] : 0

                let compatible = (macVersion.majorVersion > reqMajor) ||
                    (macVersion.majorVersion == reqMajor && macVersion.minorVersion >= reqMinor)

                if compatible {
                    compatibleXcode = CompatibleXcode(
                        version: release.version.number,
                        macOSVersion: macVersionString,
                        downloadURL: downloadURL
                    )
                    return
                }
            }
        } catch {
            // 네트워크 실패 시 조용히 무시 (App Store 버튼은 항상 표시)
        }
    }
}

// MARK: - Models

private struct CompatibleXcode {
    let version: String
    let macOSVersion: String
    let downloadURL: String
}

private struct XcodeRelease: Codable {
    let version: XcodeVersion
    let requires: String
    let links: XcodeLinks
}

private struct XcodeVersion: Codable {
    let number: String
    let release: XcodeReleaseInfo
}

private struct XcodeReleaseInfo: Codable {
    let release: Bool?
}

private struct XcodeLinks: Codable {
    let download: XcodeDownloadLink?
}

private struct XcodeDownloadLink: Codable {
    let url: String
}
