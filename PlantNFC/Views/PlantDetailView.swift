import SwiftUI

struct PlantDetailView: View {
    @ObservedObject var plant: PlantEntity
    @EnvironmentObject var nfcManager: NFCManager
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var showScanSheet = false
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showWaterConfirmation = false
    @State private var pulseAnimation = false
    @State private var timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero card
                heroCard

                // Status card
                statusCard

                // Water button
                waterButton

                // Quick info
                infoGrid

                // NFC section
                nfcSection

                // Danger zone
                deleteButton
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.plantBg.ignoresSafeArea())
        .navigationTitle(plant.wrappedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Bewerk") {
                    showEditSheet = true
                }
                .foregroundColor(.plantGreen)
            }
        }
        .sheet(isPresented: $showScanSheet) {
            NFCScanSheet(mode: .readForWatering, isPresented: $showScanSheet)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(nfcManager)
        }
        .sheet(isPresented: $showEditSheet) {
            AddEditPlantView(plantToEdit: plant)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(nfcManager)
        }
        .alert("Plant verwijderen?", isPresented: $showDeleteAlert) {
            Button("Verwijderen", role: .destructive) {
                PersistenceController.shared.deletePlant(plant)
                dismiss()
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            Text("Dit verwijdert \(plant.wrappedName) en al zijn gegevens.")
        }
        .onReceive(timer) { _ in
            // Refresh countdown
        }
    }

    // MARK: - Hero Card
    private var heroCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [plant.waterStatus.color.opacity(0.2), plant.waterStatus.color.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)

                Text(plant.wrappedEmoji)
                    .font(.system(size: 64))
            }
            .onAppear { pulseAnimation = true }

            Text(plant.wrappedName)
                .font(.title.bold())

            StatusBadge(status: plant.waterStatus)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .plantCard()
    }

    // MARK: - Status Card
    private var statusCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Volgende waterbeurt")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(plant.intervalDisplayText)
                    .font(.subheadline.bold())
                    .foregroundColor(.plantGreen)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Countdown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(plant.countdownText)
                        .font(.title3.bold())
                        .foregroundColor(plant.waterStatus.color)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Laatste scan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(plant.lastWateredText)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .plantCard()
    }

    // MARK: - Water Button
    private var waterButton: some View {
        VStack(spacing: 12) {
            // NFC Scan button
            Button {
                showScanSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.title3)
                    Text("Scan NFC-tag")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.plantGreen, .plantGreenDark],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .plantGreen.opacity(0.35), radius: 10, x: 0, y: 5)
            }

            // Manual water button
            Button {
                withAnimation { showWaterConfirmation = true }
                PersistenceController.shared.waterPlant(plant)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { showWaterConfirmation = false }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                    Text("Handmatig water geven")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.12))
                .foregroundColor(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if showWaterConfirmation {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Plant heeft water gekregen 🌱")
                }
                .font(.subheadline.bold())
                .foregroundColor(.plantGreen)
                .padding(.vertical, 6)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .plantCard()
    }

    // MARK: - Info Grid
    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            infoTile(icon: "clock", label: "Interval", value: plant.intervalDisplayText, color: .plantGreen)
            infoTile(icon: "calendar", label: "Toegevoegd", value: plantAddedText, color: .blue)
            if let next = plant.nextWaterDate {
                infoTile(icon: "drop.fill", label: "Volgende keer", value: formatDate(next), color: .cyan)
            }
            if plant.lastWatered != nil {
                infoTile(icon: "checkmark.seal.fill", label: "Laatste scan", value: plant.lastWateredFullText, color: .purple)
            }
        }
    }

    private func infoTile(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .plantCard()
    }

    // MARK: - NFC Section
    private var nfcSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("NFC-koppeling", systemImage: "antenna.radiowaves.left.and.right")
                .font(.headline)

            if plant.isLinkedToNFC {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.plantGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gekoppeld")
                            .font(.subheadline.bold())
                            .foregroundColor(.plantGreen)
                        Text(plant.wrappedNfcID ?? "")
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button("Wijzig") {
                        // trigger new NFC link scan
                        nfcManager.startScanning(mode: .readForLinking) { newID in
                            PersistenceController.shared.linkNFC(id: newID, to: plant)
                        }
                    }
                    .font(.caption.bold())
                    .foregroundColor(.plantGreen)
                }
            } else {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("Nog niet gekoppeld aan NFC-tag")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    Spacer()
                    Button("Koppel") {
                        nfcManager.startScanning(mode: .readForLinking) { newID in
                            PersistenceController.shared.linkNFC(id: newID, to: plant)
                        }
                    }
                    .font(.caption.bold())
                    .foregroundColor(.plantGreen)
                }
            }
        }
        .padding(16)
        .plantCard()
    }

    // MARK: - Delete Button
    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            Label("Plant verwijderen", systemImage: "trash")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(.red)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helpers
    private var plantAddedText: String {
        guard let date = plant.createdAt else { return "Onbekend" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }
}
