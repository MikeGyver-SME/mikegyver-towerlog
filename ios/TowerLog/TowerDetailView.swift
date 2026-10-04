import SwiftUI
import MapKit

/// Detail for one logged tower: photo, mini map, fix facts, notes, and a
/// single-entry JSON export via the share sheet.
struct TowerDetailView: View {
    let tower: TowerEntry
    @State private var exportURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let filename = tower.photoFilename,
                   let img = PhotoStore.load(filename: filename) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Map(position: .constant(.region(region()))) {
                    Annotation(tower.displayName, coordinate: tower.coordinate) {
                        Image(systemName: tower.towerType.systemImage)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Brand.navy)
                            .clipShape(Circle())
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(true)

                factRow(label: "Type", value: tower.towerType.label)
                if !tower.callsign.isEmpty {
                    factRow(label: "Callsign", value: tower.callsign)
                }
                if !tower.frequency.isEmpty {
                    factRow(label: "Frequency", value: tower.frequency)
                }
                factRow(label: "Coordinates",
                        value: TowerEntry.coordinateString(latitude: tower.latitude,
                                                          longitude: tower.longitude),
                        monospaced: true)
                factRow(label: "Fix accuracy",
                        value: String(format: "±%.0f m", tower.accuracy))
                if let alt = tower.altitude {
                    factRow(label: "Altitude", value: String(format: "%.0f m", alt))
                }
                factRow(label: "Logged", value: TowerEntry.displayDate(tower.recordedAt))

                if !tower.notes.isEmpty {
                    Text("Notes")
                        .font(.headline)
                    Text(tower.notes)
                }

                if let url = exportURL {
                    ShareLink(item: url) {
                        Label("Export this tower as JSON", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Brand.navy)
                }
            }
            .padding()
        }
        .navigationTitle(tower.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            exportURL = ExportHelper.writeExport(towers: [], single: tower)
        }
    }

    private func region() -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: tower.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    private func factRow(label: String, value: String, monospaced: Bool = false) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .multilineTextAlignment(.trailing)
        }
    }
}
