import SwiftUI
import SimulatorDomainInterface
import DesignKit

public struct DeviceListView: View {

    @Bindable var viewModel: DeviceListViewModel
    @State private var showCreateSheet = false

    public init(viewModel: DeviceListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HSplitView {
            listPanel
                .frame(minWidth: 250, idealWidth: 300)
            detailPanel
                .frame(minWidth: 350)
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateDeviceSheet(viewModel: viewModel)
        }
        .toolbar {
            ToolbarItem {
                Button { showCreateSheet = true } label: {
                    Label("디바이스 생성", systemImage: "plus")
                }
            }
            ToolbarItem {
                Button { Task { await viewModel.refreshAll() } } label: {
                    Label("새로고침", systemImage: "arrow.clockwise")
                }
            }
        }
        .task { await viewModel.onAppear() }
    }

    // MARK: - List

    private var listPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("디바이스")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.devices.count)개")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if viewModel.isLoading && viewModel.devices.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.devices.isEmpty {
                ContentUnavailableView(
                    "디바이스가 없습니다",
                    systemImage: "iphone.slash",
                    description: Text("디바이스 생성 버튼을 눌러주세요")
                )
            } else {
                List(selection: $viewModel.selectedDevice) {
                    let booted = viewModel.devices.filter(\.isBooted)
                    if !booted.isEmpty {
                        Section("실행중") {
                            ForEach(booted) { device in
                                DeviceRowView(device: device).tag(device)
                            }
                        }
                    }
                    let shutdown = viewModel.devices.filter(\.isShutdown)
                    if !shutdown.isEmpty {
                        Section("종료됨") {
                            ForEach(shutdown) { device in
                                DeviceRowView(device: device).tag(device)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailPanel: some View {
        if let device = viewModel.selectedDevice {
            DeviceDetailView(device: device, viewModel: viewModel)
        } else {
            ContentUnavailableView(
                "디바이스를 선택하세요",
                systemImage: "hand.tap"
            )
        }
    }
}
