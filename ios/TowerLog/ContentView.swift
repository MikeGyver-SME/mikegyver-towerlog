import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            LogTab()
                .tabItem { Label("Log Tower", systemImage: "plus.circle.fill") }
            TowerListView()
                .tabItem { Label("Towers", systemImage: "list.bullet") }
            TowerMapView()
                .tabItem { Label("Map", systemImage: "map") }
        }
        .tint(Brand.navy)
    }
}

/// Home tab: the big "Log Tower" button plus a running count. Everything is
/// stored on this iPhone — no account, no signal required.
struct LogTab: View {
    @Query(sort: \TowerEntry.recordedAt, order: .reverse) private var towers: [TowerEntry]
    @State private var showLogSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 84))
                    .foregroundStyle(Brand.navy, Brand.gold)
                Text("MikeGyver Studio")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(towers.isEmpty ? "No towers logged yet." : "\(towers.count) tower\(towers.count == 1 ? "" : "s") logged")
                    .font(.title3)
                Button {
                    showLogSheet = true
                } label: {
                    Text("Log Tower")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.navy)
                Text("Captures GPS + timestamp, with optional photo, tower type, and notes. All entries stay on this iPhone — works with no signal on a walk.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding()
            .navigationTitle("TowerLog")
            .sheet(isPresented: $showLogSheet) {
                LogTowerView()
            }
        }
    }
}
