import SwiftUI
import Domain
import Core

struct DeviceDetailView: View {

    @Bindable var viewModel: DeviceListViewModel

    @State private var isPerformingAction = false
    @State private var showDeleteConfirmation = false
    @State private var showFilePicker = false
    @State private var installProgressMessage = ""
    @State private var deepLinkURL = ""
    @State private var isEditingName = false
    @State private var editingName = ""

    private var device: SimulatorDevice? { viewModel.selectedDevice }

    var body: some View {
        Group {
            if let device {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header(device)
                        Divider()
                        controls(device)
                        if device.isBooted {
                            Divider()
                            deepLinkSection(device)
                            Divider()
                            appManagement(device)
                        }
                        Divider()
                        info(device)
                    }
                    .padding(24)
                }
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.directory, .zip, .application],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .confirmationDialog(
            "'\(device?.name ?? "")' 디바이스를 삭제하시겠습니까?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            if let device {
                Button("삭제", role: .destructive) { Task { await viewModel.delete(udid: device.udid) } }
            }
        } message: {
            Text("이 작업은 되돌릴 수 없습니다.")
        }
    }

    private func header(_ device: SimulatorDevice) -> some View {
        HStack(spacing: 16) {
            Image(systemName: device.name.lowercased().contains("ipad") ? "ipad" : "iphone")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                if isEditingName {
                    HStack(spacing: 8) {
                        TextField("디바이스 이름", text: $editingName)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                            .fontWeight(.bold)
                            .onSubmit { commitRename(device) }
                            .onExitCommand { isEditingName = false }
                        Button {
                            commitRename(device)
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                        Button {
                            isEditingName = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    HStack(spacing: 8) {
                        Text(device.name).font(.title2).fontWeight(.bold)
                        Button {
                            editingName = device.name
                            isEditingName = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("이름 변경")
                    }
                }
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

    private func commitRename(_ device: SimulatorDevice) {
        let trimmed = editingName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != device.name else {
            isEditingName = false
            return
        }
        isEditingName = false
        performAction {
            await viewModel.renameDevice(udid: device.udid, newName: trimmed)
        }
    }

    private func controls(_ device: SimulatorDevice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("제어").font(.headline)
            HStack(spacing: 12) {
                if device.isBooted {
                    ActionButton("종료", icon: "stop.fill", style: .secondary, isDisabled: isPerformingAction) {
                        performAction { await viewModel.shutdown(udid: device.udid) }
                    }
                    ActionButton("화면 보기", icon: "macwindow", style: .primary, isDisabled: isPerformingAction) {
                        performAction { try await viewModel.bringSimulatorToFront() }
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

    private func deepLinkSection(_ device: SimulatorDevice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("딥링크").font(.headline)
            HStack(spacing: 8) {
                TextField("socar-v2://path 또는 https://...", text: $deepLinkURL)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { openDeepLink(device) }
                Button("실행") { openDeepLink(device) }
                    .buttonStyle(.borderedProminent)
                    .disabled(deepLinkURL.trimmingCharacters(in: .whitespaces).isEmpty || isPerformingAction)
            }
            Text("시뮬레이터에서 딥링크를 열어 특정 화면으로 이동합니다.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func openDeepLink(_ device: SimulatorDevice) {
        let url = deepLinkURL.trimmingCharacters(in: .whitespaces)
        guard !url.isEmpty else { return }
        performAction {
            try await viewModel.openURL(udid: device.udid, url: url)
            try? await viewModel.bringSimulatorToFront()
        }
    }

    private func appManagement(_ device: SimulatorDevice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("앱 관리").font(.headline)
            HStack(spacing: 12) {
                ActionButton("앱 설치 (.app / .zip)", icon: "square.and.arrow.down", style: .primary) {
                    showFilePicker = true
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

    private func info(_ device: SimulatorDevice) -> some View {
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
        guard let device else { return }
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
