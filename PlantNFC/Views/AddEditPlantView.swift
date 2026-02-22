import SwiftUI

struct AddEditPlantView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var nfcManager: NFCManager
    @Environment(\.dismiss) private var dismiss

    var plantToEdit: PlantEntity?

    @State private var name = ""
    @State private var selectedEmoji = "🪴"
    @State private var selectedPreset: WaterIntervalPreset = .everyDay
    @State private var selectedHours: Double = 24
    @State private var customDays = 2
    @State private var linkedNFCID: String? = nil
    @State private var isLinkingNFC = false
    @State private var showEmojiPicker = false
    @State private var nfcLinkError: String? = nil

    private var isEditing: Bool { plantToEdit != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Emoji picker
                    emojiSection

                    // Name input
                    nameSection

                    // Interval picker
                    intervalSection

                    // NFC link section
                    nfcLinkSection
                }
                .padding(16)
                .padding(.bottom, 40)
            }
            .background(Color.plantBg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Plant bewerken" : "Nieuwe plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleren") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Opslaan" : "Toevoegen") {
                        save()
                    }
                    .font(.headline)
                    .foregroundColor(canSave ? .plantGreen : .secondary)
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: loadExistingData)
        }
    }

    // MARK: - Emoji Section
    private var emojiSection: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation { showEmojiPicker.toggle() }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.plantGreen.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Text(selectedEmoji)
                        .font(.system(size: 54))
                }
            }

            Text("Tik om emoji te wijzigen")
                .font(.caption)
                .foregroundColor(.secondary)

            if showEmojiPicker {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                    ForEach(plantEmojis, id: \.self) { emoji in
                        Button {
                            selectedEmoji = emoji
                            withAnimation { showEmojiPicker = false }
                        } label: {
                            Text(emoji)
                                .font(.title2)
                                .padding(6)
                                .background(selectedEmoji == emoji ? Color.plantGreen.opacity(0.2) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(12)
                .background(Color.plantCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Name Section
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Naam van de plant", systemImage: "leaf")
                .font(.headline)

            TextField("bijv. Monstera, Cactus...", text: $name)
                .padding(12)
                .background(Color.plantCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .font(.body)
        }
    }

    // MARK: - Interval Section
    private var intervalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            WaterIntervalPicker(
                selectedHours: $selectedHours,
                selectedPreset: $selectedPreset,
                customDays: $customDays
            )
        }
        .padding(16)
        .plantCard()
    }

    // MARK: - NFC Link Section
    private var nfcLinkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("NFC-tag koppelen", systemImage: "antenna.radiowaves.left.and.right")
                .font(.headline)

            if let nfcID = linkedNFCID {
                // Linked
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.plantGreen)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NFC-tag gekoppeld!")
                            .font(.subheadline.bold())
                            .foregroundColor(.plantGreen)
                        Text(nfcID)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button {
                        linkedNFCID = nil
                    } label: {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color.plantGreen.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                // Not linked
                VStack(spacing: 10) {
                    Text("Scan een NFC-tag om deze plant te koppelen. Je kunt dit ook later doen.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Real NFC button
                    Button {
                        isLinkingNFC = true
                        nfcLinkError = nil
                        nfcManager.startScanning(mode: .readForLinking) { tagID in
                            isLinkingNFC = false
                            linkedNFCID = tagID
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isLinkingNFC {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                            }
                            Text(isLinkingNFC ? "Scannen..." : "Scan NFC-tag")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.plantGreen)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isLinkingNFC)

                    // Simulator mock button
                    #if targetEnvironment(simulator)
                    Button {
                        let mockID = "MOCK-\(UUID().uuidString.prefix(8))"
                        linkedNFCID = mockID
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "wand.and.stars")
                            Text("Simuleer NFC (Simulator)")
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    #endif

                    Button("Overslaan (later instellen)") {
                        linkedNFCID = nil
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .plantCard()
    }

    // MARK: - Save
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if isEditing, let plant = plantToEdit {
            PersistenceController.shared.updatePlant(
                plant, name: trimmedName, emoji: selectedEmoji, waterIntervalHours: selectedHours
            )
            if let nfcID = linkedNFCID {
                PersistenceController.shared.linkNFC(id: nfcID, to: plant)
            }
            NotificationManager.shared.scheduleNotification(for: plant)
        } else {
            let plant = PersistenceController.shared.createPlant(
                name: trimmedName, emoji: selectedEmoji, waterIntervalHours: selectedHours
            )
            if let nfcID = linkedNFCID {
                PersistenceController.shared.linkNFC(id: nfcID, to: plant)
            }
        }

        dismiss()
    }

    // MARK: - Load existing
    private func loadExistingData() {
        guard let plant = plantToEdit else { return }
        name = plant.wrappedName
        selectedEmoji = plant.wrappedEmoji
        selectedHours = plant.waterIntervalHours
        linkedNFCID = plant.wrappedNfcID

        // Determine preset from hours
        if let preset = WaterIntervalPreset.allCases.first(where: { $0.hours == selectedHours }) {
            selectedPreset = preset
        } else {
            selectedPreset = .custom
            customDays = Int(selectedHours / 24)
        }
    }
}

#Preview {
    AddEditPlantView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(NFCManager.shared)
}
