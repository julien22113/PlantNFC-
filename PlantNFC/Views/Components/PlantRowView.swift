import SwiftUI

struct PlantRowView: View {
    let plant: PlantEntity
    @State private var appear = false

    var body: some View {
        HStack(spacing: 14) {
            // Emoji circle
            ZStack {
                Circle()
                    .fill(plant.waterStatus.color.opacity(0.15))
                    .frame(width: 58, height: 58)
                Text(plant.wrappedEmoji)
                    .font(.system(size: 30))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(plant.wrappedName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    StatusBadge(status: plant.waterStatus)
                }

                Text(plant.countdownText)
                    .font(.subheadline.bold())
                    .foregroundColor(plant.waterStatus.color)

                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                        .foregroundColor(.blue.opacity(0.7))
                    Text(plant.lastWateredText)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if plant.isLinkedToNFC {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.caption)
                            .foregroundColor(.plantGreen.opacity(0.8))
                    } else {
                        Text("Geen NFC")
                            .font(.caption2)
                            .foregroundColor(.orange.opacity(0.8))
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .plantCard()
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
        .onAppear {
            withAnimation(.spring(duration: 0.4)) {
                appear = true
            }
        }
    }
}
