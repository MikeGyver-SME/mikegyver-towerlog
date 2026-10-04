import SwiftUI
import SwiftData
import MapKit

/// MapKit view of every logged tower. The camera fits all entries with a
/// small padding; tapping a marker's callout is not needed in v1 — use the
/// Towers tab for details.
struct TowerMapView: View {
    @Query(sort: \TowerEntry.recordedAt, order: .reverse) private var towers: [TowerEntry]
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Group {
                if towers.isEmpty {
                    ContentUnavailableView(
                        "No towers to map",
                        systemImage: "map",
                        description: Text("Logged towers will appear here as pins.")
                    )
                } else {
                    Map(position: $position) {
                        ForEach(towers) { tower in
                            Annotation(tower.displayName, coordinate: tower.coordinate) {
                                Image(systemName: tower.towerType.systemImage)
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Brand.navy)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tower Map")
            .onAppear { fitAll() }
            .onChange(of: towers.count) { _, _ in fitAll() }
        }
    }

    private func fitAll() {
        guard !towers.isEmpty else {
            position = .automatic
            return
        }
        var rect = MKMapRect.null
        for tower in towers {
            let point = MKMapPoint(tower.coordinate)
            // ~1 km pad per tower so a single pin still shows a useful area.
            let padded = MKMapRect(x: point.x - 500, y: point.y - 500,
                                   width: 1000, height: 1000)
            rect = rect.union(padded)
        }
        position = .rect(rect)
    }
}
