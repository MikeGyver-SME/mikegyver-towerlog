import SwiftUI
import PhotosUI
import UIKit

/// "Log Tower" capture sheet: acquires one GPS fix, then collects the tower
/// type, optional photo, callsign/frequency, and freeform notes. Save is
/// enabled as soon as the fix lands.
struct LogTowerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var location = LocationService()

    @State private var towerType: TowerType = .unknown
    @State private var callsign = ""
    @State private var frequency = ""
    @State private var notes = ""
    @State private var photo: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false

    private let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)

    var body: some View {
        NavigationStack {
            Form {
                Section(header: sectionHeader("GPS fix")) {
                    gpsRow
                }

                Section(header: sectionHeader("Tower")) {
                    Picker("Type", selection: $towerType) {
                        ForEach(TowerType.allCases) { type in
                            Label(type.label, systemImage: type.systemImage).tag(type)
                        }
                    }
                    TextField("Callsign (optional, e.g. KRLY-LP)", text: $callsign)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("Frequency (optional, e.g. 104.5 FM)", text: $frequency)
                        .autocorrectionDisabled()
                }

                Section(header: sectionHeader("Photo (optional)")) {
                    if let photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Button("Remove photo", role: .destructive) {
                            self.photo = nil
                        }
                    } else {
                        HStack {
                            if cameraAvailable {
                                Button {
                                    showCamera = true
                                } label: {
                                    Label("Camera", systemImage: "camera")
                                }
                            }
                            Spacer()
                            PhotosPicker(selection: $pickerItem, matching: .images) {
                                Label("Photo Library", systemImage: "photo")
                            }
                        }
                    }
                }

                Section(header: sectionHeader("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 110)
                }
            }
            .navigationTitle("Log Tower")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.navy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(Brand.gold)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(location.fix == nil)
                }
            }
            .onAppear {
                location.requestWhenInUseIfNeeded()
                location.acquireFix()
            }
            .onDisappear {
                location.stop()
            }
            .onChange(of: pickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        await MainActor.run { photo = img }
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(image: $photo)
            }
        }
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote.bold())
            .foregroundStyle(Brand.gold)
            .textCase(.uppercase)
    }

    // MARK: - GPS row

    @ViewBuilder
    private var gpsRow: some View {
        if let fix = location.fix {
            VStack(alignment: .leading, spacing: 6) {
                Text(TowerEntry.coordinateString(latitude: fix.coordinate.latitude,
                                                 longitude: fix.coordinate.longitude))
                    .font(.system(.body, design: .monospaced))
                Text(String(format: "Accuracy ±%.0f m", fix.horizontalAccuracy))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Retake fix") { location.acquireFix() }
                    .font(.footnote)
            }
        } else if location.isAuthorized || location.authorization == .notDetermined {
            HStack {
                ProgressView()
                Text(location.status.isEmpty ? "Acquiring GPS…" : location.status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Location access is off.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    // MARK: - Save

    private func save() {
        guard let fix = location.fix else { return }
        var filename: String?
        if let photo {
            filename = PhotoStore.saveJPEG(photo)
        }
        let entry = TowerEntry(
            latitude: fix.coordinate.latitude,
            longitude: fix.coordinate.longitude,
            accuracy: fix.horizontalAccuracy,
            altitude: fix.verticalAccuracy >= 0 ? fix.altitude : nil,
            towerType: towerType,
            callsign: callsign.trimmingCharacters(in: .whitespacesAndNewlines),
            frequency: frequency.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            photoFilename: filename
        )
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}
