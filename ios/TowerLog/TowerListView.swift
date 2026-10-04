import SwiftUI
import SwiftData

/// All logged towers, newest first. Swipe to delete (also removes the saved
/// photo file). The toolbar share button exports the whole log as JSON.
struct TowerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TowerEntry.recordedAt, order: .reverse) private var towers: [TowerEntry]
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                if towers.isEmpty {
                    ContentUnavailableView(
                        "No towers yet",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("Tap Log Tower to record your first find.")
                    )
                } else {
                    List {
                        ForEach(towers) { tower in
                            NavigationLink {
                                TowerDetailView(tower: tower)
                            } label: {
                                row(for: tower)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Towers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if let url = exportURL {
                        ShareLink(item: url)
                    }
                }
            }
            .onAppear { refreshExport() }
            .onChange(of: towers.count) { _, _ in refreshExport() }
        }
    }

    private func row(for tower: TowerEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tower.towerType.systemImage)
                .font(.title2)
                .foregroundStyle(Brand.navy)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(tower.displayName)
                    .font(.headline)
                Text("\(tower.towerType.label) · \(TowerEntry.displayDate(tower.recordedAt))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if tower.photoFilename != nil {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let tower = towers[index]
            if let filename = tower.photoFilename {
                PhotoStore.delete(filename: filename)
            }
            modelContext.delete(tower)
        }
        try? modelContext.save()
    }

    private func refreshExport() {
        exportURL = ExportHelper.writeExport(towers: towers)
    }
}
