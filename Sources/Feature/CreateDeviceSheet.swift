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

    private var iOSRuntimes: [SimulatorIOSVersion] {
        viewModel.runtimes.filter(\.isIOS)
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
                        ForEach(iOSRuntimes) { Text("\($0.name) (\($0.version))").tag($0 as SimulatorIOSVersion?) }
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
        .frame(width: 450, height: 380)
        .onChange(of: selectedDeviceType) { _, newType in
            if deviceName.isEmpty, let t = newType { deviceName = t.name }
        }
    }

    private func create() {
        guard let dt = selectedDeviceType, let rt = selectedRuntime else { return }
        isCreating = true
        Task {
            defer { isCreating = false }
            do {
                let name = deviceName.isEmpty ? dt.name : deviceName
                try await viewModel.createDevice(name: name, deviceType: dt, runtime: rt)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
