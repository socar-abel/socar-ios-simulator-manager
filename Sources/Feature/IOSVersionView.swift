import SwiftUI
import Domain
import Core

public struct IOSVersionView: View {

    @Bindable var viewModel: IOSVersionViewModel

    @State private var versionToDelete: InstalledIOSVersion?
    @State private var versionToDownload: DownloadableIOSVersion?

    public init(viewModel: IOSVersionViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                diskUsageSection
                Divider()
                installedSection
                Divider()
                downloadableSection
                Divider()
                cleanupSection
            }
            .padding(24)
        }
        .overlay {
            // 삭제 중 오버레이
            if viewModel.isDeleting {
                Color.black.opacity(0.3).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView().scaleEffect(1.2)
                    Text("iOS 버전 삭제 중...").font(.headline).foregroundStyle(.white)
                    Text("이 작업은 시간이 오래 소요될 수 있습니다.")
                        .font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            // 정리 중 오버레이
            if viewModel.isCleaning {
                Color.black.opacity(0.3).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView().scaleEffect(1.2)
                    Text("디바이스 정리 중...").font(.headline).foregroundStyle(.white)
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error) { viewModel.dismissError() }
                        .padding(.horizontal, 16)
                }
                if let success = viewModel.successMessage {
                    successBanner(success)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation { viewModel.dismissSuccess() }
                            }
                        }
                }
            }
            .padding(.bottom, 24)
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.successMessage)
        .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
        .task { await viewModel.onAppear() }
        .confirmationDialog(
            "iOS 버전을 삭제하시겠습니까?",
            isPresented: .init(
                get: { versionToDelete != nil },
                set: { if !$0 { versionToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let version = versionToDelete {
                Button("삭제 (\(version.displaySize))", role: .destructive) {
                    Task { await viewModel.deleteIOSVersion(version) }
                    versionToDelete = nil
                }
            }
        } message: {
            if let version = versionToDelete {
                Text("\(version.displayName) (\(version.displaySize))을(를) 삭제합니다. 이 버전을 사용하는 디바이스도 사용할 수 없게 됩니다.")
            }
        }
        .confirmationDialog(
            "iOS 버전을 다운로드하시겠습니까?",
            isPresented: .init(
                get: { versionToDownload != nil },
                set: { if !$0 { versionToDownload = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let version = versionToDownload {
                Button("다운로드 (\(version.displaySize))") {
                    let v = version
                    versionToDownload = nil
                    Task { await viewModel.downloadIOSVersion(v) }
                }
            }
        } message: {
            if let version = versionToDownload {
                Text("\(version.shortName) (\(version.displaySize))을(를) 다운로드합니다. 수십 분이 소요될 수 있습니다.")
            }
        }
    }

    // MARK: - Disk Usage

    private var diskUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("디스크 사용량").font(.headline)

            if let disk = viewModel.diskUsage {
                HStack(spacing: 24) {
                    diskItem(label: "iOS 버전", value: disk.iosVersionsDisplay, icon: "cpu", color: .blue)
                    diskItem(label: "디바이스", value: disk.devicesDisplay, icon: "iphone", color: .green)
                    diskItem(label: "합계", value: disk.totalDisplay, icon: "externaldrive", color: .orange)
                }

                GeometryReader { geo in
                    let total = max(disk.totalBytes, 1)
                    HStack(spacing: 2) {
                        Rectangle()
                            .fill(.blue)
                            .frame(width: geo.size.width * CGFloat(disk.iosVersionsBytes) / CGFloat(total))
                        Rectangle()
                            .fill(.green)
                            .frame(width: geo.size.width * CGFloat(disk.devicesBytes) / CGFloat(total))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .frame(height: 8)
            } else if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity)
            }
        }
    }

    private func diskItem(label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.title3).fontWeight(.semibold)
            }
        }
        .padding(12)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Installed

    private var installedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("설치된 iOS 버전").font(.headline)

            if viewModel.installedIOSVersions.isEmpty && !viewModel.isLoading {
                VStack(spacing: 8) {
                    Image(systemName: "cpu").font(.largeTitle).foregroundStyle(.secondary)
                    Text("설치된 iOS 버전이 없습니다").foregroundStyle(.secondary)
                    Text("아래에서 원하는 버전을 다운로드하세요.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(viewModel.installedIOSVersions) { version in
                    installedRow(version)
                }
            }
        }
    }

    private func installedRow(_ version: InstalledIOSVersion) -> some View {
        let isBeingDeleted = viewModel.deletingVersionId == version.identifier
        return HStack(spacing: 12) {
            if isBeingDeleted {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(width: 28)
            } else {
                Image(systemName: "cpu")
                    .font(.title2)
                    .foregroundStyle(version.isReady ? .blue : .secondary)
                    .frame(width: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(version.displayName).font(.body).fontWeight(.medium)
                    Text("v\(version.version)")
                        .font(.caption)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                    if isBeingDeleted {
                        Text("삭제 중...")
                            .font(.caption).fontWeight(.medium)
                            .foregroundStyle(.red)
                    }
                }
                HStack(spacing: 8) {
                    Text(version.displaySize).font(.caption).foregroundStyle(.secondary)
                    Text(version.state).font(.caption).foregroundStyle(version.isReady ? .green : .orange)
                }
            }

            Spacer()

            if version.isDeletable {
                Button { versionToDelete = version } label: {
                    Image(systemName: "trash").foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isDeleting)
            } else {
                Text("시스템").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .background(isBeingDeleted ? Color.red.opacity(0.05) : Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(isBeingDeleted ? 0.7 : 1)
    }

    // MARK: - Downloadable

    private var downloadableSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("다운로드 가능한 iOS 버전").font(.headline)
                Spacer()
                if viewModel.isLoadingDownloadable {
                    ProgressView().scaleEffect(0.7)
                }
            }

            if viewModel.isDownloading, let name = viewModel.downloadingVersionName {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.8)
                        Text("\(name) 다운로드 중")
                            .font(.callout).fontWeight(.medium)
                        Spacer()
                        Button("취소") { viewModel.cancelDownload() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }

                    if let progress = viewModel.downloadProgress {
                        ProgressView(value: progress.percent, total: 100)
                            .progressViewStyle(.linear)

                        Text(progress.displayText)
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("준비 중...")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if viewModel.downloadableLoadFailed && !viewModel.isLoadingDownloadable {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash").foregroundStyle(.orange)
                    Text("다운로드 가능한 버전을 불러올 수 없습니다. 인터넷 연결을 확인해주세요.")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("재시도") { Task { await viewModel.loadDownloadableVersions() } }
                        .buttonStyle(.bordered).controlSize(.small)
                }
                .padding(8)
            } else if viewModel.downloadableIOSVersions.isEmpty && !viewModel.isLoadingDownloadable && !viewModel.isLoading {
                Text("모든 iOS 버전이 이미 설치되어 있습니다.")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else if !viewModel.downloadableIOSVersions.isEmpty {
                ForEach(viewModel.downloadableIOSVersions) { version in
                    downloadableRow(version)
                }
            }
        }
    }

    private func downloadableRow(_ version: DownloadableIOSVersion) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(version.shortName).font(.body).fontWeight(.medium)
                Text(version.displaySize).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.isDownloading && viewModel.downloadingVersionName == version.shortName {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(width: 80)
            } else {
                Button {
                    versionToDownload = version
                } label: {
                    Label("다운로드", systemImage: "arrow.down.to.line")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isDownloading)
            }
        }
        .padding(10)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Cleanup

    @State private var showCleanupConfirmation = false

    private var cleanupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("정리").font(.headline)

            Button {
                showCleanupConfirmation = true
            } label: {
                Label("사용 불가능한 디바이스 모두 삭제", systemImage: "trash.circle")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isCleaning)
            .confirmationDialog(
                "사용 불가능한 디바이스를 모두 삭제하시겠습니까?",
                isPresented: $showCleanupConfirmation,
                titleVisibility: .visible
            ) {
                Button("모두 삭제", role: .destructive) {
                    Task { await viewModel.cleanupUnavailableDevices() }
                }
            } message: {
                Text("삭제된 iOS 버전을 사용하던 디바이스가 영구적으로 제거됩니다. 이 작업은 되돌릴 수 없습니다.")
            }

            Text("iOS 버전이 삭제되어 더 이상 사용할 수 없는 디바이스를 일괄 정리합니다.")
                .font(.caption).foregroundStyle(.secondary)
        }
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
        .background(.green.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
