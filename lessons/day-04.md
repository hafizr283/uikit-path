# Day 04: Auto Layout without guesswork

Describe relationships, reason about priorities, and make interfaces survive real content.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/4/lesson) · [Course overview](../README.md)

## Outcomes

- Build layouts using anchors, safe areas, margins, and stack views.
- Distinguish missing constraints from contradictory constraints.
- Use intrinsic content size, hugging, and compression resistance intentionally.
- Debug long text, Dynamic Type, small screens, and size changes.

## Before you begin

- Day 3 UIKit app setup and lifecycle.
- Run examples as a root controller inside the Day 3 navigation controller.
- An iOS simulator with several device sizes and accessibility text sizes.

## Constraints describe a solvable system

A constraint is a relationship such as label.leading = container.leading + 20 or button.height ≥ 44. Auto Layout solves these relationships to determine view geometry. A view usually needs enough information to determine its horizontal position and width and its vertical position and height; intrinsic content size can supply part of that information. You do not always need four explicit constraints.

When creating constrained views in code, set translatesAutoresizingMaskIntoConstraints to false. Otherwise the autoresizing mask can produce additional constraints that compete with yours. Add views into a common hierarchy before activating constraints between them. Activate related constraints together with NSLayoutConstraint.activate so the intended relationships are easy to inspect and update.

## Safe areas, margins, and directional edges

The safe area describes the region not obscured by bars and other relevant system UI. It is not a universal 20-point padding rule. Pin primary content to safeAreaLayoutGuide when it should avoid those regions; use layoutMarginsGuide or directionalLayoutMargins for your own interior spacing. Decorative backgrounds often extend to the view's full edges while content remains inside its safe area.

Prefer leading and trailing over left and right for reading-order layouts. They adapt to right-to-left languages. Layout guides have no drawing or event behavior: they provide geometry without adding a visible view. Avoid storing UIScreen.main.bounds as the layout width; an app's window may be smaller than the screen on iPad, and the relevant container can resize independently.

## Intrinsic size and the two priorities people confuse

UILabel and UIButton can describe a natural size based on their content and font. Content hugging resists stretching beyond that intrinsic size. Compression resistance resists shrinking below it. Higher priority means the view argues more strongly to keep that preference; neither setting is a replacement for the positional relationships the layout needs.

For a row containing a descriptive label and a short status badge, increase the badge's horizontal hugging and compression resistance so the descriptive text takes extra space and yields first when space becomes tight. For multiline text, set numberOfLines to 0 and provide a determinable width so UIKit can calculate height. Avoid fixing text-containing views to a small height when Dynamic Type or localization can make their content grow.

## Stack views manage layout, not every concern

UIStackView arranges its arrangedSubviews along an axis using alignment, distribution, and spacing. It is ideal for forms and groups of related controls. A stack still needs constraints that position it in its parent. Its arranged views may need extra constraints when intrinsic sizes alone do not express the design, such as a minimum button height.

fill lets intrinsic sizes and priorities influence the result; fillEqually makes arranged views equal along the stack's axis. Hiding an arranged subview normally removes its contribution to the stack's layout. Removing it from arrangedSubviews does not necessarily remove it from the view hierarchy, so removeFromSuperview when you want it gone completely. Nested stacks can be useful, but deeply nested stacks can become harder to debug than a few direct constraints.

## Debug the system before adding another constraint

An ambiguous layout has more than one valid solution because information is missing. An unsatisfiable layout has requirements that cannot all be true, so UIKit breaks a constraint and logs a warning. Give important constraints identifiers, inspect the console, and use Xcode's View Debugger. A symbolic breakpoint on UIViewAlertForUnsatisfiableConstraints can stop near the failure during development.

Test with a long task title, an empty subtitle, accessibility text sizes, a compact phone, and a wide iPad window. Fix the relationship causing the problem instead of adding random widths until one screenshot looks right. Prefer flexible inequalities and sensible priorities when content competes. Never silence a conflict by lowering every priority; you should be able to explain which requirement may yield and why.

## Worked example: A content-sized task summary card

**File:** Day04TaskSummaryViewController.swift

```swift
import UIKit

@MainActor
final class TaskSummaryViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Task summary"
        view.backgroundColor = .systemGroupedBackground

        let heading = UILabel()
        heading.text = "Practice layouts that adapt"
        heading.font = .preferredFont(forTextStyle: .title2)
        heading.adjustsFontForContentSizeCategory = true
        heading.numberOfLines = 0

        let detail = UILabel()
        detail.text = "Try a longer title, rotate the simulator, and increase text size."
        detail.font = .preferredFont(forTextStyle: .body)
        detail.adjustsFontForContentSizeCategory = true
        detail.textColor = .secondaryLabel
        detail.numberOfLines = 0

        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Mark complete"
        button.configuration = configuration
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addAction(UIAction { [weak button] _ in
            button?.configuration?.title = "Completed"
            button?.isEnabled = false
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [heading, detail, button])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 20, leading: 20, bottom: 20, trailing: 20
        )
        stack.backgroundColor = .secondarySystemGroupedBackground
        stack.layer.cornerRadius = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: safe.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -20)
        ])
    }
}
```

### Walkthrough and setup

1. Add this file to the UIKit target, then use TaskSummaryViewController() as the root of your navigation controller.
2. The stack's width comes from its leading and trailing constraints. That width allows both multiline labels to derive their heights.
3. The stack's vertical size comes from its arranged subviews, spacing, and margins. There is no fixed card height to fight larger text.
4. The filled button has a minimum touch height, not a forced text-label height. Its action changes only its state; the layout handles the new title.
5. Test large text sizes. This single-card example does not scroll; if the entire card becomes taller than the screen, the next day's scroll-container pattern is the correct extension rather than shrinking accessible text.

**Expected behavior:** A rounded summary card below the navigation bar. Text wraps and the card grows with content. Tapping Mark complete changes the button to Completed and disables it.

## Challenge 1: Center a fixed-size icon correctly

**Level:** Warm-up

Write a helper that adds an image view to a container and centers it in the safe area with an 80-by-80 size.

### Requirements

- Disable autoresizing-mask constraints.
- Add the view before activating relationships.
- Use safe-area center anchors.

### Starter

```swift
import UIKit
@MainActor
func addCenteredIcon(to container: UIView) {
    // Create and constrain an image view
}
```

<details>
<summary>Hints</summary>

- A fixed icon is appropriate for an explicit visual asset size.
- Use systemName for a built-in SF Symbol.

</details>

### Acceptance checks

- The icon remains centered after rotation.
- No autoresizing-mask conflict appears.
- Only the icon has a fixed size; the container remains flexible.

<details>
<summary>Worked solution</summary>

```swift
import UIKit

@MainActor
func addCenteredIcon(to container: UIView) {
    let icon = UIImageView(image: UIImage(systemName: "checkmark.circle"))
    icon.contentMode = .scaleAspectFit
    icon.tintColor = .systemGreen
    icon.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(icon)
    NSLayoutConstraint.activate([
        icon.centerXAnchor.constraint(equalTo: container.safeAreaLayoutGuide.centerXAnchor),
        icon.centerYAnchor.constraint(equalTo: container.safeAreaLayoutGuide.centerYAnchor),
        icon.widthAnchor.constraint(equalToConstant: 80),
        icon.heightAnchor.constraint(equalToConstant: 80)
    ])
}
```

The two center constraints determine position, and the two size constraints determine dimensions. Fixed sizes can be intentional for icons; they are often inappropriate for labels containing variable text.

</details>

## Challenge 2: Protect a short status badge

**Level:** Core

Build a horizontal row containing a long title and a short Done badge. The title should wrap and use extra width while the badge stays close to its natural width.

### Requirements

- Use a horizontal stack.
- Set title.numberOfLines to 0.
- Give the badge stronger horizontal hugging and compression resistance.

### Starter

```swift
import UIKit
@MainActor
func makeStatusRow() -> UIStackView {
    // Configure title and badge
}
```

<details>
<summary>Hints</summary>

- Hugging resists growth; compression resistance resists shrinkage.
- Constrain the returned stack's width in its eventual parent.

</details>

### Acceptance checks

- A long title wraps rather than truncating immediately.
- The badge does not stretch across unused space.
- You can explain why required compression resistance is acceptable only while this row remains feasible.

<details>
<summary>Worked solution</summary>

```swift
import UIKit

@MainActor
func makeStatusRow() -> UIStackView {
    let title = UILabel()
    title.text = "A task title that may wrap across several lines"
    title.font = .preferredFont(forTextStyle: .body)
    title.adjustsFontForContentSizeCategory = true
    title.numberOfLines = 0

    let badge = UILabel()
    badge.text = "Done"
    badge.font = .preferredFont(forTextStyle: .caption1)
    badge.adjustsFontForContentSizeCategory = true
    badge.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    badge.setContentCompressionResistancePriority(.required, for: .horizontal)

    let row = UIStackView(arrangedSubviews: [title, badge])
    row.axis = .horizontal
    row.alignment = .firstBaseline
    row.spacing = 12
    return row
}
```

The badge has stronger preferences, so the title accepts extra width and gives up space first. The parent must still provide a feasible row width. At extreme text sizes, a vertical arrangement may be a better design than insisting on this row.

</details>

## Challenge 3: Update a stored constraint instead of duplicating it

**Level:** Stretch

Build a controller with an expandable panel. A button should alternate its height between 80 and 160 points without installing a new height constraint on every tap.

### Requirements

- Store the height constraint.
- Change its constant on the main actor.
- Use layoutIfNeeded inside an animation block to animate the layout result.

### Starter

```swift
import UIKit
@MainActor
final class ExpandViewController: UIViewController {
    private var panelHeight: NSLayoutConstraint?
    // Create panel and toggle button
}
```

<details>
<summary>Hints</summary>

- Constraints are objects with mutable constants.
- Establish the initial layout before changing the constraint.

</details>

### Acceptance checks

- Repeated taps produce no constraint-conflict logs.
- The panel alternates between two heights.
- The stored constraint remains the one installed during setup.

<details>
<summary>Worked solution</summary>

```swift
import UIKit

@MainActor
final class ExpandViewController: UIViewController {
    private var panelHeight: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let panel = UIView()
        panel.backgroundColor = .systemTeal
        panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)
        let height = panel.heightAnchor.constraint(equalToConstant: 80)
        panelHeight = height
        NSLayoutConstraint.activate([
            panel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            height
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Resize", primaryAction: UIAction { [weak self] _ in
                self?.togglePanel()
            }
        )
    }

    private func togglePanel() {
        guard let panelHeight else { return }
        view.layoutIfNeeded()
        panelHeight.constant = panelHeight.constant == 80 ? 160 : 80
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
}
```

There is one active height constraint throughout the screen's lifetime. Changing its constant modifies the existing layout system instead of creating contradictory requirements. The animation closure is short-lived; retaining self for the animation is intentional here.

</details>

## Knowledge check

### 1. What does content hugging resist?

A. Shrinking below intrinsic size.

B. Growing beyond intrinsic size.

C. Moving outside a scroll view.

D. Becoming first responder.

<details>
<summary>Answer and explanation</summary>

**B. Growing beyond intrinsic size.**

Hugging prefers the natural size by resisting extra space; compression resistance protects against shrinking.

</details>

### 2. What is an ambiguous layout?

A. Two required constraints contradict each other.

B. More than one geometry satisfies the available constraints.

C. Every label has numberOfLines = 0.

D. A view has a safe area.

<details>
<summary>Answer and explanation</summary>

**B. More than one geometry satisfies the available constraints.**

The system lacks enough information to select a unique solution.

</details>

### 3. Why use leading/trailing rather than left/right?

A. They are always faster.

B. They automatically add margins.

C. They follow layout direction, including right-to-left languages.

D. They disable Auto Layout.

<details>
<summary>Answer and explanation</summary>

**C. They follow layout direction, including right-to-left languages.**

Directional edges express reading-order relationships instead of physical screen edges.

</details>

### 4. A multiline label needs what to calculate its wrapping height?

A. A determined available width.

B. A fixed height of 44.

C. An explicit contentSize.

D. A separate UIWindow.

<details>
<summary>Answer and explanation</summary>

**A. A determined available width.**

Text must know its available width before its wrapped height can be determined.

</details>

### 5. How should a repeatedly resized panel usually update its height?

A. Add a new equal-height constraint every tap.

B. Change the constant of a retained constraint.

C. Set all priorities to 1.

D. Recreate the root view every time.

<details>
<summary>Answer and explanation</summary>

**B. Change the constant of a retained constraint.**

Updating the existing requirement avoids contradictory constraints and unnecessary reconstruction.

</details>

## Common pitfalls

- Pinning both edges and also requiring an incompatible fixed width creates an unsatisfiable system.
- Leaving translatesAutoresizingMaskIntoConstraints enabled is a common source of unexpected constraints.
- A multiline label with no determinable width cannot calculate a useful wrapped height.
- Removing an arranged subview is not the same operation as removing it from its superview.
- A layout that works for short English text is not yet validated for real content.

## PocketTasks milestone: Lay out a task summary screen

1. Create a summary view with a task title, optional notes, status, and primary action.
2. Use semantic fonts and multiline text with no fixed card height.
3. Add constraint identifiers to the relationships you expect to debug.
4. Record results on a compact phone and a wide simulator, including large text.

## Before you move on

- Explain position, size, and intrinsic contributions for the example.
- Describe hugging and compression resistance without confusing them.
- Intentionally create and then fix one missing constraint and one conflict.
- Test a long title, rotation, and an accessibility text size.
- Explain which elements should use safe areas versus full-view edges.

## Official references

- [Apple — Auto Layout Guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/)
- [Apple — NSLayoutAnchor](https://developer.apple.com/documentation/uikit/nslayoutanchor)
- [Apple — UIStackView](https://developer.apple.com/documentation/uikit/uistackview)
- [Apple — UIView safeAreaLayoutGuide](https://developer.apple.com/documentation/uikit/uiview/safearealayoutguide)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
