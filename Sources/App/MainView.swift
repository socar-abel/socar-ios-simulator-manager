import SwiftUI
import Core
import Domain
import Data
import Feature

struct MainView: View {

    @Bindable var coordinator: AppCoordinator

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
            Label("빌드", systemImage: "shippingbox")
                .tag(AppRoute.builds)
            Label("iOS 버전", systemImage: "cpu")
                .tag(AppRoute.iosVersions)
            Divider()
            Label("가이드", systemImage: "book")
                .tag(AppRoute.guide)
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private var warningBanner: some View {
        if let warnings = coordinator.environmentStatus?.warnings, !warnings.isEmpty {
            ForEach(warnings, id: \.title) { warning in
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(warning.title).font(.callout).fontWeight(.medium)
                    Text("—").foregroundStyle(.secondary)
                    Text(warning.description).font(.callout).foregroundStyle(.secondary)
                    Spacer()
                    if case .noRuntimesAvailable = warning {
                        Button("iOS 버전 탭으로 이동") {
                            coordinator.selectedTab = .iosVersions
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.orange.opacity(0.08))
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch coordinator.selectedTab {
        case .devices:
            if let vm = coordinator.deviceListViewModel {
                DeviceListView(viewModel: vm)
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
