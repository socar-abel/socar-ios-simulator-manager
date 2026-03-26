import SwiftUI
import SimulatorDomainInterface
import Design

public struct IOSVersionView: View {

    @Bindable var viewModel: IOSVersionViewModel

    @State private var versionToDelete: InstalledIOSVersion?

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

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error) { viewModel.dismissError() }
                }
                if let success = viewModel.successMessage {
                    successBanner(success)
                }
            }
            .padding(24)
        }
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
        HStack(spacing: 12) {
            Image(systemName: "cpu")
                .font(.title2)
                .foregroundStyle(version.isReady ? .blue : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(version.displayName).font(.body).fontWeight(.medium)
                    Text("v\(version.version)")
                        .font(.caption)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
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
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8)
                    Text("\(name) 다운로드 중... (수십 분 소요될 수 있습니다)")
                        .font(.callout).foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if viewModel.downloadableIOSVersions.isEmpty && !viewModel.isLoadingDownloadable {
                Text("모든 iOS 버전이 이미 설치되어 있습니다.")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
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

            Button {
                Task { await viewModel.downloadIOSVersion(version) }
            } label: {
                Label("다운로드", systemImage: "arrow.down.to.line")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isDownloading)
        }
        .padding(10)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Cleanup

    private var cleanupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("정리").font(.headline)

            Button {
                Task { await viewModel.cleanupUnavailableDevices() }
            } label: {
                Label("사용 불가능한 디바이스 모두 삭제", systemImage: "trash.circle")
            }
            .buttonStyle(.bordered)

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
        .background(.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
