# TowerLog v1.0.0

A native iOS field recorder for MikeGyver Studio — the pocket successor to the
**Bearing Lab** ("Record Communications Tower") web app. On a walk, tap the
big **Log Tower** button: the app captures one GPS fix + timestamp, and you
add the tower type (guyed, monopole, lattice, water tank, unknown), an
optional photo (camera or library), callsign/frequency when known, and
freeform notes. Everything is stored locally on the iPhone with SwiftData —
no account, no signal required.

Browse entries in the **Towers** tab, see them as pins in the **Map** tab, and
export one entry or the whole log as JSON through the share sheet.

## Layout

```
towerlog/
├── ios/                     SwiftUI iPhone app (XcodeGen project, iOS 17+)
│   ├── project.yml          MARKETING_VERSION / CURRENT_PROJECT_VERSION live here
│   └── TowerLog/
│       ├── TowerLogApp.swift    @main + SwiftData model container
│       ├── Brand.swift          MikeGyver navy/gold
│       ├── TowerEntry.swift     SwiftData model, TowerType enum, bearing-lab JSON export
│       ├── LocationService.swift  One-shot When-In-Use GPS fix (no background mode)
│       ├── PhotoStore.swift     JPEG save/load/delete in Documents
│       ├── ExportHelper.swift   Timestamped JSON export files for ShareLink
│       ├── CameraPicker.swift   UIImagePickerController wrapper
│       ├── ContentView.swift    Tab bar + big "Log Tower" home tab
│       ├── LogTowerView.swift   Capture sheet: fix, type, photo, notes
│       ├── TowerListView.swift  Entry list + delete + whole-log export
│       ├── TowerDetailView.swift  Photo, mini map, facts, single-entry export
│       ├── TowerMapView.swift   MapKit pins for all logged towers
│       ├── Info.plist           Location/camera/photo-library usage strings
│       └── Assets.xcassets/     Navy/gold tower app icon set
├── .github/workflows/
│   └── testflight.yml       macos-26: XcodeGen → archive → IPA → fastlane pilot
├── docs/
│   └── POWERSHELL-SETUP.md  Detailed PowerShell runbook (start here)
└── scripts/
    └── push-towerlog.ps1    Clone/copy/commit/push/tag helper for Windows
```

## Quickstart

Follow **`docs/POWERSHELL-SETUP.md`** — it covers every command:

1. App Store Connect API key ("TowerLog CI") + Team ID + bundle ID
   `studio.mikegyver.towerlog` + app record **MikeGyver TowerLog**
   (check the name is still available in App Store Connect when you create it)
2. Create the GitHub repo (`mikegyver-towerlog`, Private) → push the code
3. Add the 4 secrets (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `TEAM_ID`)
4. `git tag v1.0.0` → the workflow builds and uploads to TestFlight
5. Install via TestFlight, grant **While Using** location (Precise ON), go log towers

## Format compatibility with the Bearing Lab web app

TowerLog v1 exports JSON that uses the **same snake_case key style** as
Bearing Lab's serde model (`src/model.rs`), so entries move between the two
with a mechanical key mapping. Fields that exist in both use identical names:

| TowerLog export key | Bearing Lab equivalent |
|---|---|
| `id` | `Observation.id` / `KnownTower.id` (TowerLog uses a UUID string) |
| `recorded_at` | `Observation.recorded_at` (ISO-8601 in both) |
| `latitude`, `longitude` | same in `Observation` and `KnownTower` |
| `accuracy` | `Observation.accuracy` (meters) |
| `altitude` | `Observation.altitude` (meters, null when unknown) |
| `note` | `Observation.note` |
| `callsign` | `KnownTower.callsign` |
| `frequency` | `KnownTower.frequency` |
| `tower_type` | TowerLog-only (`guyed` / `monopole` / `lattice` / `water-tank` / `unknown`) |
| `has_photo` | TowerLog-only (photos stay on the device, never in JSON) |
| `source` | TowerLog-only (`"towerlog-ios"`) |

Sample single entry:

```json
{
  "format": "towerlog-v1",
  "exported_at": "2026-10-03T20:15:00Z",
  "app": "MikeGyver TowerLog",
  "towers": [
    {
      "accuracy": 8.0,
      "altitude": 62.0,
      "callsign": "KRLY-LP",
      "frequency": "104.5 FM",
      "has_photo": true,
      "id": "3F2A1B0C-…",
      "latitude": 30.070074,
      "longitude": -95.710961,
      "note": "Guyed mast behind the treeline, red obstruction light.",
      "recorded_at": "2026-10-03T20:12:44Z",
      "source": "towerlog-ios",
      "tower_type": "guyed"
    }
  ]
}
```

To bring TowerLog entries into Bearing Lab: each `towers[]` object maps onto a
`KnownTower` by filling `id`, `callsign`, `frequency`, `latitude`,
`longitude`, and putting `tower_type` + `note` into `notes`
(`facility_id`/`erp`/`haat`/`licensee` come from the FCC lookup worker, as
usual). To bring Bearing Lab towers into TowerLog, a future version can import
the same shape — v1 is export-only.

## Honest v1 limits

- **Local-first only.** No login, no Cloudflare Worker, no sync — entries live
  in the iPhone's SwiftData store. The Bearing Lab web app keeps its own
  store; the JSON export above is the bridge between them.
- **No bearing capture.** Bearing Lab's compass/GPS-math bearing modes stay in
  the web app; TowerLog logs the tower itself (position, type, photo, notes).
- **Photos are device-only.** Exports carry `"has_photo": true/false`; the
  JPEGs never leave the phone except through the iOS share sheet if you share
  them yourself.
- **When-In-Use location only.** No background mode, no "Always" prompt — a
  tower log needs one fix while the app is open. Leave **Precise Location ON**.
- Unverified on real hardware until the first TestFlight build: the capture
  flow, camera picker, and SwiftData persistence were written carefully but
  have not run under Xcode yet.
