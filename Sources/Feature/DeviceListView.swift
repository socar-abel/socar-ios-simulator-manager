import SwiftUI
import Domain
import Core

public struct DeviceListView: View {

    @Bindable var viewModel: DeviceListViewModel
    var buildListViewModel: BuildListViewModel?
    @State private var showCreateSheet = false
    @State private var showDeleteSelectedConfirmation = false

    public init(viewModel: DeviceListViewModel, buildListViewModel: BuildListViewModel? = nil) {
        self.viewModel = viewModel
        self.buildListViewModel = buildListViewModel
    }

    public var body: some View {
        ZStack {
            HStack(spacing: 0) {
                listPanel
                    .frame(minWidth: 320, idealWidth: 360)
                Divider()
                detailPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // 삭제 중 오버레이
            if viewModel.isDeleting, let name = viewModel.deletingDeviceName {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("'\(name)' 삭제 중...")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // 생성 중 오버레이
            if viewModel.isCreating, let name = viewModel.creatingDeviceName {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("'\(name)' 생성 중...")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error) { viewModel.dismissError() }
                        .padding(.horizontal, 16)
                }
                if let success = viewModel.successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text(success).font(.callout)
                        Spacer()
                        Button("닫기") { viewModel.dismissSuccess() }.buttonStyle(.borderless)
                    }
                    .padding(12)
                    .background(.green.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { viewModel.dismissSuccess() }
                        }
                    }
                }
            }
            .padding(.bottom, 12)
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.successMessage)
        .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
        .sheet(isPresented: $showCreateSheet) {
            CreateDeviceSheet(viewModel: viewModel)
        }
        .toolbar {
            ToolbarItem {
                Button("디바이스 추가") { showCreateSheet = true }
                    .buttonStyle(.bordered)
            }
            ToolbarItem {
                Button { Task { await viewModel.refreshAll() } } label: {
                    Label("새로고침", systemImage: "arrow.clockwise")
                }
            }
        }
        .task { await viewModel.onAppear() }
        .confirmationDialog(
            "\(viewModel.selectedCount)개 디바이스를 삭제하시겠습니까?",
            isPresented: $showDeleteSelectedConfirmation,
            titleVisibility: .visible
        ) {
            Button("삭제 (\(viewModel.selectedCount)개)", role: .destructive) {
                Task { await viewModel.deleteSelected() }
            }
        } message: {
            Text("선택한 디바이스가 모두 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
        }
    }

    // MARK: - List

    private var listPanel: some View {
        VStack(spacing: 0) {
            listHeader
            Divider()

            if viewModel.isLoading && viewModel.devices.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.devices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "iphone.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("디바이스가 없습니다")
                        .font(.headline).foregroundStyle(.secondary)
                    Text("상단의 '디바이스 추가' 버튼을 눌러주세요")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                deviceList
            }
        }
    }

    private var listHeader: some View {
        HStack {
            if viewModel.isMultiSelectMode {
                Button("전체 선택") { viewModel.selectAll() }
                    .buttonStyle(.borderless).font(.caption)
                Button("선택 해제") { viewModel.deselectAll() }
                    .buttonStyle(.borderless).font(.caption)
                Spacer()
                Button("취소") { viewModel.exitMultiSelectMode() }
                    .buttonStyle(.borderless).font(.caption)
            } else {
                Text("디바이스")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.filteredAndSortedDevices.count)개")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    viewModel.isMultiSelectMode = true
                } label: {
                    Label("선택", systemImage: "checkmark.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var sortFilterBar: some View {
        HStack(spacing: 8) {
            Picker("정렬", selection: $viewModel.sortOption) {
                ForEach(DeviceSortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()

            Picker("필터", selection: $viewModel.notchFilter) {
                ForEach(NotchFilter.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private var deviceList: some View {
        VStack(spacing: 0) {
            sortFilterBar
            Divider()
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    let sorted = viewModel.filteredAndSortedDevices
                    let booted = sorted.filter(\.isBooted)
                    if !booted.isEmpty {
                        Section {
                            ForEach(booted, id: \SimulatorDevice.compositeId) { device in
                                deviceRow(device)
                                Divider().padding(.leading, 40)
                            }
                        } header: {
                            sectionHeader("실행중")
                        }
                    }
                    let shutdown = sorted.filter(\.isShutdown)
                    if !shutdown.isEmpty {
                        Section {
                            ForEach(shutdown, id: \SimulatorDevice.compositeId) { device in
                                deviceRow(device)
                                Divider().padding(.leading, 40)
                            }
                        } header: {
                            sectionHeader("종료됨")
                        }
                    }
                    let other = sorted.filter { !$0.isBooted && !$0.isShutdown }
                    if !other.isEmpty {
                        Section {
                            ForEach(other, id: \SimulatorDevice.compositeId) { device in
                                deviceRow(device)
                                Divider().padding(.leading, 40)
                            }
                        } header: {
                            sectionHeader("기타")
                        }
                    }
                }
            }

            if viewModel.isMultiSelectMode && viewModel.selectedCount > 0 {
                deleteBar
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption).fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.bar)
    }

    private func deviceRow(_ device: SimulatorDevice) -> some View {
        let isSelected = viewModel.selectedDevice?.udid == device.udid && !viewModel.isMultiSelectMode

        return HStack(spacing: 8) {
            if viewModel.isMultiSelectMode {
                Image(systemName: viewModel.isSelected(device) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(viewModel.isSelected(device) ? .blue : .secondary)
                    .font(.title3)
                    .padding(.leading, 16)
            }
            DeviceRowView(device: device, profile: viewModel.profile(for: device))
        }
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.isMultiSelectMode {
                viewModel.toggleSelection(device)
            } else {
                viewModel.selectedDevice = device
            }
        }
    }

    private var deleteBar: some View {
        HStack {
            Text("\(viewModel.selectedCount)개 선택됨")
                .font(.callout).fontWeight(.medium)
            Spacer()
            Button(role: .destructive) {
                showDeleteSelectedConfirmation = true
            } label: {
                Label("선택 삭제", systemImage: "trash")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(viewModel.isDeleting)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailPanel: some View {
        if viewModel.selectedDevice != nil, !viewModel.isMultiSelectMode {
            DeviceDetailView(viewModel: viewModel, buildListViewModel: buildListViewModel)
        } else if viewModel.isMultiSelectMode {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text("디바이스를 선택하세요")
                    .font(.headline).foregroundStyle(.secondary)
                Text("삭제할 디바이스를 체크한 후 하단의 '선택 삭제' 버튼을 눌러주세요")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text("디바이스를 선택하세요")
                    .font(.headline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
