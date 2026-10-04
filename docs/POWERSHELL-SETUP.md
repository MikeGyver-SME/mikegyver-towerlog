# TowerLog v1.0.0 — PowerShell Setup Runbook

Everything runs in two stages, in order. Stage 1 is the one-time Apple /
GitHub setup. Stage 2 builds the iPhone app in GitHub Actions and delivers
it to your phone through TestFlight.

**What you're building**

```
iPhone (TowerLog, SwiftUI, iOS 17+)
┌──────────────────────────────────────────────┐
│ Log Tower → one GPS fix + timestamp          │
│   + tower type (guyed/monopole/lattice/      │
│     water tank/unknown)                       │
│   + optional photo (camera or library)       │
│   + callsign/frequency + freeform notes      │
│ Stored locally in SwiftData — works with     │
│ no signal. Towers tab + MapKit map tab.      │
│ Export one entry or the whole log as JSON    │
│ (bearing-lab-compatible) via the share sheet. │
│ No login, no cloud in v1.                     │
└──────────────────────────────────────────────┘
```

**Before you start:** the `towerlog-v1.0.0.zip` from Wiggs, extracted somewhere
handy (these steps assume `~\Downloads\towerlog-v1.0.0\towerlog`). Your paid
Apple Developer membership.

---

## Stage 1 — One-time Apple setup (about 5 minutes on the web)

### 1.1 App Store Connect API key

This is how GitHub Actions signs and uploads without your password:

- Go to https://appstoreconnect.apple.com → **Users and Access** →
  **Integrations** → **App Store Connect API** → **Team Keys** → **+**
- Name it `TowerLog CI`, Access: **Admin** (App Manager also works for uploads)
- Click **Generate**, then note the **Key ID** (e.g. `A1B2C3D4E5`) and the
  **Issuer ID** (a UUID at the top of the page)
- **Download the `.p8` file now** — Apple shows it exactly once. Save it to
  `~\Downloads\AuthKey_<KeyID>.p8`

### 1.2 Team ID

https://developer.apple.com/account → **Membership** → copy the **Team ID**
(e.g. `WXMPJQBSTA7` — use YOUR actual value, not this example)

### 1.3 Register the bundle ID

- https://developer.apple.com/account → **Certificates, Identifiers & Profiles**
  → **Identifiers** → **+** → **App IDs** → **App**
- Description: `TowerLog`, Bundle ID: **Explicit** → `studio.mikegyver.towerlog`
- No special capabilities needed (When-In-Use location is an Info.plist usage
  string, not a capability) → **Register**

### 1.4 Create the app record

- App Store Connect → **My Apps** → **+** → **New App** → platform **iOS**,
  Name `MikeGyver TowerLog`, Bundle ID `studio.mikegyver.towerlog`,
  SKU `towerlog-001`
- **Name check:** App Store Connect will tell you right here if
  `MikeGyver TowerLog` is already taken. If it is, tweak it (e.g.
  `MikeGyver Tower Log`) and update `CFBundleDisplayName` in
  `ios\TowerLog\Info.plist` to match before you push.

---

## Stage 2 — GitHub repo, secrets, and TestFlight build

### 2.1 Create the repo and push the code

On https://github.com/new (or under your `MikeGyver-SME` org): repository name
**`mikegyver-towerlog`**, visibility **Private**, do **not** add a README
(the zip already has one).

Then in PowerShell:

```powershell
cd "$env:USERPROFILE\Downloads\towerlog-v1.0.0\towerlog"
git init -b main
git add -A
git commit -m "TowerLog v1.0.0"
git remote add origin https://github.com/MikeGyver-SME/mikegyver-towerlog.git
git branch -M main
git push -u origin main
```

> Shortcut: `scripts\push-towerlog.ps1` in this folder does the clone/copy/
> commit/push/tag cycle for you on later versions — see the script's header
> comments. (This first push is shown longhand so you see each step.)

### 2.2 Add the four secrets to the repo

Either: repo page → **Settings** → **Secrets and variables** → **Actions** →
**New repository secret** (four times), or in PowerShell with the GitHub CLI:

```powershell
$Repo = "MikeGyver-SME/mikegyver-towerlog"

gh secret set ASC_KEY_ID    --body "A1B2C3D4E5"   --repo $Repo
gh secret set ASC_ISSUER_ID --body "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" --repo $Repo
gh secret set TEAM_ID       --body "WXMPJQBSTA7"   --repo $Repo   # <-- YOUR real Team ID from the Membership page

$P8 = Get-Content -Raw "$env:USERPROFILE\Downloads\AuthKey_A1B2C3D4E5.p8"
gh secret set ASC_KEY_P8 --body $P8 --repo $Repo
```

(`gh secret set` handles the multi-line `.p8` content correctly. Don't have the
`gh` CLI? `winget install GitHub.cli`, then `gh auth login`.)

### 2.3 Trigger the build

The workflow runs on version tags. Push one:

```powershell
cd "$env:USERPROFILE\Downloads\towerlog-v1.0.0\towerlog"
git tag v1.0.0
git push origin v1.0.0
```

Watch it: repo → **Actions** → **Build and upload TowerLog to TestFlight**.
It takes roughly 10–15 minutes: XcodeGen → archive with App Store signing →
export IPA → `fastlane pilot upload`. A copy of the IPA is also kept as a
workflow artifact for 14 days.

### 2.4 Install on your iPhone via TestFlight

1. App Store Connect → **My Apps** → **MikeGyver TowerLog** → **TestFlight** →
   the new build appears under **iOS Builds** (processing takes a few minutes)
2. **Internal Testing** → create a group (or use the default) → **+** → add
   yourself as a tester
3. On your iPhone: install **TestFlight** from the App Store, open the invite
   email (or redeem the public link), install **TowerLog**

### 2.5 First launch

1. Open TowerLog → **Log Tower**
2. iOS asks for location: tap **Allow While Using App** — that's all this app
   needs (no "Always" prompt in v1)
3. Leave **Precise Location ON** (Settings → TowerLog → Location)
4. Wait for "Fix acquired" → pick the tower type, snap a photo, add notes →
   **Save**
5. Check the **Towers** tab (your entry is there) and the **Map** tab (a pin)

### 2.6 Shipping v1.0.1 and beyond

1. Bump versions in `ios/project.yml`: `MARKETING_VERSION` (what users see)
   and `CURRENT_PROJECT_VERSION` (must increase every TestFlight upload)
2. Commit, push, tag the new version:
   ```powershell
   git add -A; git commit -m "TowerLog v1.0.1"
   git push
   git tag v1.0.1; git push origin v1.0.1
   ```
3. TestFlight testers get the update automatically

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `MikeGyver TowerLog` name rejected in App Store Connect | Pick the closest available name, then update `CFBundleDisplayName` in `ios\TowerLog\Info.plist` to match before pushing |
| No location prompt / "Location access is off" | iPhone **Settings → TowerLog → Location → While Using the App**; **Precise Location ON** |
| "Still waiting" for a fix indoors | Step outside or near a window; GPS needs sky. The fix filter requires ±50 m or better |
| Workflow fails at Archive: signing/provisioning | API key needs **Admin** (or App Manager) access; check all four secrets are set |
| Export fails on `teamID` | `TEAM_ID` secret is wrong — copy it from developer.apple.com → Account → Membership |
| `pilot upload`: app not found | Do step 1.4: the App Store Connect app record must exist before the first upload |
| `fastlane` install takes minutes | Normal — it's a big gem; let it finish |
| Camera button missing | You're on the Simulator — the camera only exists on a real iPhone; use Photo Library there |
| Export share shows an empty log | Exports reflect the current on-device log; log a tower first, then share |

**Notes worth knowing:** entries and photos live only on the iPhone in v1 —
there is no cloud copy, so the JSON export (Towers tab share button, or the
per-entry share in the detail view) is your backup path. Export field names
match the Bearing Lab web app's format where they overlap; see the README's
"Format compatibility" section for the mapping.
