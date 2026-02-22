import SwiftUI
import UserNotifications
import BackgroundTasks

@main
struct PlantNFCApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var nfcManager = NFCManager.shared

    init() {
        BackgroundTaskManager.shared.registerTasks()
    }

    var body: some Scene {
        WindowGroup {
            PlantListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(nfcManager)
                .environmentObject(notificationManager)
                .onAppear {
                    NotificationManager.shared.requestPermission()
                    BackgroundTaskManager.shared.scheduleAppRefresh()
                }
        }
    }
}
