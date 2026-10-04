import SwiftUI
import SwiftData

@main
struct TowerLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TowerEntry.self)
    }
}
