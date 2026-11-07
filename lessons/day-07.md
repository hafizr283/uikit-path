# Day 07: Reusable UIKit components and interaction

Separate rendering from business logic, configure every state, and add purposeful motion.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/7/lesson) · [Course overview](../README.md)

## Outcomes

- Build reusable UIView components with small configuration and event APIs.
- Keep navigation, persistence, and domain decisions outside presentation components.
- Understand gestures, hit testing, and control interactions.
- Animate state changes while respecting interrupted interactions and Reduce Motion.

## Before you begin

- Days 2–6: weak captures, layout, controls, and navigation.
- A UIKit app target on iOS 17 or later.
- Be ready to test a component with more than one configuration.

## A reusable component has a focused contract

A task card should render a title, notes, and completion state, then emit an intent such as toggle requested. It should not decide which repository to save to or which screen to push. Give the view a configuration value and a callback or delegate for user actions. This separates what the interface looks like from what the app decides to do.

A custom UIView is useful when a group of controls has a repeated visual structure or interaction. Do not extract every two-line label into its own abstraction just to make files smaller. A good component API hides its internal stack and constraints while exposing meaningful operations such as configure(with:). Keeping labels private prevents callers from placing the component into contradictory states.

## Configuration must replace old state completely

Views may be reconfigured many times, particularly once you use reusable table and collection cells. A configure method should assign every property that can differ between models: text, images, hidden state, enabled state, accessibility values, and any transient visual state. If you only set isHidden when notes are absent, the next task with notes may remain hidden.

Render from a complete configuration rather than applying unexplained incremental changes from unrelated callers. Stable model identity becomes important when asynchronous work finishes later; a response for an old configuration must not overwrite a newly configured view. Days 8–12 expand this into cell reuse and image loading. Today, test one view with empty notes, populated notes, complete state, and incomplete state in sequence.

## Construction can use code or a XIB

Programmatic views usually configure subviews and constraints in a shared setup method called from the initializer. A required coder initializer can either support Interface Builder construction or fail deliberately with a clear message when the type is programmatic-only. Do not accidentally call the setup method twice or load a XIB whose root recursively creates another copy of the same custom view.

When using a XIB, check the file owner, custom class, module, outlet connections, and top-level object type. Bundle lookup matters when a component moves into a package or framework. Keep reusable colors, typography, spacing, and corner radii in a small design vocabulary so screens feel related. Semantic system colors adapt to appearance, and text styles adapt to Dynamic Type when you enable adjustment.

## Gestures and hit testing should support the action

UIKit hit testing finds the appropriate view to receive a touch, taking hierarchy and visibility into account. A view outside its parent's hit-test bounds may be visible but not receive touches as you expect. Transparent color alone does not make a view ignore interaction. Prefer a real UIButton or UIControl for an action that behaves like a button; you receive accessibility and control semantics without rebuilding them.

Gesture recognizers are useful for interactions such as a long press or a pan. A continuous recognizer changes state through began, changed, and ended; trigger a one-time menu on began rather than on every callback. Recognizers attached to a container can interfere with buttons and scrolling through touch-cancellation behavior. Decide whether simultaneous recognition is appropriate and test the actual interaction, not just whether the recognizer fires once.

## Animation should communicate a state transition

Animate a change that helps the user understand cause and effect: a checkmark appears, a panel expands, or feedback fades in. Change the model first and render a consistent target state. Avoid making the animation itself the source of truth. Constraint animations require layoutIfNeeded on the appropriate common ancestor, while opacity and transforms can be animated directly.

Respect UIAccessibility.isReduceMotionEnabled by simplifying or removing nonessential motion. Repeated taps can arrive before an animation ends, so either support interruption or intentionally manage availability. UIViewPropertyAnimator is useful for interactive or interruptible transitions. If you use a simple UIView animation, beginFromCurrentState and allowUserInteraction can help avoid obvious jumps and blocked controls, but still test the final model and view state after rapid input.

## Worked example: A task card that emits intent and renders complete state

**File:** Day07TaskCard.swift

```swift
import UIKit

struct TaskCardContent {
    let title: String
    let notes: String
    let isComplete: Bool
}

@MainActor
final class TaskCardView: UIView {
    var onToggle: (@MainActor () -> Void)?
    private let titleLabel = UILabel()
    private let notesLabel = UILabel()
    private let toggleButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 18
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits.insert(.header)
        notesLabel.font = .preferredFont(forTextStyle: .body)
        notesLabel.adjustsFontForContentSizeCategory = true
        notesLabel.textColor = .secondaryLabel
        notesLabel.numberOfLines = 0
        toggleButton.addAction(UIAction { [weak self] _ in
            self?.onToggle?()
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            titleLabel, notesLabel, toggleButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            toggleButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    func configure(with content: TaskCardContent) {
        titleLabel.text = content.title
        notesLabel.text = content.notes
        notesLabel.isHidden = content.notes.isEmpty
        var config = UIButton.Configuration.tinted()
        config.title = content.isComplete ? "Mark unfinished" : "Mark complete"
        config.image = UIImage(systemName:
            content.isComplete ? "checkmark.circle.fill" : "circle"
        )
        config.imagePadding = 8
        toggleButton.configuration = config
        toggleButton.accessibilityLabel = "Toggle task completion"
        toggleButton.accessibilityValue = content.isComplete ? "Complete" : "Unfinished"
    }
}

@MainActor
final class CardDemoViewController: UIViewController {
    private let card = TaskCardView(frame: .zero)
    private var isComplete = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Reusable task card"
        view.backgroundColor = .systemGroupedBackground
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
        card.onToggle = { [weak self] in
            guard let self else { return }
            self.isComplete.toggle()
            self.render()
        }
        render()
    }

    private func render() {
        card.configure(with: TaskCardContent(
            title: "Build one reusable component",
            notes: "The controller owns the state; the card renders it.",
            isComplete: isComplete
        ))
    }
}
```

### Walkthrough and setup

1. Add the file to the UIKit app and use CardDemoViewController as a navigation root. TaskCardView is a view component, not another view controller.
2. The configuration contains all data needed to render the card. configure explicitly sets both empty and nonempty notes behavior and both completion states.
3. The card emits onToggle but never edits a model, saves a database record, or performs navigation. The controller changes its state and asks the card to render again.
4. Both initializers call one setup method. This supports programmatic creation and basic storyboard/XIB unarchiving, provided Interface Builder is not also duplicating the component's internally created content.
5. Toggle several times, increase text size, and configure the same card with different notes. Its view hierarchy stays the same while the content changes.

**Expected behavior:** A reusable task card whose action alternates between Mark complete and Mark unfinished. The controller owns completion state, and the component updates its button symbol and accessibility value.

## Challenge 1: Fix stale hidden state

**Level:** Warm-up

A reusable subtitle view hides its label when text is empty, but never unhides it for the next item. Replace the configuration logic with a complete assignment.

### Requirements

- Set the text every time.
- Set isHidden for both empty and nonempty input.
- Do not recreate the label.

### Starter

```swift
func configure(subtitle: String) {
    subtitleLabel.text = subtitle
    if subtitle.isEmpty { subtitleLabel.isHidden = true }
}
```

<details>
<summary>Hints</summary>

- A Boolean expression can be assigned directly.
- Reconfiguration must replace old state, not only add changes.

</details>

### Acceptance checks

- Empty then nonempty text makes the label visible again.
- Nonempty then empty text hides it.
- Repeated identical configurations do not create subviews.

<details>
<summary>Worked solution</summary>

```swift
// Inside a view type that owns subtitleLabel:
func configure(subtitle: String) {
    subtitleLabel.text = subtitle
    subtitleLabel.isHidden = subtitle.isEmpty
}
```

The old code only handled the transition into an empty state. Direct assignment makes the result depend solely on the current input, so configuration order no longer changes the result.

</details>

## Challenge 2: Handle a long press once

**Level:** Core

Add a long-press recognizer to a task view. Emit one callback when the press begins, rather than repeatedly during changed and ended states.

### Requirements

- Use a dedicated method with an Objective-C-compatible selector.
- Check recognizer.state.
- Keep the event callback separate from navigation or storage.

### Starter

```swift
import UIKit
@MainActor
final class PressableTaskView: UIView {
    var onLongPress: (@MainActor () -> Void)?
    // Install recognizer and handle its state
}
```

<details>
<summary>Hints</summary>

- UILongPressGestureRecognizer is a continuous recognizer.
- The .began state is the one-time start of a recognized press.

</details>

### Acceptance checks

- Holding a press emits one callback, not a stream.
- Ending or cancelling the gesture does not emit another callback.
- The parent can choose a different response without editing the view.

<details>
<summary>Worked solution</summary>

```swift
import UIKit

@MainActor
final class PressableTaskView: UIView {
    var onLongPress: (@MainActor () -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        installGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        installGesture()
    }

    private func installGesture() {
        let gesture = UILongPressGestureRecognizer(
            target: self, action: #selector(handleLongPress(_:))
        )
        addGestureRecognizer(gesture)
    }

    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }
        onLongPress?()
    }
}
```

The component reports intent without deciding what the parent should do. Long press must not be the only way to access an essential action: add a visible button or accessibility custom action when integrating it into a real screen.

</details>

## Challenge 3: Animate feedback while respecting Reduce Motion

**Level:** Stretch

Write a main-actor function that shows or hides an existing feedback label by changing opacity. Use an immediate transition when Reduce Motion is enabled and an interruptible simple animation otherwise.

### Requirements

- The caller owns the actual success/error state.
- Keep the label in layout during the fade.
- Support rapid repeated visibility changes without queuing long animations.

### Starter

```swift
@MainActor
func setFeedbackVisible(_ visible: Bool, label: UILabel) {
    // Update opacity
}
```

<details>
<summary>Hints</summary>

- isHidden does not itself produce an opacity animation.
- beginFromCurrentState starts from the current visual transition.

</details>

### Acceptance checks

- Reduce Motion causes an immediate state change.
- Rapid show/hide calls settle on the latest requested opacity.
- Hidden feedback is removed from accessibility exposure without removing its layout space.

<details>
<summary>Worked solution</summary>

```swift
import UIKit

@MainActor
func setFeedbackVisible(_ visible: Bool, label: UILabel) {
    let targetAlpha: CGFloat = visible ? 1 : 0
    label.isHidden = false
    label.accessibilityElementsHidden = !visible
    if UIAccessibility.isReduceMotionEnabled {
        label.layer.removeAllAnimations()
        label.alpha = targetAlpha
        return
    }
    UIView.animate(
        withDuration: 0.2,
        delay: 0,
        options: [.beginFromCurrentState, .allowUserInteraction]
    ) {
        label.alpha = targetAlpha
    }
}
```

Opacity changes presentation, while the caller's state remains authoritative. Keeping the label in layout avoids a simultaneous jump in surrounding geometry. The accessibility setting prevents visually hidden feedback from remaining in the accessibility sequence. For a layout-collapsing message, design a separate stack/constraint transition.

</details>

## Knowledge check

### 1. What should a reusable task card normally do when its completion button is tapped?

A. Choose a database and save directly.

B. Push a hardcoded detail screen.

C. Emit an intent that its owner handles.

D. Look up a global controller.

<details>
<summary>Answer and explanation</summary>

**C. Emit an intent that its owner handles.**

The component renders and reports interaction; its owner controls domain behavior and navigation.

</details>

### 2. Why must configure assign isHidden for both true and false cases?

A. Views can retain state from earlier configurations.

B. UIKit resets it automatically otherwise.

C. Hidden views cannot contain labels.

D. It avoids every need for testing.

<details>
<summary>Answer and explanation</summary>

**A. Views can retain state from earlier configurations.**

A reused or reconfigured view retains properties unless new configuration replaces them.

</details>

### 3. When should a one-time action for a long press usually fire?

A. On every state change.

B. Only at .began.

C. Only in deinit.

D. Whenever the view lays out.

<details>
<summary>Answer and explanation</summary>

**B. Only at .began.**

The recognizer transitions through multiple states; began identifies the start of a recognized press.

</details>

### 4. What is usually preferable for an ordinary accessible tap action?

A. A UILabel with hidden gesture behavior.

B. A UIButton or appropriate UIControl.

C. A transparent window above the app.

D. A global touch override.

<details>
<summary>Answer and explanation</summary>

**B. A UIButton or appropriate UIControl.**

Controls provide established interaction, accessibility, and state semantics.

</details>

### 5. What should remain the source of truth during an animation?

A. The animation's elapsed percentage only.

B. The view's model or explicit UI state.

C. The most recent screenshot.

D. The screen's fixed pixel coordinates.

<details>
<summary>Answer and explanation</summary>

**B. The view's model or explicit UI state.**

Animations communicate a transition between states; they should not replace the actual state model.

</details>

## Common pitfalls

- Exposing all internal labels lets callers create inconsistent component states.
- Incremental configuration can leave stale hidden, enabled, or image values.
- Calling shared setup twice duplicates constraints and event handlers.
- A recognizer on a container can cancel touches intended for a nested button.
- Essential actions need an accessible alternative to an undiscoverable gesture.

## PocketTasks milestone: Extract PocketTasks' reusable task card

1. Move task-card rendering into a custom UIView with a complete configuration value.
2. Emit a toggle or edit intent and let the controller decide the resulting action.
3. Exercise empty notes, long text, and both completion states on the same instance.
4. Introduce a small set of semantic style tokens and ensure nonessential animation respects Reduce Motion.

## Before you move on

- Explain the component's input and event contract in one sentence.
- Configure one view with multiple models in different orders.
- Trace ownership of the card, button action, and controller callback.
- Test a gesture's began, changed, cancelled, and ended behavior.
- Demonstrate feedback with Reduce Motion enabled and with rapid input.

## Official references

- [Apple — UIView](https://developer.apple.com/documentation/uikit/uiview)
- [Apple — UIGestureRecognizer](https://developer.apple.com/documentation/uikit/uigesturerecognizer)
- [Apple — UIViewPropertyAnimator](https://developer.apple.com/documentation/uikit/uiviewpropertyanimator)
- [Apple — UIAccessibility](https://developer.apple.com/documentation/uikit/uiaccessibility)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
