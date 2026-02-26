import Foundation
import Combine
import UIKit
import UserNotifications

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var fcmToken: String?

    private override init() {
        super.init()
    }

    // MARK: - Setup

    /// Call once at app launch
    func configure() {
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        } catch {
            print("[Push] Permission request failed: \(error)")
            return false
        }
    }

    // MARK: - Token Registration

    /// Sends the current FCM token to the backend
    func registerTokenWithBackend() {
        guard let token = fcmToken else { return }

        Task {
            do {
                _ = try await AuthService.shared.registerPushToken(token: token)
                print("[Push] Token registered with backend")
            } catch {
                print("[Push] Failed to register token: \(error)")
            }
        }
    }

    // MARK: - APNs Token

    func handleAPNsToken(_ deviceToken: Data) {
        // TODO: Forward to Firebase Messaging when SDK is added
        // Messaging.messaging().apnsToken = deviceToken
        print("[Push] APNs token received")
    }
}

// MARK: - UNUserNotificationCenter Delegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Called when notification arrives while app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    /// Called when user taps a notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("[Push] Notification tapped: \(userInfo)")
        completionHandler()
    }
}
