import SwiftUI
import EnvironmentDomain

public struct SettingsView: View {

    @Bindable var viewModel: SettingsViewModel
    @State private var showFileImporter = false

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            Section("Google Drive 연동") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("서비스 계정 키")
                        Spacer()
                        if viewModel.hasServiceAccountKey {
                            Label("등록됨", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green).font(.caption)
                        } else {
                            Label("미등록", systemImage: "xmark.circle")
                                .foregroundStyle(.secondary).font(.caption)
                        }
                    }
                    HStack(spacing: 8) {
                        Button("JSON 키 파일 등록") { showFileImporter = true }
                            .buttonStyle(.bordered)
                        if viewModel.hasServiceAccountKey {
                            Button("삭제", role: .destructive) { viewModel.removeServiceAccountKey() }
                                .buttonStyle(.bordered).tint(.red)
                        }
                    }
                    Text("GCP 서비스 계정 키 JSON 파일을 등록하면 Google Drive에서 빌드를 다운로드할 수 있습니다.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                TextField("Google Drive 폴더 ID", text: $viewModel.folderId)
                    .textFieldStyle(.roundedBorder)
            }

            if let status = viewModel.environmentStatus {
                Section("환경 정보") {
                    infoRow("Xcode", value: status.xcodeVersion ?? "미설치")
                    infoRow("경로", value: status.xcodePath ?? "-")
                    infoRow("런타임", value: status.availableRuntimes.joined(separator: ", "))
                }
            }

            if let message = viewModel.statusMessage {
                Section {
                    Label(message, systemImage: viewModel.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(viewModel.isError ? .red : .green)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 400)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                viewModel.importServiceAccountKey(from: url)
            }
        }
        .task { await viewModel.onAppear() }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 60, alignment: .leading)
            Text(value).font(.caption).textSelection(.enabled)
        }
    }
}
