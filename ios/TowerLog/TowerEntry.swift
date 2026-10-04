import Foundation
import SwiftData
import CoreLocation

// MARK: - TowerType

/// Field-log tower types. Raw values are the snake_case strings used in
/// exported JSON, so they stay stable across app versions.
enum TowerType: String, CaseIterable, Identifiable, Codable {
    case guyed
    case monopole
    case lattice
    case waterTank = "water-tank"
    case unknown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .guyed: return "Guyed mast"
        case .monopole: return "Monopole"
        case .lattice: return "Lattice (self-supporting)"
        case .waterTank: return "Water tank"
        case .unknown: return "Unknown"
        }
    }

    var systemImage: String {
        switch self {
        case .guyed: return "antenna.radiowaves.left.and.right"
        case .monopole: return "arrow.up"
        case .lattice: return "triangle"
        case .waterTank: return "drop.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - TowerEntry (SwiftData model)

/// One logged tower: GPS fix + timestamp + type + optional photo and notes.
/// Stored locally on the device (SwiftData). No login, no cloud in v1.
@Model
final class TowerEntry {
    @Attribute(.unique) var id: UUID
    var recordedAt: Date
    var latitude: Double
    var longitude: Double
    /// Horizontal accuracy of the fix, in meters.
    var accuracy: Double
    /// Altitude in meters, when the fix carried one.
    var altitude: Double?
    /// Backing store for `towerType`; persisted as the stable raw string.
    var towerTypeRaw: String
    /// Broadcast callsign when known (e.g. "KRLY-LP"). Empty when unknown.
    var callsign: String
    /// Frequency when known (e.g. "104.5 FM"). Empty when unknown.
    var frequency: String
    var notes: String
    /// JPEG filename in the app's Documents directory, when a photo was saved.
    var photoFilename: String?

    var towerType: TowerType {
        get { TowerType(rawValue: towerTypeRaw) ?? .unknown }
        set { towerTypeRaw = newValue.rawValue }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// "KRLY-LP", or "Unknown tower" when no callsign was entered.
    var displayName: String {
        callsign.isEmpty ? "Unknown tower" : callsign
    }

    init(
        id: UUID = UUID(),
        recordedAt: Date = Date(),
        latitude: Double,
        longitude: Double,
        accuracy: Double,
        altitude: Double? = nil,
        towerType: TowerType = .unknown,
        callsign: String = "",
        frequency: String = "",
        notes: String = "",
        photoFilename: String? = nil
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.altitude = altitude
        self.towerTypeRaw = towerType.rawValue
        self.callsign = callsign
        self.frequency = frequency
        self.notes = notes
        self.photoFilename = photoFilename
    }
}

// MARK: - Bearing Lab compatible export

/// One logged tower, serialized with the same snake_case key style as the
/// Bearing Lab web app's serde JSON (model.rs). Fields that exist in both
/// apps use identical names so entries can move between the two with a
/// mechanical key mapping — see README "Format compatibility".
struct TowerEntryExport: Codable {
    var id: String
    var recordedAt: Date
    var latitude: Double
    var longitude: Double
    var accuracy: Double
    var altitude: Double?
    var towerType: String
    var callsign: String
    var frequency: String
    var note: String
    var hasPhoto: Bool
    var source: String

    enum CodingKeys: String, CodingKey {
        case id
        case recordedAt = "recorded_at"
        case latitude
        case longitude
        case accuracy
        case altitude
        case towerType = "tower_type"
        case callsign
        case frequency
        case note
        case hasPhoto = "has_photo"
        case source
    }
}

/// Export envelope: `{format, exported_at, app, towers:[...]}`.
struct TowerLogExport: Codable {
    var format: String
    var exportedAt: Date
    var app: String
    var towers: [TowerEntryExport]

    enum CodingKeys: String, CodingKey {
        case format
        case exportedAt = "exported_at"
        case app
        case towers
    }
}

extension TowerEntry {
    /// Convert to the export representation. `recorded_at` uses ISO-8601,
    /// the same shape as Bearing Lab's `Date.toISOString()` output.
    func toExport() -> TowerEntryExport {
        TowerEntryExport(
            id: id.uuidString,
            recordedAt: recordedAt,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            altitude: altitude,
            towerType: towerTypeRaw,
            callsign: callsign,
            frequency: frequency,
            note: notes,
            hasPhoto: photoFilename != nil,
            source: "towerlog-ios"
        )
    }

    /// Pretty-printed, key-sorted JSON of the export envelope, or nil when
    /// encoding fails (never expected — all fields are plain JSON types).
    static func exportJSON(towers: [TowerEntry]) -> Data? {
        let envelope = TowerLogExport(
            format: "towerlog-v1",
            exportedAt: Date(),
            app: "MikeGyver TowerLog",
            towers: towers.map { $0.toExport() }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(envelope)
    }

    static func displayDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    static func coordinateString(latitude: Double, longitude: Double) -> String {
        String(format: "%.6f, %.6f", latitude, longitude)
    }
}
