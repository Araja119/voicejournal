import Foundation

// MARK: - Remind Eligibility

struct RemindEligibility {
    let canRemind: Bool
    let reason: RemindBlockReason?
    let cooldownRemaining: TimeInterval?

    /// Compute remind eligibility for an assignment
    static func check(_ assignment: Assignment) -> RemindEligibility {
        // Must be sent or viewed (not pending, not answered)
        guard assignment.status == .sent || assignment.status == .viewed else {
            let reason: RemindBlockReason = assignment.status == .answered
                ? .alreadyAnswered
                : .notYetSent
            return RemindEligibility(canRemind: false, reason: reason, cooldownRemaining: nil)
        }

        let reminderCount = assignment.reminderCount ?? 0

        // Per-question cap: 3 max
        if reminderCount >= 3 {
            return RemindEligibility(canRemind: false, reason: .maxRemindersReached, cooldownRemaining: nil)
        }

        // Escalating cooldown thresholds
        let thresholds: [TimeInterval] = [
            24 * 3600,      // 24h after initial send (before 1st remind)
            72 * 3600,      // 72h after 1st remind (before 2nd)
            7 * 24 * 3600   // 7 days after 2nd remind (before 3rd)
        ]

        let threshold = thresholds[min(reminderCount, thresholds.count - 1)]

        // Use lastReminderAt if available, otherwise sentAt
        let lastAction = assignment.lastReminderAt ?? assignment.sentAt
        guard let lastAction = lastAction else {
            // No sentAt means question hasn't actually been sent yet
            return RemindEligibility(canRemind: false, reason: .notYetSent, cooldownRemaining: nil)
        }

        let elapsed = Date().timeIntervalSince(lastAction)
        let remaining = threshold - elapsed

        if remaining > 0 {
            return RemindEligibility(canRemind: false, reason: .cooldownActive, cooldownRemaining: remaining)
        }

        return RemindEligibility(canRemind: true, reason: nil, cooldownRemaining: nil)
    }

    /// Format cooldown remaining as human-readable string (e.g. "2h 14m", "3d 5h")
    static func formatCooldown(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days > 0 {
            return hours > 0 ? "\(days)d \(hours)h" : "\(days)d"
        } else if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(max(minutes, 1))m"
        }
    }
}

// MARK: - Block Reasons

enum RemindBlockReason {
    case alreadyAnswered
    case notYetSent
    case maxRemindersReached
    case cooldownActive
    case dailyCapReached
    case personCapReached
}
