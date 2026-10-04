import UIKit

/// Photos attached to tower entries are saved as JPEGs in the app's Documents
/// directory and referenced by filename on the SwiftData model. The photos
/// stay on the device: JSON exports only record `"has_photo": true/false`.
enum PhotoStore {
    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Downscale to a sane field-photo size, then save. Returns the filename,
    /// or nil when encoding or the write fails.
    static func saveJPEG(_ image: UIImage) -> String? {
        let scaled = downscale(image, maxDimension: 1600)
        guard let data = scaled.jpegData(compressionQuality: 0.85) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        do {
            try data.write(to: documentsDirectory().appendingPathComponent(filename),
                           options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    static func load(filename: String) -> UIImage? {
        let url = documentsDirectory().appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(filename: String) {
        try? FileManager.default.removeItem(
            at: documentsDirectory().appendingPathComponent(filename))
    }

    private static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let size = CGSize(width: image.size.width * scale,
                          height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
}
