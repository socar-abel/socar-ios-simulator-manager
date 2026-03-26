import SwiftUI
import SimulatorDomainInterface
import Design

public struct RuntimeView: View {

    @Bindable var viewModel: RuntimeViewModel

    @State private var runtimeToDelete: InstalledRuntime?

    public init(viewModel: RuntimeViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                diskUsageSection
                Divider()
                runtimesSection
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
            "런타임을 삭제하시겠습니까?",
            isPresented: .init(
                get: { runtimeToDelete != nil },
                set: { if !$0 { runtimeToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let runtime = runtimeToDelete {
                Button("삭제 (\(runtime.displaySize))", role: .destructive) {
                    Task { await viewModel.deleteRuntime(runtime) }
                    runtimeToDelete = nil
                }
            }
        } message: {
            if let runtime = runtimeToDelete {
                Text("\(runtime.displayName) (\(runtime.displaySize))을(를) 삭제합니다. 이 런타임을 사용하는 디바이스도 사용할 수 없게 됩니다.")
            }
        }
    }

    // MARK: - Disk Usage

    private var diskUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("디스크 사용량").font(.headline)

            if let disk = viewModel.diskUsage {
                HStack(spacing: 24) {
                    diskItem(label: "런타임", value: disk.runtimesDisplay, icon: "cpu", color: .blue)
                    diskItem(label: "디바이스", value: disk.devicesDisplay, icon: "iphone", color: .green)
                    diskItem(label: "합계", value: disk.totalDisplay, icon: "externaldrive", color: .orange)
                }

                // 비율 바
                GeometryReader { geo in
                    let total = max(disk.totalBytes, 1)
                    HStack(spacing: 2) {
                        Rectangle()
                            .fill(.blue)
                            .frame(width: geo.size.width * CGFloat(disk.runtimesBytes) / CGFloat(total))
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

    // MARK: - Runtimes

    private var runtimesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("설치된 런타임").font(.headline)
                Spacer()
                if viewModel.isDownloading {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.7)
                        Text("다운로드 중...").font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        Task { await viewModel.downloadiOSRuntime() }
                    } label: {
                        Label("iOS 런타임 다운로드", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }

            if viewModel.installedRuntimes.isEmpty && !viewModel.isLoading {
                VStack(spacing: 8) {
                    Image(systemName: "cpu").font(.largeTitle).foregroundStyle(.secondary)
                    Text("설치된 iOS 런타임이 없습니다").foregroundStyle(.secondary)
                    Text("런타임을 다운로드하면 시뮬레이터 디바이스를 생성할 수 있습니다.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(viewModel.installedRuntimes) { runtime in
                    runtimeRow(runtime)
                }
            }
        }
    }

    private func runtimeRow(_ runtime: InstalledRuntime) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "cpu")
                .font(.title2)
                .foregroundStyle(runtime.isReady ? .blue : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(runtime.displayName).font(.body).fontWeight(.medium)
                    Text("v\(runtime.version)")
                        .font(.caption)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
                HStack(spacing: 8) {
                    Text(runtime.displaySize).font(.caption).foregroundStyle(.secondary)
                    Text(runtime.state).font(.caption).foregroundStyle(runtime.isReady ? .green : .orange)
                }
            }

            Spacer()

            if runtime.isDeletable {
                Button {
                    runtimeToDelete = runtime
                } label: {
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

            Text("런타임이 삭제되어 더 이상 사용할 수 없는 디바이스를 일괄 정리합니다.")
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
