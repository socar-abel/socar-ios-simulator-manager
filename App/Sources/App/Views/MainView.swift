import SwiftUI
import DeviceFeature
import BuildFeature
import IOSVersionFeature

struct MainView: View {

    @Bindable var coordinator: AppCoordinator

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
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
        }
        .listStyle(.sidebar)
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
        }
    }
}
