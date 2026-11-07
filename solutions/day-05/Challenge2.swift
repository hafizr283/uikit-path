// Worked solution: Extract form validation
// A UI can switch on the result to choose precise feedback. The same validation rule is now usable from a view model, a controller, and a unit test. Return a validated domain value instead of String when the architecture evolves.
// Read lessons/day-05.md for any surrounding types or setup.

import Foundation

enum FormError: Error { case blankTitle, titleTooLong }

func validateTitle(_ raw: String) -> Result<String, FormError> {
    let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !clean.isEmpty else { return .failure(.blankTitle) }
    guard clean.count <= 80 else { return .failure(.titleTooLong) }
    return .success(clean)
}
