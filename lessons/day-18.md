# Day 18: Accessibility & polished user experience

Build interfaces that adapt to people, language, and context.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/18/lesson) · [Course overview](../README.md)

## Outcomes

- Make UIKit controls understandable and usable with VoiceOver.
- Support Dynamic Type, Dark Mode, and right-to-left layouts.
- Use localization resources for text and plural forms.
- Respect Reduce Motion and provide clear, recoverable feedback.

## Before you begin

- Day 4: intrinsic content size and adaptive Auto Layout.
- Day 5: controls, labels, and keyboard interaction.
- Day 7: reusable components and animations.

## 1. Accessibility is part of the interaction model

VoiceOver presents an interface as a sequence of meaningful elements. A button needs a useful label, the correct trait, and a state when the state matters. 'Button 1' does not explain an action; 'Mark complete' does. accessibilityLabel describes the element, accessibilityValue describes its current value, and accessibilityHint can explain a non-obvious result. Avoid repeating the word button in the label when the button trait already announces it.

Decide which information should be read together and which controls need separate focus. A task title and subtitle can be grouped into one static summary, while its completion button remains independently actionable. Do not mark an entire card as one accessibility element if that hides actionable children. Test the actual swipe order, activation, editing, and error recovery with VoiceOver; adding properties without navigating the screen is not sufficient verification.

## 2. Let typography change the layout

Use preferredFont(forTextStyle:) and adjustsFontForContentSizeCategory for standard text styles. For a custom font, use UIFontMetrics to scale it. Set multiline content labels to numberOfLines = 0 when truncation would lose essential information. A fixed-height row that works at the default text size can become unusable at an accessibility size; let constraints and intrinsic content determine its height.

Dynamic Type affects hierarchy and density, not just font sizes. Horizontal arrangements may need to become vertical, secondary labels may wrap, and a toolbar may need a different presentation. Test the largest supported sizes with long content rather than a single short English title. Keep tappable targets generous, avoid overlapping hit areas, and check that the primary action remains reachable when the keyboard is visible.

## 3. Use semantic appearance and direction

Semantic colors such as label, secondaryLabel, systemBackground, and secondarySystemBackground adapt to light and dark appearances. A custom color should use named asset variants and be checked for contrast in each appearance. Do not communicate completion or failure with color alone: use text, a symbol, a state announcement, or another redundant cue. Images that contain text or assume a white background need their own review.

Use leading/trailing anchors and directionalLayoutMargins so layout follows the interface direction. Natural text alignment respects the language of the content. Some symbols should mirror and others should not; a navigation arrow and a company logo have different meanings. Test a right-to-left language and mixed content such as names, dates, and numbers. Forcing every view to left-to-right may make one screenshot look familiar while breaking localization.

## 4. Localize meaning, including plural rules

Keep user-facing text in String Catalogs or other supported localization resources. Give translators enough context to understand an action and distinguish a task from a background task. Do not build sentences by concatenating fragments: languages may reorder words, insert agreement, or use a different plural structure. Dates, numbers, and units should use locale-aware formatting instead of a hand-built English format.

String interpolation with String(localized:) can participate in a String Catalog; configure plural variations for counts in Xcode and supply translations. A single English singular/plural conditional is not a universal localization system. Use pseudolocalization or intentionally long translations to expose clipped controls. The user's task title is user content, so do not run it through a lookup table as if it were an interface localization key.

## 5. Respect motion and communicate changes

Animations can communicate a transition, but they should not be required to understand the result. Check UIAccessibility.isReduceMotionEnabled and provide a low-motion transition or immediate state change. Listen for setting changes when an interface remains active for a long time. Preserve the final state in both paths; skipping an animation must not skip the actual update.

Use accessibility notifications sparingly. A significant layout change may need focus moved to the newly relevant element; a completed action may need a short announcement. Do not announce every keystroke or steal focus repeatedly while results refresh. Show validation close to its field, connect the error to an accessible description, and leave the user a clear recovery action. Accessibility, localization, and error states all become easier when they are part of the component design from the start.

## Worked example: An adaptive, accessible task card

**File:** AccessibleTaskViewController.swift

```swift
import UIKit

@MainActor
final class AccessibleTaskViewController: UIViewController {
    private let completionButton = UIButton(type: .system)
    private var isComplete = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Task details")
        view.backgroundColor = .systemBackground

        let heading = UILabel()
        heading.text = String(localized: "Practice accessible UIKit")
        heading.font = .preferredFont(forTextStyle: .title2)
        heading.adjustsFontForContentSizeCategory = true
        heading.numberOfLines = 0

        let detail = UILabel()
        detail.text = String(localized: "Read the task, then mark it complete.")
        detail.font = .preferredFont(forTextStyle: .body)
        detail.adjustsFontForContentSizeCategory = true
        detail.textColor = .secondaryLabel
        detail.numberOfLines = 0

        let summary = UIStackView(arrangedSubviews: [heading, detail])
        summary.axis = .vertical
        summary.spacing = 8
        summary.isAccessibilityElement = true
        summary.accessibilityTraits = .staticText
        summary.accessibilityLabel = [
            heading.text, detail.text
        ].compactMap { $0 }.joined(separator: ". ")

        completionButton.accessibilityIdentifier = "task.completeButton"
        completionButton.addAction(UIAction { [weak self] _ in
            self?.toggleCompletion()
        }, for: .touchUpInside)
        updateButton()

        let stack = UIStackView(arrangedSubviews: [
            summary, completionButton
        ])
        stack.axis = .vertical
        stack.spacing = 24
        stack.directionalLayoutMargins = .init(
            top: 24, leading: 24, bottom: 24, trailing: 24
        )
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            stack.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor
            ),
            stack.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor
            ),
            completionButton.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 44
            )
        ])
    }

    private func toggleCompletion() {
        isComplete.toggle()
        updateButton()
        UIAccessibility.post(
            notification: .announcement,
            argument: isComplete
                ? String(localized: "Task completed")
                : String(localized: "Task marked incomplete")
        )
    }

    private func updateButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.title = isComplete
            ? String(localized: "Mark incomplete")
            : String(localized: "Mark complete")
        configuration.image = UIImage(
            systemName: isComplete ? "checkmark.circle.fill" : "circle"
        )
        configuration.imagePadding = 8
        completionButton.configuration = configuration
        completionButton.accessibilityValue = isComplete
            ? String(localized: "Completed")
            : String(localized: "Not completed")
    }
}
```

### Walkthrough and setup

1. Add this controller to the app target and present or push it. Xcode can extract the String(localized:) values into a String Catalog when localization is configured.
2. Turn on VoiceOver and swipe: the summary is one element and the completion button is another. Activate the button and check its new action and state.
3. Increase Dynamic Type, switch Dark Mode, and inspect a right-to-left localization. The semantic colors and directional anchors adapt without manual appearance branching.
4. The static summary is intentionally grouped. The separate completion button remains reachable; making the outer stack a single accessibility element would hide that interaction.
5. This short screen fits typical sizes, but a longer production detail view should use a scroll view. Test the actual smallest device and largest supported type size instead of assuming the sample's content length.

**Expected behavior:** The task summary and completion action are independently reachable. Tapping changes the visible icon, action title, and accessible state, with readable semantic colors in light and dark appearances.

## Challenge 1: Repair a text label for Dynamic Type

**Level:** Warm-up

A cell uses a 14-point fixed font, one line, and a fixed 20-point label height. Replace the label configuration and explain which constraint must be removed.

### Requirements

- Use the body text style and automatic content-size updates.
- Allow the title to wrap.
- Use semantic foreground color.
- Do not constrain the label to a fixed height.

### Starter

```swift
import UIKit
@MainActor
func makeTitleLabel() -> UILabel {
    let label = UILabel()
    // Configure for variable text and content size.
    return label
}
```

<details>
<summary>Hints</summary>

- A UILabel's intrinsic size can drive a self-sizing cell.
- Automatic font updates require adjustsFontForContentSizeCategory.

</details>

### Acceptance checks

- A long title wraps at narrow widths.
- The label grows at accessibility text sizes.
- Text remains legible in light and dark appearances.

<details>
<summary>Worked solution</summary>

```swift
import UIKit
@MainActor
func makeTitleLabel() -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .body)
    label.adjustsFontForContentSizeCategory = true
    label.numberOfLines = 0
    label.textColor = .label
    label.textAlignment = .natural
    return label
}
// Remove the fixed height == 20 constraint.
// Pin the label's edges so the cell has a complete vertical chain.
```

A scalable font alone is insufficient if a fixed-height constraint clips it. Self-sizing needs a complete set of vertical relationships and no contradictory fixed height.

</details>

## Challenge 2: Preserve the result when Reduce Motion is enabled

**Level:** Core

A banner slides down when a task is saved. Implement a helper that always reveals the banner, using a slide/fade only when Reduce Motion is off.

### Requirements

- Run UIKit mutations on MainActor.
- Give both paths the same final alpha, transform, and visibility.
- Read the user's Reduce Motion setting at the time of the action.

### Starter

```swift
import UIKit
@MainActor
func reveal(_ banner: UIView) {
    // Respect Reduce Motion and preserve the final state.
}
```

<details>
<summary>Hints</summary>

- CGAffineTransform.identity is the final position.
- Move the final-state assignments into one closure shared by both paths.

</details>

### Acceptance checks

- With Reduce Motion on, the banner appears immediately in its final position.
- With it off, the banner animates to exactly the same state.
- The banner never remains at alpha zero after a completed reveal.

<details>
<summary>Worked solution</summary>

```swift
import UIKit
@MainActor
func reveal(_ banner: UIView) {
    banner.isHidden = false
    let finish = {
        banner.alpha = 1
        banner.transform = .identity
    }

    if UIAccessibility.isReduceMotionEnabled {
        finish()
    } else {
        banner.alpha = 0
        banner.transform = CGAffineTransform(
            translationX: 0, y: -12
        )
        UIView.animate(withDuration: 0.2, animations: finish)
    }
}
```

The setting changes the transition rather than the outcome. A production component that can receive overlapping reveal/hide commands should also manage or cancel the previous animation, then apply the requested final state.

</details>

## Challenge 3: Localize a task count with plural resources

**Level:** Stretch

Replace hard-coded English count assembly with a localized count. Use Xcode's String Catalog plural variants for an English one/other example, then inspect what a second language needs.

### Requirements

- Keep the entire sentence in a localization resource.
- Provide singular and plural variants through the catalog.
- Test zero, one, and two tasks.
- Do not translate user-entered task titles as localization keys.

### Starter

```swift
import Foundation
func remainingMessage(count: Int) -> String {
    // Replace concatenated fragments with a localizable sentence.
    "\(count) tasks remaining"
}
```

<details>
<summary>Hints</summary>

- String(localized:) accepts an interpolated localized string.
- After building, select the catalog entry and use Vary by Plural on the count substitution.

</details>

### Acceptance checks

- The configured English catalog displays 0 tasks, 1 task, and 2 tasks remaining.
- A long translation does not clip the label.
- Inspect the second language's plural categories rather than copying English rules.

<details>
<summary>Worked solution</summary>

```swift
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
```

Plural behavior belongs to localization resources, because languages have different categories and sentence structures. The code intentionally states the required resource setup; it does not claim that String(localized:) invents singular translations automatically.

</details>

## Knowledge check

### 1. Which property describes a control's current state, such as Completed?

A. accessibilityIdentifier

B. accessibilityValue

C. restorationIdentifier

D. reuseIdentifier

<details>
<summary>Answer and explanation</summary>

**B. accessibilityValue**

Use accessibilityValue for relevant current values or states; identifiers serve tests and lookup.

</details>

### 2. Why can a preferred font still become clipped at a large text size?

A. Dynamic Type prevents multiline labels

B. A fixed-height constraint can stop the view from growing

C. Semantic colors disable layout

D. VoiceOver changes the string encoding

<details>
<summary>Answer and explanation</summary>

**B. A fixed-height constraint can stop the view from growing**

Typography and layout must both adapt. Remove contradictory fixed heights and provide complete constraints.

</details>

### 3. Which anchors should generally express horizontal reading direction?

A. Leading and trailing

B. Only left and right

C. Center X for every edge

D. Top and bottom

<details>
<summary>Answer and explanation</summary>

**A. Leading and trailing**

Leading and trailing adapt to right-to-left interface direction.

</details>

### 4. What should Reduce Motion change?

A. Whether the save succeeds

B. Whether text appears at all

C. The transition while preserving its final state

D. The user's stored data

<details>
<summary>Answer and explanation</summary>

**C. The transition while preserving its final state**

The interaction outcome remains the same; motion is reduced or replaced.

</details>

### 5. What is the main problem with concatenating count + translated noun + sentence suffix?

A. Swift cannot concatenate strings

B. Word order and plural grammar vary across languages

C. It always crashes

D. It prevents button targets

<details>
<summary>Answer and explanation</summary>

**B. Word order and plural grammar vary across languages**

Localize the complete message with count variations so translators can express the correct grammar.

</details>

## Common pitfalls

- Grouping an entire interactive card can hide its child buttons from VoiceOver.
- A custom fixed font without UIFontMetrics ignores Dynamic Type.
- Color alone is insufficient to communicate completion or an error.
- Leading/trailing support is undermined by arbitrary forced left-to-right settings.
- A pluralizable Swift string still needs the appropriate resource variants.

## PocketTasks milestone: Make PocketTasks usable beyond the default settings

1. Audit the task list, editor, details, and errors with VoiceOver.
2. Remove fixed text heights and use scalable typography in reusable cells.
3. Add a String Catalog with count pluralization and a second language or pseudolocalized test.
4. Record results for Dark Mode, maximum text size, right-to-left layout, and Reduce Motion.

## Before you move on

- Navigate the full task flow with VoiceOver and correct focus order.
- Test the largest supported text size on a narrow screen.
- Inspect light and dark appearances with readable contrast.
- Verify one right-to-left layout and one long translation.
- Confirm Reduce Motion preserves every interaction's final state.

## Official references

- [Apple: UIAccessibility](https://developer.apple.com/documentation/uikit/uiaccessibility)
- [Apple: UIFontMetrics](https://developer.apple.com/documentation/uikit/uifontmetrics)
- [Apple: Localizing and varying text with a string catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
