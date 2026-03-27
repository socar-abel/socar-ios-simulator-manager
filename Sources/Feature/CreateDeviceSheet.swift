import SwiftUI
import Domain
import Core

struct CreateDeviceSheet: View {

    @Bindable var viewModel: DeviceListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var deviceName = ""
    @State private var selectedDeviceType: SimulatorDeviceType?
    @State private var selectedRuntime: SimulatorIOSVersion?
    @State private var isCreating = false
    @State private var errorMessage: String?

    private var iPhoneTypes: [SimulatorDeviceType] {
        viewModel.deviceTypes.filter(\.isIPhone)
    }

    /// 선택된 디바이스 타입의 최소 런타임 버전에 따라 호환 가능한 iOS 버전만 표시
    private var compatibleRuntimes: [SimulatorIOSVersion] {
        let iosRuntimes = viewModel.runtimes.filter(\.isIOS)
        guard let minComponents = selectedDeviceType?.minRuntimeVersionComponents else {
            return iosRuntimes
        }
        return iosRuntimes.filter { $0.isCompatible(withMinVersion: minComponents) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("새 디바이스 생성").font(.headline)
                Spacer()
                Button("취소") { dismiss() }.buttonStyle(.borderless).keyboardShortcut(.cancelAction)
            }
            .padding()
            Divider()

            Form {
                Section("디바이스 설정") {
                    Picker("디바이스 타입", selection: $selectedDeviceType) {
                        Text("선택하세요").tag(nil as SimulatorDeviceType?)
                        ForEach(iPhoneTypes) { Text($0.name).tag($0 as SimulatorDeviceType?) }
                    }
                    Picker("iOS 버전", selection: $selectedRuntime) {
                        Text("선택하세요").tag(nil as SimulatorIOSVersion?)
                        ForEach(compatibleRuntimes) { Text("\($0.name) (\($0.version))").tag($0 as SimulatorIOSVersion?) }
                    }
                    if let dt = selectedDeviceType, let minVer = dt.minRuntimeVersionString {
                        Text("최소 지원 iOS 버전: \(minVer)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    TextField("디바이스 이름 (선택)", text: $deviceName)
                        .textFieldStyle(.roundedBorder)
                }
                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                Spacer()
                Button("생성") { create() }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedDeviceType == nil || selectedRuntime == nil || isCreating)
            }
            .padding()
        }
        .frame(width: 450, height: 400)
        .onChange(of: selectedDeviceType) { _, newType in
            if deviceName.isEmpty, let t = newType { deviceName = t.name }
            // 디바이스 타입 변경 시 호환되지 않는 런타임이 선택되어 있으면 초기화
            if let rt = selectedRuntime, !compatibleRuntimes.contains(rt) {
                selectedRuntime = nil
            }
        }
    }

    private func create() {
        guard let dt = selectedDeviceType, let rt = selectedRuntime else { return }
        isCreating = true
        errorMessage = nil
        let name = deviceName.isEmpty ? dt.name : deviceName

        Task {
            defer { isCreating = false }
            do {
                try await viewModel.createDevice(name: name, deviceType: dt, runtime: rt)
                dismiss()
            } catch {
                errorMessage = Self.translateError(error.localizedDescription)
            }
        }
    }

    /// simctl 에러 메시지를 사용자 친화적인 한국어로 변환
    static func translateError(_ message: String) -> String {
        let lowercased = message.lowercased()
        if lowercased.contains("incompatible device") {
            return "이 기기는 선택한 iOS 버전을 지원하지 않습니다. 다른 iOS 버전을 선택해주세요."
        } else if lowercased.contains("invalid runtime") {
            return "해당 iOS 버전이 설치되어 있지 않습니다. 'iOS 버전' 탭에서 설치해주세요."
        } else if lowercased.contains("invalid device type") {
            return "지원하지 않는 기기 타입입니다."
        } else {
            return "디바이스 생성 실패: \(message)"
        }
    }
}
