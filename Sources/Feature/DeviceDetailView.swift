import SwiftUI
import Domain
import Core

struct DeviceDetailView: View {

    @Bindable var viewModel: DeviceListViewModel
    var buildListViewModel: BuildListViewModel?
    var onNavigateToBuilds: (() -> Void)?

    @State private var isPerformingAction = false
    @State private var showDeleteConfirmation = false
    @State private var showFilePicker = false
    @State private var showAppListPicker = false
    @State private var installProgressMessage = ""
    @State private var deepLinkURL = ""
    @State private var isEditingName = false
    @State private var editingName = ""
    @State private var locationLatitude = ""
    @State private var locationLongitude = ""
    @State private var pushTitle = "쏘카"
    @State private var pushBody = ""
    @State private var pushDeepLink = ""

    private var device: SimulatorDevice? { viewModel.selectedDevice }

    var body: some View {
        Group {
            if let device {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header(device)
                        Divider()
                        appInstall(device)
                        Divider()
                        controls(device)
                        if device.isBooted {
                            Divider()
                            locationSection(device)
                            Divider()
                            deepLinkSection(device)
                            Divider()
                            pushTestSection(device)
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
                    ActionButton("흔들기", icon: "iphone.gen3.radiowaves.left.and.right", style: .secondary, isDisabled: isPerformingAction) {
                        performAction { await viewModel.shake(udid: device.udid) }
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

    // MARK: - Location

    private func locationSection(_ device: SimulatorDevice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("위치 설정").font(.headline)

            // 프리셋 위치
            Text("자주 쓰는 위치").font(.subheadline).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                ForEach(LocationPreset.all) { preset in
                    Button {
                        applyLocation(preset, device: device)
                    } label: {
                        HStack(spacing: 6) {
                            Text(preset.emoji)
                            Text(preset.name).font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.background.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }

            // 직접 입력
            Text("직접 입력").font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                TextField("위도 (예: 37.5665)", text: $locationLatitude)
                    .textFieldStyle(.roundedBorder)
                TextField("경도 (예: 126.9780)", text: $locationLongitude)
                    .textFieldStyle(.roundedBorder)
                Button("설정") {
                    guard let lat = Double(locationLatitude), let lon = Double(locationLongitude) else {
                        viewModel.errorMessage = "올바른 좌표를 입력해주세요. (예: 37.5665, 126.9780)"
                        return
                    }
                    performAction {
                        await viewModel.setLocation(udid: device.udid, latitude: lat, longitude: lon)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(locationLatitude.isEmpty || locationLongitude.isEmpty)
            }

            Text("시뮬레이터의 GPS 위치를 변경합니다. 쏘카앱의 지도/차량 검색 테스트에 유용합니다.")
                .font(.caption).foregroundStyle(.tertiary)
        }
    }

    private func applyLocation(_ preset: LocationPreset, device: SimulatorDevice) {
        locationLatitude = String(preset.latitude)
        locationLongitude = String(preset.longitude)
        performAction {
            await viewModel.setLocation(udid: device.udid, latitude: preset.latitude, longitude: preset.longitude)
        }
    }

    // MARK: - Push Test

    private func pushTestSection(_ device: SimulatorDevice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("푸시 테스트").font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("타이틀")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .trailing)
                    TextField("쏘카", text: $pushTitle)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 8) {
                    Text("내용")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .trailing)
                    TextField("푸시 알림 내용을 입력하세요", text: $pushBody)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 8) {
                    Text("딥링크")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .trailing)
                    TextField("socar-v2://path (선택)", text: $pushDeepLink)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack {
                Spacer()
                Button("전송") {
                    sendPush(device: device)
                }
                .buttonStyle(.borderedProminent)
                .disabled(pushBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPerformingAction)
            }

            Text("시뮬레이터에 푸시 알림을 전송합니다.")
                .font(.caption).foregroundStyle(.tertiary)
        }
    }

    private let socarBundleIds = ["kr.socar.socarapp.debug", "kr.socar.socarapp"]

    private func buildPushPayload() -> String {
        let title = pushTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "쏘카" : pushTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = pushBody.trimmingCharacters(in: .whitespacesAndNewlines)
        let deepLink = pushDeepLink.trimmingCharacters(in: .whitespacesAndNewlines)

        var payload: [String: Any] = [
            "aps": [
                "alert": [
                    "title": title,
                    "body": body,
                ],
                "sound": "default",
            ] as [String: Any],
        ]

        if !deepLink.isEmpty {
            payload["land_page"] = deepLink
        }

        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    private func sendPush(device: SimulatorDevice) {
        let body = pushBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        let payload = buildPushPayload()
        performAction {
            for bundleId in socarBundleIds {
                await viewModel.sendPush(
                    udid: device.udid,
                    bundleId: bundleId,
                    payload: payload
                )
            }
            viewModel.successMessage = "푸시 알림이 전송되었습니다."
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

    private func appInstall(_ device: SimulatorDevice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("앱 설치").font(.headline)
            HStack(spacing: 12) {
                ActionButton("등록된 앱에서 설치하기", icon: "list.bullet", style: .primary) {
                    if buildListViewModel?.localAppsList.isEmpty == false {
                        showAppListPicker = true
                    } else {
                        onNavigateToBuilds?()
                    }
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
                Text("등록된 앱에서 설치하기").font(.headline)
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
                    Text("'앱 설치하기' 탭에서 먼저 빌드 파일을 추가해주세요.")
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
