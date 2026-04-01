import SwiftUI
import Domain
import Core

struct DeviceDetailView: View {

    @Bindable var viewModel: DeviceListViewModel
    var buildListViewModel: BuildListViewModel?

    @State private var isPerformingAction = false
    @State private var showDeleteConfirmation = false
    @State private var showFilePicker = false
    @State private var showAppListPicker = false
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
        .sheet(isPresented: $showAppListPicker) {
            if let device, let buildVM = buildListViewModel {
                AppListPickerSheet(deviceUDID: device.udid, viewModel: viewModel, buildListViewModel: buildVM) {
                    showAppListPicker = false
                }
            }
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
                ActionButton("앱 목록에서 설치", icon: "list.bullet", style: .primary) {
                    showAppListPicker = true
                }
                ActionButton("파일에서 직접 설치", icon: "folder", style: .secondary) {
                    showFilePicker = true
                }
            }
            if !installProgressMessage.isEmpty {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8)
                    Text(installProgressMessage).font(.caption).foregroundStyle(.secondary)
                }
            }
            Text("💡 '앱 목록'에서 설치하거나, Google Drive에서 다운받은 .app 또는 .zip 파일을 직접 선택할 수 있습니다.")
                .font(.caption).foregroundStyle(.tertiary)
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

// MARK: - App List Picker Sheet

struct AppListPickerSheet: View {
    let deviceUDID: String
    @Bindable var viewModel: DeviceListViewModel
    @Bindable var buildListViewModel: BuildListViewModel
    let onDismiss: () -> Void

    @State private var isInstalling = false
    @State private var installError: String?

    private var localApps: [URL] {
        buildListViewModel.localAppsList
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("앱 목록에서 설치").font(.headline)
                Spacer()
                Button("취소") { onDismiss() }
                    .buttonStyle(.borderless)
                    .keyboardShortcut(.cancelAction)
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
            } else if localApps.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("앱 목록이 비어있습니다")
                        .font(.headline).foregroundStyle(.secondary)
                    Text("'앱 목록' 탭에서 먼저 빌드 파일을 추가해주세요.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(localApps, id: \.path) { appURL in
                        let info = AppBundleInfo(appURL: appURL)
                        Button {
                            install(appURL: appURL)
                        } label: {
                            HStack(spacing: 12) {
                                if let icon = info.iconImage {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .clipShape(RoundedRectangle(cornerRadius: 7))
                                } else {
                                    Image(systemName: "app.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                        .frame(width: 32, height: 32)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(info.displayName ?? appURL.lastPathComponent)
                                        .fontWeight(.medium)
                                    Text(info.versionDescription)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("설치").foregroundStyle(.blue)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(width: 450, height: 400)
    }

    private func install(appURL: URL) {
        isInstalling = true
        installError = nil
        Task {
            do {
                try await viewModel.installApp(udid: deviceUDID, appPath: appURL)
                viewModel.successMessage = "\(appURL.lastPathComponent)을(를) 설치했습니다."
                onDismiss()
            } catch {
                installError = error.localizedDescription
                isInstalling = false
            }
        }
    }
}
