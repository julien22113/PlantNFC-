import Foundation
import CoreNFC
import AudioToolbox
import UIKit

// MARK: - NFC Scan Mode
enum NFCScanMode {
    case readForWatering   // Scan → find plant → water it
    case readForLinking    // Scan → return tag ID to bind to new plant
}

// MARK: - NFC Result
enum NFCScanResult {
    case wateredPlant(PlantEntity)
    case unknownTag(String)
    case linked(String)
    case error(String)
}

@MainActor
class NFCManager: NSObject, ObservableObject {
    static let shared = NFCManager()

    @Published var isScanning = false
    @Published var scanResult: NFCScanResult?
    @Published var scanMessage = "Houd iPhone bij NFC-tag..."

    private var session: NFCTagReaderSession?
    private var currentMode: NFCScanMode = .readForWatering
    private var linkingCompletion: ((String) -> Void)?

    // MARK: - Start Scanning
    func startScanning(mode: NFCScanMode, onLinked: ((String) -> Void)? = nil) {
        guard NFCTagReaderSession.readingAvailable else {
            scanResult = .error("NFC niet beschikbaar op dit apparaat.")
            return
        }

        currentMode = mode
        linkingCompletion = onLinked
        isScanning = true
        scanMessage = "Houd iPhone bij de NFC-tag van uw plant..."
        scanResult = nil

        session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: .main)
        session?.alertMessage = "Houd iPhone bij de NFC-chip van uw plant."
        session?.begin()
    }

    // MARK: - Stop Scanning
    func stopScanning() {
        session?.invalidate()
        isScanning = false
    }

    // MARK: - Haptic & Sound
    private func successFeedback() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        // System sound: "payment success" style
        AudioServicesPlaySystemSound(1007)
    }

    private func errorFeedback() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    // MARK: - Simulator Mock
    #if targetEnvironment(simulator)
    func simulateScan(mode: NFCScanMode, mockID: String = "MOCK-\(UUID().uuidString.prefix(8))") {
        isScanning = true
        scanResult = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isScanning = false
            self.handleTagID(mockID, mode: mode)
        }
    }
    #endif

    // MARK: - Handle Tag ID (shared logic)
    func handleTagID(_ tagID: String, mode: NFCScanMode) {
        switch mode {
        case .readForWatering:
            if let plant = PersistenceController.shared.findPlant(byNFCID: tagID) {
                PersistenceController.shared.waterPlant(plant)
                successFeedback()
                scanResult = .wateredPlant(plant)
            } else {
                errorFeedback()
                scanResult = .unknownTag(tagID)
            }

        case .readForLinking:
            successFeedback()
            linkingCompletion?(tagID)
            scanResult = .linked(tagID)
        }
    }
}

// MARK: - NFCTagReaderSessionDelegate
extension NFCManager: NFCTagReaderSessionDelegate {

    nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Session is active, ready to scan
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as? NFCReaderError
        guard nfcError?.code != .readerSessionInvalidationErrorUserCanceled else { return }

        Task { @MainActor in
            self.isScanning = false
            if nfcError?.code != .readerSessionInvalidationErrorUserCanceled {
                self.scanResult = .error("NFC scan mislukt: \(error.localizedDescription)")
            }
        }
    }

    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }

        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "Verbinding mislukt: \(error.localizedDescription)")
                return
            }

            let tagID: String
            switch tag {
            case .iso7816(let t):
                tagID = t.identifier.map { String(format: "%02X", $0) }.joined()
            case .miFare(let t):
                tagID = t.identifier.map { String(format: "%02X", $0) }.joined()
            case .feliCa(let t):
                tagID = t.currentIDm.map { String(format: "%02X", $0) }.joined()
            case .iso15693(let t):
                tagID = t.identifier.map { String(format: "%02X", $0) }.joined()
            @unknown default:
                session.invalidate(errorMessage: "Onbekend NFC type.")
                return
            }

            session.alertMessage = "✅ NFC gelezen!"
            session.invalidate()

            Task { @MainActor in
                self.isScanning = false
                self.handleTagID(tagID, mode: self.currentMode)
            }
        }
    }
}
