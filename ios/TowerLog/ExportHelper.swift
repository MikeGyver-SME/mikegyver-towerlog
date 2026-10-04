import Foundation

/// Writes TowerLog JSON exports to the shared temporary directory and hands
/// back a file URL for ShareLink. Filenames are timestamped so repeated
/// exports never collide.
enum ExportHelper {
    static func writeExport(towers: [TowerEntry], single: TowerEntry? = nil) -> URL? {
        let list = single.map { [$0] } ?? towers
        guard let data = TowerEntry.exportJSON(towers: list) else { return nil }
        let stamp = exportStamp()
        let name: String
        if let one = single {
            name = "towerlog-entry-\(one.id.uuidString.prefix(8))-\(stamp).json"
        } else {
            name = "towerlog-export-\(stamp).json"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private static func exportStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return f.string(from: Date())
    }
}
