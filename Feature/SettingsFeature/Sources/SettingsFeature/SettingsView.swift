import SwiftUI
import EnvironmentDomain

public struct SettingsView: View {

    @Bindable var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            if let status = viewModel.environmentStatus {
                Section("환경 정보") {
                    infoRow("Xcode", value: status.xcodeVersion ?? "미설치")
                    infoRow("경로", value: status.xcodePath ?? "-")
                    infoRow("iOS 버전", value: status.availableRuntimes.isEmpty
                        ? "없음"
                        : status.availableRuntimes.joined(separator: ", ")
                    )
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 300)
        .task { await viewModel.onAppear() }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(.caption).foregroundStyle(.secondary).frame(width: 60, alignment: .leading)
            Text(value).font(.caption).textSelection(.enabled)
        }
    }
}
