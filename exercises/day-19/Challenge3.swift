// Schedule and cancel a local reminder
// Build a fixture reminder helper that asks for alert permission in context and schedules a one-off reminder at least one second in the future. Use a stable task-specific identifier so rescheduling replaces the pending reminder.
// See lessons/day-19.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

import Foundation
import UserNotifications
enum ReminderError: Error { case denied, invalidDate }
// Add schedule and cancel methods for a task UUID.
