# Day 05: Forms, controls, scrolling, and the keyboard

Build input flows that validate clearly and remain usable when the keyboard appears.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/5/lesson) · [Course overview](../README.md)

## Outcomes

- Choose UIKit controls and connect target–action, UIAction, and delegate callbacks.
- Build a vertical form using UIScrollView's content and frame layout guides.
- Handle first responder, return keys, keyboard avoidance, and dismissal.
- Keep raw text input separate from validated task data.

## Before you begin

- Day 4 Auto Layout, stack views, and content sizing.
- A UIKit target on iOS 17 or later for the course examples.
- Use the simulator's software keyboard when testing keyboard avoidance.

## Controls emit events; delegates answer richer questions

UIControl subclasses such as UIButton, UISwitch, UISlider, and UISegmentedControl emit events. A button commonly uses touchUpInside, a text field uses editingChanged, and a switch uses valueChanged. Connect these with target–action selectors or UIAction closures. Choose one clear wiring style per behavior and avoid installing multiple identical actions when a view reappears.

Delegates support richer interactions. UITextFieldDelegate can decide whether Return should move focus or finish editing, and UITextViewDelegate can observe multiline editing. A text field and a text view are not interchangeable: fields suit short single-line values, while text views support multiline input and scrolling. Keep event handlers small; read the control's value, validate or update state, and render the result.

## Validation is a conversation with the user

Raw input is not yet a valid domain value. Trim only where the product rule requires it, check required fields and length, and return useful reasons for rejection. Do not silently erase what the user typed after a failure. An error should say how to fix the value, and the form should preserve the user's other fields.

Use keyboardType, returnKeyType, autocapitalizationType, and textContentType where they actually describe the field. A task title is ordinary text, not an email address. Disabling Save when input is invalid provides a cue, but it does not replace validation at the save boundary: values may change through restoration, tests, or other code. A disabled button should have nearby explanatory text so the user is not left guessing.

## A scroll view has two geometries

UIScrollView's frameLayoutGuide describes its visible viewport. Its contentLayoutGuide describes its scrollable content. For a vertical form, constrain the form's edges to the content guide and its width to the frame guide. The complete top-to-bottom chain through arranged views determines content height; a width relationship prevents unintended horizontal scrolling.

A scroll view does not automatically know the height of arbitrary subviews. If you leave the bottom relationship missing, it cannot reliably infer the full content extent. If you pin every form edge only to the frame guide, content may be trapped at viewport height. Avoid hardcoding contentSize when Auto Layout already provides a consistent content-layout chain.

## First responder and keyboard avoidance

The first responder receives relevant input; calling becomeFirstResponder on a visible text input requests keyboard focus. resignFirstResponder ends editing for that control, while view.endEditing(true) asks the hierarchy to resign its current first responder. Decide what Return means: advance to the next field or finish the form. A Done button or suitable dismissal gesture is helpful when the keyboard has no Return key.

On modern iOS, UIKeyboardLayoutGuide lets constraints follow keyboard geometry. A vertical form can end its viewport at the guide's top. Test docked keyboards, hardware keyboards, and iPad configurations instead of assuming one fixed keyboard height. A scrolling viewport does not guarantee the active control is visible; for longer forms, scroll the active input into view as the keyboard and layout settle.

## Form state should be readable and testable

Keep field values in a small form state or convert them into a validated draft at submission time. Do not scatter business rules across six delegate methods. A pure validation function can be tested with blank text, Unicode, long input, and whitespace without launching UIKit. The controller then translates validation results into labels, button states, and focus changes.

Accessibility is part of form behavior. Give controls clear labels, do not rely only on red text, and test with Dynamic Type. A UITextView used inside a form often works best with internal scrolling disabled and an appropriate minimum height, allowing the outer form to scroll. For genuinely long documents, design its editing experience intentionally rather than stacking competing scroll gestures.

## Worked example: A keyboard-aware task editor

**File:** Day05TaskFormViewController.swift

```swift
import UIKit

@MainActor
final class TaskFormViewController: UIViewController, UITextFieldDelegate {
    private let titleField = UITextField()
    private let notesView = UITextView()
    private let helperLabel = UILabel()
    private let saveButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New task"
        view.backgroundColor = .systemBackground

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .interactive
        scroll.contentInsetAdjustmentBehavior = .never
        view.addSubview(scroll)

        let titleLabel = UILabel()
        titleLabel.text = "Task title"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true

        titleField.borderStyle = .roundedRect
        titleField.placeholder = "What needs to get done?"
        titleField.accessibilityLabel = "Task title"
        titleField.font = .preferredFont(forTextStyle: .body)
        titleField.adjustsFontForContentSizeCategory = true
        titleField.returnKeyType = .next
        titleField.delegate = self
        titleField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)

        let notesLabel = UILabel()
        notesLabel.text = "Notes (optional)"
        notesLabel.font = .preferredFont(forTextStyle: .headline)
        notesLabel.adjustsFontForContentSizeCategory = true

        notesView.font = .preferredFont(forTextStyle: .body)
        notesView.adjustsFontForContentSizeCategory = true
        notesView.accessibilityLabel = "Task notes"
        notesView.backgroundColor = .secondarySystemBackground
        notesView.layer.cornerRadius = 10
        notesView.isScrollEnabled = false

        helperLabel.font = .preferredFont(forTextStyle: .footnote)
        helperLabel.adjustsFontForContentSizeCategory = true
        helperLabel.numberOfLines = 0

        var config = UIButton.Configuration.filled()
        config.title = "Save task"
        saveButton.configuration = config
        saveButton.addAction(UIAction { [weak self] _ in self?.save() },
                             for: .touchUpInside)

        let form = UIStackView(arrangedSubviews: [
            titleLabel, titleField, notesLabel, notesView, helperLabel, saveButton
        ])
        form.axis = .vertical
        form.spacing = 12
        form.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(form)

        let content = scroll.contentLayoutGuide
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            form.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            form.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            form.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            form.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            form.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
            titleField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            notesView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            saveButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done", primaryAction: UIAction { [weak self] _ in
                self?.view.endEditing(true)
            }
        )
        titleChanged()
    }

    private var cleanTitle: String {
        (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @objc private func titleChanged() {
        let count = cleanTitle.count
        let valid = count > 0 && count <= 80
        saveButton.isEnabled = valid
        helperLabel.text = count == 0
            ? "Enter a title to enable Save."
            : "\(count)/80 characters"
        helperLabel.textColor = count > 80 ? .systemRed : .secondaryLabel
    }

    private func save() {
        guard !cleanTitle.isEmpty, cleanTitle.count <= 80 else {
            titleChanged()
            return
        }
        view.endEditing(true)
        helperLabel.text = "Draft validated: \(cleanTitle)"
        helperLabel.textColor = .label
        // Add repository persistence in Day 14; this example only validates a draft.
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        notesView.becomeFirstResponder()
        return true
    }
}
```

### Walkthrough and setup

1. Add this controller to the UIKit app and present it inside a navigation controller so its Done item is visible.
2. The outer scroll view's viewport ends at the keyboard layout guide. Its content remains independently sized by the stack's complete edge constraints.
3. The width equality prevents horizontal scrolling, while the stack's arranged content determines its height.
4. Title edits update validity and helper text. Save validates again and reports that the draft is valid; it does not claim to persist data.
5. Press Next in the title field to move to notes. Use Done or interactive scrolling to dismiss the keyboard, then repeat with large text and a short device.

**Expected behavior:** A scrollable title-and-notes form. Save is disabled for a blank or overlong title, Next moves to notes, and a valid Save reports a validated draft without pretending it has been stored.

## Challenge 1: Move focus on Return

**Level:** Warm-up

Given titleField and notesView properties in a UIViewController, implement the text-field delegate so Return advances from the title field to notes.

### Requirements

- Only special-case the intended title field.
- Assign the delegate during setup.
- Do not use a fixed delay before moving focus.

### Starter

```swift
func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    // Move focus
}
```

<details>
<summary>Hints</summary>

- Compare the incoming control by identity with ===.
- becomeFirstResponder returns whether the request succeeded.

</details>

### Acceptance checks

- Return in title requests focus for notes.
- No arbitrary timer or force unwrap is used.
- The delegate is assigned once during view setup.

<details>
<summary>Worked solution</summary>

```swift
// In viewDidLoad:
// titleField.delegate = self
// titleField.returnKeyType = .next
// The controller must conform to UITextFieldDelegate.

func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard textField === titleField else { return true }
    notesView.becomeFirstResponder()
    return true
}
```

The identity check prevents a future second text field from accidentally using the same behavior. Keyboard type alone does not implement navigation between inputs.

</details>

## Challenge 2: Extract form validation

**Level:** Core

Write a pure function that validates a task title and returns its cleaned value or a descriptive error. Use it both for button state and saving.

### Requirements

- Reject blank and over-80-character titles.
- Return a Result instead of throwing for this exercise.
- Keep the function free of UIKit.

### Starter

```swift
import Foundation
enum FormError: Error { case blankTitle, titleTooLong }
func validateTitle(_ raw: String) -> Result<String, FormError> {
    // Validate
}
```

<details>
<summary>Hints</summary>

- Result has success and failure cases.
- Do not trim internal spaces or alter the user's capitalization.

</details>

### Acceptance checks

- Whitespace-only input fails with blankTitle.
- 81 characters fail with titleTooLong.
- Input '  Read docs  ' succeeds as 'Read docs'.

<details>
<summary>Worked solution</summary>

```swift
import Foundation

enum FormError: Error { case blankTitle, titleTooLong }

func validateTitle(_ raw: String) -> Result<String, FormError> {
    let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !clean.isEmpty else { return .failure(.blankTitle) }
    guard clean.count <= 80 else { return .failure(.titleTooLong) }
    return .success(clean)
}
```

A UI can switch on the result to choose precise feedback. The same validation rule is now usable from a view model, a controller, and a unit test. Return a validated domain value instead of String when the architecture evolves.

</details>

## Challenge 3: Convert a segmented control into a domain value

**Level:** Stretch

Represent priority with a three-segment control and convert selection into an enum without a force unwrap. Handle the no-selection case explicitly.

### Requirements

- Keep the enum independent of UIKit.
- Use low, normal, and high cases.
- Choose normal as the deliberate fallback for no selection.

### Starter

```swift
enum FormPriority: Int { case low = 0, normal, high }
// Build UISegmentedControl and a conversion helper.
```

<details>
<summary>Hints</summary>

- selectedSegmentIndex may be UISegmentedControl.noSegment.
- A raw-value enum initializer is failable.

</details>

### Acceptance checks

- Indices 0, 1, and 2 map to low, normal, and high.
- No selection maps to the documented default.
- Changing displayed labels does not alter the enum cases.

<details>
<summary>Worked solution</summary>

```swift
import UIKit

enum FormPriority: Int { case low = 0, normal, high }

@MainActor
func makePriorityControl() -> UISegmentedControl {
    let control = UISegmentedControl(items: ["Low", "Normal", "High"])
    control.selectedSegmentIndex = FormPriority.normal.rawValue
    control.accessibilityLabel = "Task priority"
    return control
}

@MainActor
func selectedPriority(in control: UISegmentedControl) -> FormPriority {
    FormPriority(rawValue: control.selectedSegmentIndex) ?? .normal
}
```

The UI index is an implementation detail; the rest of the app receives a meaningful domain value. If priority is mandatory with no default in your product, return an optional or validation error instead of using this fallback.

</details>

## Knowledge check

### 1. Which event usually observes typed changes in UITextField?

A. touchUpInside.

B. editingChanged.

C. valueDidDecode.

D. viewWillAppear.

<details>
<summary>Answer and explanation</summary>

**B. editingChanged.**

editingChanged is the UIControl event for changes to the field's editing value.

</details>

### 2. For a vertical Auto Layout form, what usually prevents horizontal scrolling?

A. A fixed contentSize height.

B. A content width tied to the scroll view's frameLayoutGuide.

C. An unowned delegate.

D. Setting keyboardType to default.

<details>
<summary>Answer and explanation</summary>

**B. A content width tied to the scroll view's frameLayoutGuide.**

The width relationship keeps content aligned to the viewport while allowing its height to grow.

</details>

### 3. What is the first responder?

A. Always the app delegate.

B. The responder currently first in line to receive relevant input.

C. The view with the largest frame.

D. The first class in a Swift file.

<details>
<summary>Answer and explanation</summary>

**B. The responder currently first in line to receive relevant input.**

Text inputs become first responder to receive keyboard input.

</details>

### 4. Why validate again in Save when the button is disabled for invalid text?

A. The button performs network validation automatically.

B. Values can arrive through other code paths, so the save boundary must enforce invariants.

C. Every touchUpInside event is malicious.

D. It makes Auto Layout faster.

<details>
<summary>Answer and explanation</summary>

**B. Values can arrive through other code paths, so the save boundary must enforce invariants.**

Presentation state is not the domain's final validation boundary.

</details>

### 5. Does the example's Save action persist the task?

A. Yes, UILabel writes to disk.

B. Yes, UIAction automatically uses Core Data.

C. No; it validates a draft and explicitly leaves persistence for a later lesson.

D. Only when the keyboard is hidden.

<details>
<summary>Answer and explanation</summary>

**C. No; it validates a draft and explicitly leaves persistence for a later lesson.**

Feedback must describe what actually happened. Validation alone is not durable storage.

</details>

## Common pitfalls

- Pinning scroll content only to the viewport can prevent real scrolling.
- A missing bottom content constraint leaves content height underdetermined.
- Disabling Save without explaining why creates a confusing form.
- Fixed keyboard heights fail with hardware keyboards and other configurations.
- Nested scrolling text views can compete with the form's scroll gestures.

## PocketTasks milestone: Build the PocketTasks editor form

1. Add title, notes, and priority controls to the editor.
2. Use one title-validation rule for feedback and submission.
3. Make the form scroll and remain usable with the keyboard visible.
4. Return a validated draft to the caller later; do not show a persistence success before a repository has actually saved it.

## Before you move on

- Explain contentLayoutGuide versus frameLayoutGuide.
- Build and validate a form without force unwrapping text.
- Demonstrate Next and Done behavior with the software keyboard.
- Test blank, overlong, Unicode, and whitespace-padded titles.
- Explain exactly what the Save action does and does not store.

## Official references

- [Apple — UIScrollView](https://developer.apple.com/documentation/uikit/uiscrollview)
- [Apple — UIKeyboardLayoutGuide](https://developer.apple.com/documentation/uikit/uikeyboardlayoutguide)
- [Apple — UITextFieldDelegate](https://developer.apple.com/documentation/uikit/uitextfielddelegate)
- [Apple — UIControl](https://developer.apple.com/documentation/uikit/uicontrol)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
