import UIKit

enum ImageUtils {
    /// Compresses image data to JPEG for upload. Returns compressed data or nil if conversion fails.
    static func compressForUpload(_ data: Data, quality: CGFloat = 0.7) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return image.jpegData(compressionQuality: quality)
    }
}
