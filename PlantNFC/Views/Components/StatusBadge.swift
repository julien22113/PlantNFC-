import SwiftUI

struct StatusBadge: View {
    let status: WaterStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            Text(status.label)
                .font(.caption.bold())
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Water Interval Picker
struct WaterIntervalPicker: View {
    @Binding var selectedHours: Double
    @Binding var selectedPreset: WaterIntervalPreset
    @Binding var customDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Water-interval")
                .font(.headline)

            // Preset grid
            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible())
            ], spacing: 8) {
                ForEach(WaterIntervalPreset.allCases) { preset in
                    Button {
                        selectedPreset = preset
                        if let h = preset.hours {
                            selectedHours = h
                        }
                    } label: {
                        Text(preset.rawValue)
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedPreset == preset ? Color.plantGreen : Color.plantSurface)
                            .foregroundColor(selectedPreset == preset ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            // Custom days input
            if selectedPreset == .custom {
                HStack {
                    Text("Aantal dagen:")
                    Stepper("\(customDays) dag\(customDays == 1 ? "" : "en")", value: $customDays, in: 1...60)
                        .onChange(of: customDays) { _, newVal in
                            selectedHours = Double(newVal) * 24
                        }
                }
                .padding(12)
                .background(Color.plantSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
