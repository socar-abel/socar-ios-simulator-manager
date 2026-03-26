import SwiftUI
import BuildDomainInterface
import SimulatorDomainInterface
import Design

public struct BuildListView: View {

    @Bindable var viewModel: BuildListViewModel

    @State private var showFilePicker = false
    @State private var showInstallSheet = false
    @State private var appToInstall: URL?

    public init(viewModel: BuildListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                localSection
                Divider()
                driveSection
            }
            .padding(24)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.application, .zip],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first, url.pathExtension == "zip" {
                Task {
                    do { _ = try await viewModel.downloadBuild } catch {}
                }
            }
        }
        .sheet(isPresented: $showInstallSheet) {
            if let url = appToInstall {
                InstallTargetSheet(appURL: url, viewModel: viewModel) {
                    showInstallSheet = false
                }
            }
        }
        .task { await viewModel.onAppear() }
    }

    // MARK: - Local

    private var localSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("로컬 빌드").font(.headline)
                Spacer()
                Button { showFilePicker = true } label: {
                    Label("파일 추가", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }

            let apps = viewModel.localApps()
            if apps.isEmpty {
                Text("로컬에 저장된 빌드가 없습니다.")
                    .font(.caption).foregroundStyle(.secondary).padding(.vertical, 8)
            } else {
                ForEach(apps, id: \.path) { appURL in
                    localBuildRow(appURL)
                }
            }
        }
    }

    private func localBuildRow(_ appURL: URL) -> some View {
        HStack {
            Image(systemName: "app.fill").foregroundStyle(.blue)
            VStack(alignment: .leading) {
                Text(appURL.lastPathComponent).font(.body)
                Text(appURL.deletingLastPathComponent().lastPathComponent)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("설치") {
                appToInstall = appURL
                showInstallSheet = true
            }
            .buttonStyle(.bordered)

            Button { viewModel.deleteBuild(at: appURL) } label: {
                Image(systemName: "trash").foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(8)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Drive

    private var driveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Google Drive 빌드").font(.headline)
                Spacer()
                if viewModel.isLoadingRemote { ProgressView().scaleEffect(0.8) }
                Button("새로고침") { Task { await viewModel.loadRemoteBuilds() } }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoadingRemote)
            }

            if !viewModel.isDriveConfigured {
                ContentUnavailableView(
                    "Google Drive 미연동",
                    systemImage: "cloud",
                    description: Text("설정에서 서비스 계정 키를 등록해주세요.")
                )
            } else if let error = viewModel.remoteError {
                Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red).font(.caption)
            } else {
                ForEach(viewModel.remoteBuilds) { build in
                    remoteBuildRow(build)
                }
            }
        }
    }

    private func remoteBuildRow(_ build: BuildInfo) -> some View {
        HStack {
            Image(systemName: "doc.zipper").foregroundStyle(.orange)
            VStack(alignment: .leading) {
                Text(build.fileName).font(.body)
                HStack(spacing: 8) {
                    Text("v\(build.version)").font(.caption)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.blue.opacity(0.1)).clipShape(Capsule())
                    Text(build.rcNumber).font(.caption).foregroundStyle(.secondary)
                    Text(build.displaySize).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if viewModel.downloadingFileId == build.id {
                ProgressView(value: viewModel.downloadProgress).frame(width: 80)
            } else {
                Button("다운로드") { Task { await viewModel.downloadBuild(build) } }
                    .buttonStyle(.bordered)
            }
        }
        .padding(8)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Install Target Sheet

struct InstallTargetSheet: View {
    let appURL: URL
    @Bindable var viewModel: BuildListViewModel
    let onDismiss: () -> Void

    @State private var bootedDevices: [SimulatorDevice] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("설치할 디바이스 선택").font(.headline)
                Spacer()
                Button("취소") { onDismiss() }.buttonStyle(.borderless)
            }
            .padding()
            Divider()

            if bootedDevices.isEmpty {
                ContentUnavailableView(
                    "실행중인 디바이스가 없습니다",
                    systemImage: "iphone.slash",
                    description: Text("먼저 디바이스를 부팅해주세요.")
                )
            } else {
                List {
                    ForEach(bootedDevices) { device in
                        Button {
                            Task {
                                try? await viewModel.installOnDevice(appURL: appURL, udid: device.udid)
                                onDismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "iphone")
                                Text(device.name)
                                if let rt = device.runtimeDisplayName {
                                    Text(rt).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle").foregroundStyle(.blue)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
        .task { bootedDevices = await viewModel.bootedDevices() }
    }
}
