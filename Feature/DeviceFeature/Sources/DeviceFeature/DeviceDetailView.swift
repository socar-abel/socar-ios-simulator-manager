import SwiftUI
import SimulatorDomainInterface
import Design

struct DeviceDetailView: View {

    let device: SimulatorDevice
    @Bindable var viewModel: DeviceListViewModel

    @State private var isPerformingAction = false
    @State private var showDeleteConfirmation = false
    @State private var showFilePicker = false
    @State private var installProgressMessage = ""

    private let socarBundleId = "kr.socar.socarapp"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                Divider()
                controls
                if device.isBooted {
                    Divider()
                    appManagement
                }
                Divider()
                info

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error) { viewModel.dismissError() }
                }
            }
            .padding(24)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.application, .zip],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .confirmationDialog(
            "'\(device.name)' 디바이스를 삭제하시겠습니까?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) { Task { await viewModel.delete(udid: device.udid) } }
        } message: {
            Text("이 작업은 되돌릴 수 없습니다.")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: device.name.lowercased().contains("ipad") ? "ipad" : "iphone")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name).font(.title2).fontWeight(.bold)
                HStack(spacing: 8) {
                    StatusBadge(isActive: device.isBooted)
                    Text(device.stateDisplayName).font(.subheadline).foregroundStyle(.secondary)
                }
                if let runtime = device.runtimeDisplayName {
                    Text(runtime).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("제어").font(.headline)
            HStack(spacing: 12) {
                if device.isBooted {
                    ActionButton("종료", icon: "stop.fill", style: .secondary, isDisabled: isPerformingAction) {
                        performAction { await viewModel.shutdown(udid: device.udid) }
                    }
                } else {
                    ActionButton("부팅", icon: "play.fill", style: .primary, isDisabled: isPerformingAction) {
                        performAction { await viewModel.boot(udid: device.udid) }
                    }
                }
                ActionButton("삭제", icon: "trash", style: .destructive, isDisabled: isPerformingAction) {
                    showDeleteConfirmation = true
                }
            }
        }
    }

    private var appManagement: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("앱 관리").font(.headline)
            HStack(spacing: 12) {
                ActionButton("앱 설치 (.app / .zip)", icon: "square.and.arrow.down", style: .primary) {
                    showFilePicker = true
                }
                ActionButton("SOCAR 앱 실행", icon: "play.rectangle", style: .secondary) {
                    performAction {
                        try await viewModel.launchApp(udid: device.udid, bundleId: socarBundleId)
                    }
                }
            }
            if !installProgressMessage.isEmpty {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8)
                    Text(installProgressMessage).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("정보").font(.headline)
            infoRow("UDID", value: device.udid)
            if let dt = device.deviceTypeIdentifier { infoRow("디바이스 타입", value: dt) }
            if let rt = device.runtimeIdentifier { infoRow("런타임", value: rt) }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 100, alignment: .leading)
            Text(value).font(.caption).textSelection(.enabled)
        }
    }

    private func performAction(_ action: @escaping () async throws -> Void) {
        Task {
            isPerformingAction = true
            defer { isPerformingAction = false }
            do { try await action() } catch { viewModel.errorMessage = error.localizedDescription }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        Task {
            installProgressMessage = "앱 설치 중..."
            defer { installProgressMessage = "" }
            do {
                try await viewModel.installApp(udid: device.udid, appPath: url)
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}
