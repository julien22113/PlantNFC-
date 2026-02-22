import SwiftUI
import CoreData

struct PlantListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var nfcManager: NFCManager
    @EnvironmentObject var notificationManager: NotificationManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PlantEntity.name, ascending: true)],
        animation: .spring()
    ) private var plants: FetchedResults<PlantEntity>

    @State private var showAddPlant = false
    @State private var showScanSheet = false
    @State private var showScanResult = false
    @State private var scanResultMessage = ""
    @State private var scanResultIsSuccess = true
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var refreshTick = false

    // Sort plants by urgency: 🔴 first
    private var sortedPlants: [PlantEntity] {
        plants.sorted { $0.urgencyScore > $1.urgencyScore }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.plantBg.ignoresSafeArea()

                if plants.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(sortedPlants, id: \.id) { plant in
                                NavigationLink(destination: PlantDetailView(plant: plant)) {
                                    PlantRowView(plant: plant)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                }

                // FAB scan button (bottom right)
                if !plants.isEmpty {
                    scanFAB
                }

                // Add button (bottom center)
                addFAB
            }
            .navigationTitle("Mijn Planten 🌿")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddPlant = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.plantGreen)
                    }
                }
            }
            .sheet(isPresented: $showAddPlant) {
                AddEditPlantView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(nfcManager)
            }
            .sheet(isPresented: $showScanSheet) {
                NFCScanSheet(mode: .readForWatering, isPresented: $showScanSheet)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(nfcManager)
            }
            .onReceive(timer) { _ in
                refreshTick.toggle() // force view refresh for countdowns
            }
            .onAppear {
                notificationManager.clearBadge()
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🌱")
                .font(.system(size: 80))
            Text("Nog geen planten")
                .font(.title2.bold())
                .foregroundColor(.primary)
            Text("Voeg je eerste plant toe\nom te beginnen met bijhouden.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showAddPlant = true
            } label: {
                Label("Plant toevoegen", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.plantGreen)
                    .clipShape(Capsule())
            }
            Spacer()
            Spacer()
        }
        .padding()
    }

    private var addFAB: some View {
        EmptyView()
    }

    private var scanFAB: some View {
        Button {
            showScanSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title3)
                Text("NFC Scan")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.plantGreen, .plantGreenDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .plantGreen.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 30)
    }
}

#Preview {
    PlantListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(NFCManager.shared)
        .environmentObject(NotificationManager.shared)
}
