import SwiftUI
import Domain
import Core

struct DeviceRowView: View {

    let device: SimulatorDevice
    var profile: DeviceTypeProfile?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: device.name.lowercased().contains("ipad") ? "ipad" : "iphone")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.title3)
                    .fontWeight(.medium)
                HStack(spacing: 8) {
                    if let runtime = device.runtimeDisplayName {
                        Text(runtime)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if let p = profile {
                        Text(p.screenSizeDescription)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()
            StatusBadge(isActive: device.isBooted)
                .padding(.trailing, 24)
        }
        .padding(.leading, 24)
        .padding(.vertical, 6)
    }
}
