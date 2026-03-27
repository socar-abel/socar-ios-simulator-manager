import SwiftUI
import Domain
import Core

public struct BuildListView: View {

    @Bindable var viewModel: BuildListViewModel

    @State private var showFilePicker = false
    @State private var showInstallSheet = false
    @State private var appToInstall: URL?
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
        .sheet(isPresented: $showInstallSheet) {
            if let url = appToInstall {
                InstallTargetSheet(appURL: url, viewModel: viewModel) {
                    showInstallSheet = false
                }
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
        HStack(spacing: 12) {
            Image(systemName: "app.fill")
                .foregroundStyle(.blue)
                .font(.title2)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(appURL.lastPathComponent)
                    .font(.body).fontWeight(.medium)
                Text(appURL.deletingLastPathComponent().lastPathComponent)
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Button("설치") {
                appToInstall = appURL
                showInstallSheet = true
            }
            .buttonStyle(.bordered)

            Button {
                viewModel.deleteBuild(at: appURL)
                refreshId = UUID()
            } label: {
                Image(systemName: "trash").foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(10)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
