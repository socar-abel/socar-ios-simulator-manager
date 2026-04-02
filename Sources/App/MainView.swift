import SwiftUI
import Core
import Domain
import Data
import Feature

struct MainView: View {

    @Bindable var coordinator: AppContainer

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            VStack(spacing: 0) {
                warningBanner
                detail
            }
        }
        .navigationTitle("SOCAR Simulator Manager")
    }

    private var sidebar: some View {
        List(selection: $coordinator.selectedTab) {
            Label("디바이스", systemImage: "iphone")
                .tag(AppRoute.devices)
            Label("앱 등록 및 설치", systemImage: "shippingbox")
                .tag(AppRoute.builds)
            Label("iOS 버전", systemImage: "cpu")
                .tag(AppRoute.iosVersions)
            Divider()
            Label("가이드", systemImage: "book")
                .tag(AppRoute.guide)
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            environmentInfo
        }
    }

    private var environmentInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let status = coordinator.environmentStatus {
                if let xcodeVersion = status.xcodeVersion {
                    Text("Xcode \(xcodeVersion)")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
            Text("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var warningBanner: some View {
        if let warnings = coordinator.environmentStatus?.warnings, !warnings.isEmpty {
            ForEach(warnings, id: \.title) { warning in
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(warning.title).font(.title3).fontWeight(.semibold)
                        Text(warning.description).font(.callout).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if case .noRuntimesAvailable = warning {
                        Button("iOS 버전 설치하러 가기") {
                            coordinator.selectedTab = .iosVersions
                        }
                        .buttonStyle(.borderedProminent).controlSize(.regular)
                    }
                }
                .padding(20)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16).padding(.top, 12)
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch coordinator.selectedTab {
        case .devices:
            if let vm = coordinator.deviceListViewModel {
                DeviceListView(
                    viewModel: vm,
                    buildListViewModel: coordinator.buildListViewModel,
                    onNavigateToIOSVersions: { coordinator.selectedTab = .iosVersions },
                    onNavigateToBuilds: { coordinator.selectedTab = .builds }
                )
            }
        case .builds:
            if let vm = coordinator.buildListViewModel {
                BuildListView(viewModel: vm)
            }
        case .iosVersions:
            if let vm = coordinator.iosVersionViewModel {
                IOSVersionView(viewModel: vm)
            }
        case .guide:
            GuideView()
        }
    }
}
