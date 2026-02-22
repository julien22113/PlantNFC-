import CoreData
import Foundation

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    // MARK: - Init
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PlantNFC")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("CoreData store failed: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("CoreData save error: \(error)")
            }
        }
    }

    // MARK: - Create Plant
    @discardableResult
    func createPlant(name: String, emoji: String, waterIntervalHours: Double) -> PlantEntity {
        let plant = PlantEntity(context: container.viewContext)
        plant.id = UUID()
        plant.name = name
        plant.emoji = emoji
        plant.waterIntervalHours = waterIntervalHours
        plant.createdAt = Date()
        save()
        return plant
    }

    // MARK: - Update Plant
    func updatePlant(_ plant: PlantEntity,
                     name: String,
                     emoji: String,
                     waterIntervalHours: Double) {
        plant.name = name
        plant.emoji = emoji
        plant.waterIntervalHours = waterIntervalHours
        save()
    }

    // MARK: - Link NFC
    func linkNFC(id: String, to plant: PlantEntity) {
        plant.nfcID = id
        save()
    }

    // MARK: - Water Plant
    func waterPlant(_ plant: PlantEntity) {
        plant.lastWatered = Date()
        save()
        NotificationManager.shared.cancelNotifications(for: plant)
        NotificationManager.shared.scheduleNotification(for: plant)
    }

    // MARK: - Find Plant by NFC ID
    func findPlant(byNFCID nfcID: String) -> PlantEntity? {
        let request: NSFetchRequest<PlantEntity> = PlantEntity.fetchRequest()
        request.predicate = NSPredicate(format: "nfcID == %@", nfcID)
        request.fetchLimit = 1
        return try? container.viewContext.fetch(request).first
    }

    // MARK: - Delete Plant
    func deletePlant(_ plant: PlantEntity) {
        NotificationManager.shared.cancelNotifications(for: plant)
        container.viewContext.delete(plant)
        save()
    }

    // MARK: - Preview helper
    static var preview: PersistenceController = {
        let ctrl = PersistenceController(inMemory: true)
        let ctx = ctrl.container.viewContext

        let samplePlants: [(String, String, Double, Double)] = [
            ("Monstera", "🪴", 48, -5),
            ("Cactus", "🌵", 168, 50),
            ("Orchidee", "🌸", 24, -30)
        ]

        for (name, emoji, interval, offsetHours) in samplePlants {
            let p = PlantEntity(context: ctx)
            p.id = UUID()
            p.name = name
            p.emoji = emoji
            p.waterIntervalHours = interval
            p.createdAt = Date()
            p.lastWatered = Date().addingTimeInterval(offsetHours * 3600)
            p.nfcID = "MOCK-\(UUID().uuidString.prefix(8))"
        }

        try? ctx.save()
        return ctrl
    }()
}
