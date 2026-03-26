import SwiftUI
import SimulatorDomainInterface
import Design

struct DeviceRowView: View {

    let device: SimulatorDevice

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: device.name.lowercased().contains("ipad") ? "ipad" : "iphone")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.body)
                    .fontWeight(.medium)
                if let runtime = device.runtimeDisplayName {
                    Text(runtime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
            StatusBadge(isActive: device.isBooted)
        }
        .padding(.vertical, 2)
    }
}
