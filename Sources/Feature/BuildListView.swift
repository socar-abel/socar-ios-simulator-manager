import SwiftUI
import Domain
import Core

public struct BuildListView: View {

    @Bindable var viewModel: BuildListViewModel

    @State private var showFilePicker = false
    @State private var appToInstall: IdentifiableURL?
    @State private var isDropTargeted = false
    @State private var refreshId = UUID()

    public init(viewModel: BuildListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                guideBanner
                buildList

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error) { viewModel.dismissError() }
                }
                if let success = viewModel.successMessage {
                    successBanner(success)
                }
            }
            .padding(24)
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
        .overlay {
            if isDropTargeted {
                dropOverlay
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.application, .zip],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                for url in urls {
                    Task { await viewModel.addBuild(from: url) ; refreshId = UUID() }
                }
            }
        }
        .sheet(item: $appToInstall) { item in
            InstallTargetSheet(appURL: item.url, viewModel: viewModel) {
                appToInstall = nil
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("빌드 관리").font(.headline)
            Spacer()
            if viewModel.isAdding {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.7)
                    Text("추가 중...").font(.caption).foregroundStyle(.secondary)
                }
            }
            Button("파일 추가") { showFilePicker = true }
                .buttonStyle(.bordered)
        }
    }

    // MARK: - Guide

    private var guideBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Google Drive에서 .app 또는 .zip 파일을 다운로드한 후,")
                    .font(.callout)
                Text("'파일 추가' 버튼을 누르거나 이 영역으로 드래그하세요.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.yellow.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Build List

    private var buildList: some View {
        let apps = viewModel.localApps()
        return Group {
            if apps.isEmpty {
                ContentUnavailableView(
                    "저장된 빌드가 없습니다",
                    systemImage: "app.dashed",
                    description: Text("파일을 추가하거나 여기로 드래그하세요.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(apps, id: \.path) { appURL in
                        buildRow(appURL)
                    }
                }
            }
        }
        .id(refreshId)
    }

    private func buildRow(_ appURL: URL) -> some View {
        let info = viewModel.appInfo(from: appURL)
        return HStack(spacing: 16) {
            if let icon = info.iconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "app.fill")
                    .foregroundStyle(.blue)
                    .font(.system(size: 32))
                    .frame(width: 52, height: 52)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(info.displayName ?? appURL.lastPathComponent)
                        .font(.title3).fontWeight(.semibold)
                    if let version = info.version {
                        Text("v\(version)")
                            .font(.caption)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                Text(info.versionDescription)
                    .font(.callout).foregroundStyle(.secondary)
            }

            Spacer()

            Button("설치") {
                appToInstall = IdentifiableURL(url: appURL)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button {
                viewModel.deleteBuild(at: appURL)
                refreshId = UUID()
            } label: {
                Image(systemName: "trash").foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Drop

    private var dropOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(.blue, style: StrokeStyle(lineWidth: 3, dash: [8]))
            .background(RoundedRectangle(cornerRadius: 12).fill(.blue.opacity(0.08)))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.largeTitle).foregroundStyle(.blue)
                    Text("여기에 파일을 놓으세요")
                        .font(.headline).foregroundStyle(.blue)
                    Text(".app 또는 .zip 파일")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(24)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                guard let data = data as? Data,
                      let path = String(data: data, encoding: .utf8),
                      let url = URL(string: path) else { return }
                let ext = url.pathExtension.lowercased()
                guard ext == "app" || ext == "zip" else { return }
                Task { @MainActor in
                    await viewModel.addBuild(from: url)
                    refreshId = UUID()
                }
            }
        }
        return true
    }

    // MARK: - Banners

    private func successBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text(message).font(.callout)
            Spacer()
            Button("닫기") { viewModel.dismissSuccess() }.buttonStyle(.borderless)
        }
        .padding(12)
        .background(.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Install Target Sheet

struct InstallTargetSheet: View {
    let appURL: URL
    @Bindable var viewModel: BuildListViewModel
    let onDismiss: () -> Void

    @State private var bootedDevices: [SimulatorDevice] = []
    @State private var installedStatus: [String: Bool] = [:]
    @State private var isLoadingDevices = true
    @State private var isInstalling = false
    @State private var installError: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("설치할 디바이스 선택").font(.headline)
                Spacer()
                Button("취소") { onDismiss() }.buttonStyle(.borderless)
                    .disabled(isInstalling)
            }
            .padding()
            Divider()

            if let error = installError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                    Text(error).font(.caption).foregroundStyle(.red)
                    Spacer()
                }
                .padding(.horizontal).padding(.vertical, 8)
                .background(.red.opacity(0.05))
            }

            if isInstalling {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("설치 중...").font(.callout).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isLoadingDevices {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if bootedDevices.isEmpty {
                ContentUnavailableView(
                    "실행중인 디바이스가 없습니다",
                    systemImage: "iphone.slash",
                    description: Text("먼저 디바이스를 부팅해주세요.")
                )
            } else {
                List {
                    ForEach(bootedDevices) { device in
                        let isInstalled = installedStatus[device.udid] ?? false
                        Button {
                            install(on: device)
                        } label: {
                            HStack {
                                Image(systemName: "iphone")
                                Text(device.name)
                                if let rt = device.runtimeDisplayName {
                                    Text(rt).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if isInstalled {
                                    Text("이미 설치됨").font(.caption).foregroundStyle(.green)
                                }
                                Text("설치").foregroundStyle(.blue)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("설치 경로: \(appURL.path)")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .padding(.horizontal).padding(.bottom, 8)
            }
        }
        .frame(width: 450, height: 350)
        .task {
            bootedDevices = await viewModel.bootedDevices()
            // 각 디바이스별 설치 여부 확인
            for device in bootedDevices {
                installedStatus[device.udid] = await viewModel.isAppInstalled(
                    appURL: appURL, udid: device.udid
                )
            }
            isLoadingDevices = false
        }
    }

    private func install(on device: SimulatorDevice) {
        isInstalling = true
        installError = nil
        Task {
            do {
                try await viewModel.installOnDevice(appURL: appURL, udid: device.udid)
                viewModel.successMessage = "\(appURL.lastPathComponent)을(를) \(device.name)에 설치했습니다."
                onDismiss()
            } catch {
                installError = error.localizedDescription
                isInstalling = false
            }
        }
    }
}

// MARK: - Helpers

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
