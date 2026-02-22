import SwiftUI
import Combine

struct NFCScanSheet: View {
    let mode: NFCScanMode
    @Binding var isPresented: Bool

    @EnvironmentObject var nfcManager: NFCManager
    @Environment(\.managedObjectContext) private var viewContext

    @State private var pulseScale: CGFloat = 1.0
    @State private var showSuccess = false
    @State private var successPlantName = ""
    @State private var successPlantEmoji = ""
    @State private var successCountdown = ""
    @State private var showUnknownTag = false
    @State private var unknownTagID = ""

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 24)

            if showSuccess {
                successView
            } else if showUnknownTag {
                unknownTagView
            } else {
                scanningView
            }

            Spacer()

            Button(showSuccess ? "Sluiten" : "Annuleren") {
                nfcManager.stopScanning()
                isPresented = false
            }
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .background(Color.plantBg)
        .presentationDetents([.fraction(0.55)])
        .presentationCornerRadius(24)
        // Fixed: use onReceive instead of onChange — no Equatable needed this way
        .onReceive(nfcManager.$scanResult) { result in
            handleResult(result)
        }
        .onAppear {
            startPulse()
            #if !targetEnvironment(simulator)
            nfcManager.startScanning(mode: mode)
            #endif
        }
    }

    // MARK: - Scanning View
    private var scanningView: some View {
        VStack(spacing: 28) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.plantGreen.opacity(0.3 - Double(i) * 0.08), lineWidth: 1.5)
                        .frame(width: 80 + CGFloat(i * 40), height: 80 + CGFloat(i * 40))
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.4),
                            value: pulseScale
                        )
                }
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.plantGreen, .plantGreenDark],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 34))
                        .foregroundColor(.white)
                }
            }
            .frame(height: 180)

            VStack(spacing: 8) {
                Text("Klaar om te scannen")
                    .font(.title3.bold())
                Text("Houd uw iPhone bij de NFC-chip\nvan de plant")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            #if targetEnvironment(simulator)
            Button {
                nfcManager.simulateScan(mode: mode)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                    Text("Simuleer NFC Scan")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.orange)
                .clipShape(Capsule())
            }
            #else
            Button {
                nfcManager.startScanning(mode: mode)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Start scannen")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.plantGreen)
                .clipShape(Capsule())
            }
            #endif
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.plantGreen.opacity(0.15))
                    .frame(width: 120, height: 120)
                VStack(spacing: 4) {
                    Text(successPlantEmoji)
                        .font(.system(size: 50))
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.plantGreen)
                        .offset(x: 30, y: -30)
                }
            }
            VStack(spacing: 8) {
                Text("Plant heeft water gekregen 🌱")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                Text(successPlantName)
                    .font(.title2.bold())
                    .foregroundColor(.plantGreen)
                Text("Volgende waterbeurt: \(successCountdown)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Unknown Tag View
    private var unknownTagView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
            }
            VStack(spacing: 8) {
                Text("Onbekende NFC-tag")
                    .font(.title3.bold())
                Text("Tag ID: \(unknownTagID)\nKoppel deze tag eerst aan een plant.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Handle Result
    private func handleResult(_ result: NFCScanResult?) {
        guard let result = result else { return }

        switch result {
        case .wateredPlant(let plantID):
            // Look up plant by ID string
            let ctx = PersistenceController.shared.container.viewContext
            let req = PlantEntity.fetchRequest()
            req.predicate = NSPredicate(format: "id == %@",
                                        UUID(uuidString: plantID) as CVarArg? ?? plantID as CVarArg)
            req.fetchLimit = 1
            if let plant = (try? ctx.fetch(req))?.first {
                withAnimation(.spring(duration: 0.5)) {
                    successPlantName  = plant.wrappedName
                    successPlantEmoji = plant.wrappedEmoji
                    successCountdown  = plant.countdownText
                    showSuccess = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    isPresented = false
                }
            }

        case .unknownTag(let id):
            withAnimation { showUnknownTag = true; unknownTagID = id }

        case .linked, .error:
            break
        }
    }

    private func startPulse() {
        withAnimation { pulseScale = 1.4 }
    }
}
