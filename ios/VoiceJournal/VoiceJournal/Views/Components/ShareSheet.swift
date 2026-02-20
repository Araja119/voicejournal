import SwiftUI
import UIKit

/// Presents UIActivityViewController directly via UIKit to get the full native share sheet
/// (iMessage, Mail, AirDrop, etc.). Avoids the SwiftUI .sheet() wrapper which breaks
/// the native contact suggestions row.
struct SharePresenter {
    static func present(items: [Any], completion: ((Bool) -> Void)? = nil) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.completionWithItemsHandler = { _, completed, _, _ in
            completion?(completed)
        }
        topVC.present(activityVC, animated: true)
    }
}
