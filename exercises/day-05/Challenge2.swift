// Extract form validation
// Write a pure function that validates a task title and returns its cleaned value or a descriptive error. Use it both for button state and saving.
// See lessons/day-05.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

import Foundation
enum FormError: Error { case blankTitle, titleTooLong }
func validateTitle(_ raw: String) -> Result<String, FormError> {
    // Validate
}
