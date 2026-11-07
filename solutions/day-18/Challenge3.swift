// Worked solution: Localize a task count with plural resources
// Plural behavior belongs to localization resources, because languages have different categories and sentence structures. The code intentionally states the required resource setup; it does not claim that String(localized:) invents singular translations automatically.
// Read lessons/day-18.md for any surrounding types or setup.

import Foundation

func remainingMessage(count: Int) -> String {
    String(
        localized: "\(count) tasks remaining",
        comment: "Number of unfinished tasks in the task list."
    )
}

// Xcode resource setup is part of this solution:
// 1. Add Localizable.xcstrings to the app target.
// 2. Build so Xcode extracts the interpolated sentence.
// 3. Add plural variation for the integer substitution.
// 4. English 'one':   [count] task remaining
//    English 'other': [count] tasks remaining
//    Use the catalog's generated count placeholder, not
//    the literal text [count].
// 5. Add the selected language's required plural forms.
// Without those catalog variations, the Swift function alone
// still has the English fallback "1 tasks remaining".
