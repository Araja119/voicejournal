import Foundation

// MARK: - Remind Cap Tracker
// Tracks daily remind usage client-side to enforce soft caps.
// In-memory only — resets on app restart. Backend is the authoritative enforcer.

class RemindCapTracker {
    static let shared = RemindCapTracker()

    private var dailyRemindTimestamps: [Date] = []
    private var personRemindTimestamps: [String: Date] = [:]  // personId -> last remind time

    private let maxDailyReminders = 5
    private let personCooldownInterval: TimeInterval = 24 * 3600  // 24 hours

    private init() {}

    /// Check if a remind is allowed for a specific person
    func canRemindPerson(_ personId: String) -> RemindBlockReason? {
        // Check per-person cap (1 per 24h)
        if let lastRemind = personRemindTimestamps[personId] {
            if Date().timeIntervalSince(lastRemind) < personCooldownInterval {
                return .personCapReached
            }
        }

        // Check global daily cap
        let todayCount = dailyRemindTimestamps.filter { Calendar.current.isDateInToday($0) }.count
        if todayCount >= maxDailyReminders {
            return .dailyCapReached
        }

        return nil
    }

    /// Record that a remind was sent for a person
    func recordRemind(personId: String) {
        dailyRemindTimestamps.append(Date())
        personRemindTimestamps[personId] = Date()

        // Prune old timestamps (older than 48h) to prevent memory growth
        let cutoff = Date().addingTimeInterval(-48 * 3600)
        dailyRemindTimestamps.removeAll { $0 < cutoff }
    }

    /// Number of reminds sent today
    var todayRemindCount: Int {
        dailyRemindTimestamps.filter { Calendar.current.isDateInToday($0) }.count
    }

    /// Remaining reminds allowed today
    var remainingDailyReminders: Int {
        max(0, maxDailyReminders - todayRemindCount)
    }
}
