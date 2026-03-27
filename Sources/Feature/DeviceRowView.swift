import SwiftUI
import Domain
import Core

struct DeviceRowView: View {

    let device: SimulatorDevice
    var profile: DeviceTypeProfile?

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
                HStack(spacing: 6) {
                    if let runtime = device.runtimeDisplayName {
                        Text(runtime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let p = profile {
                        Text(p.screenSizeDescription)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()
            StatusBadge(isActive: device.isBooted)
        }
        .padding(.vertical, 2)
    }
}
