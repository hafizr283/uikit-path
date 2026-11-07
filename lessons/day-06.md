# Day 06: Navigation and communication between screens

Make push, presentation, saving, cancellation, and containment behave deliberately.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/6/lesson) · [Course overview](../README.md)

## Outcomes

- Choose navigation stacks, tabs, and modal presentations by user intent.
- Pass data forward and return changes through callbacks or delegates.
- Keep cancellation separate from saving an edited draft.
- Use the required view-controller containment sequence.

## Before you begin

- Days 2–5: ownership, lifecycle, layout, and form input.
- A UIKit app with a UINavigationController at the scene root.
- Understand that copying a value can represent an isolated editing draft.

## Use containers to express the app's structure

UINavigationController manages a stack: pushing moves deeper into a hierarchy and popping returns to the previous screen. The navigation bar reflects the top controller's title and items. UITabBarController switches between peer destinations such as Tasks and Settings; each tab can own its own navigation stack. Do not use a tab for a one-time action such as Save.

A modal presentation begins a focused flow, such as adding a task or selecting a filter. Dismissal returns to the presenting context. A screen presented modally is not automatically inside a navigation controller, so wrap it in one if it needs a navigation bar with Save and Cancel. Decide whether the user is moving deeper into content or temporarily entering a task, then choose the container that communicates that relationship.

## Pass required data at construction time

If a detail screen cannot function without an identifier or task value, require that input in its initializer for programmatic construction. This makes an invalid unconfigured screen harder to create. Storyboard-based screens often receive data before the segue finishes; document that configuration point and avoid force-unwrapped properties that fail much later during view loading.

Pass a model value or stable identifier, not a UILabel copied from the source screen. Views belong to a hierarchy; domain data belongs to the feature. A value draft is useful for editing: changing the draft does not immediately mutate the list's displayed source. On Save, return the validated result; on Cancel or Back, discard the draft. Preserve the task's stable identifier when editing rather than treating every save as a new entity.

## Return changes through an explicit contract

A closure works well for one or two simple results such as onSave(TaskItem). A delegate protocol works well for a named multi-event relationship that benefits from a documented contract. Notifications fit broad observations where the sender should not know every observer, but are usually harder to trace than a direct callback for one parent-child edit flow.

Pay attention to ownership. A parent may retain or present an editor, so a callback stored by the editor should normally capture the parent weakly. A child delegate pointing to the owning parent should be weak and class-bound. UI callbacks should execute on the main actor; do not let a background notification or service callback directly mutate UIKit. Make the result contract tell callers whether the value was merely edited, validated, or actually persisted.

## Presentation has its own lifecycle and cancellation rules

Modern sheet presentations can have detents and may be dismissed interactively. A Cancel button is only one path out of a modal. Decide whether an unsaved draft may be discarded by swiping, whether you need a dismissal delegate to ask about changes, or whether a critical flow should temporarily prevent interactive dismissal with isModalInPresentation. Do not block dismissal reflexively for every form.

Use the correct inverse operation: pop a pushed controller; dismiss a presented controller or its presentation container. Calling popViewController on a modal that has no navigation controller does nothing. Avoid triggering a new presentation repeatedly from appearance callbacks. Wait for the current transition to complete when coordinating multi-step navigation, and keep route decisions in one clear place as the app grows.

## Child controllers need full containment

Adding another controller's view as a subview does not establish proper controller containment. A custom container should call addChild, insert and constrain the child's view, then call child.didMove(toParent:). This informs UIKit about the relationship so lifecycle forwarding and other behavior can work correctly.

To remove a child, call willMove(toParent: nil), remove its view, and call removeFromParent. The latter completes the parent-removal relationship. Do not use custom containment when a standard navigation or tab controller already matches the design. Coordinators can later centralize navigation policy; they are a way to organize responsibilities, not a requirement for every two-screen app.

## Worked example: Edit a title, save it back, or cancel with Back

**File:** Day06Navigation.swift

```swift
import UIKit

@MainActor
final class TaskHomeViewController: UIViewController {
    private var taskTitle = "Practice navigation"
    private let titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PocketTasks"
        view.backgroundColor = .systemBackground
        titleLabel.text = taskTitle
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            titleLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Edit", primaryAction: UIAction { [weak self] _ in
                self?.showEditor()
            }
        )
    }

    private func showEditor() {
        let editor = TaskTitleEditorViewController(initialTitle: taskTitle)
        editor.onSave = { [weak self] newTitle in
            self?.taskTitle = newTitle
            self?.titleLabel.text = newTitle
        }
        navigationController?.pushViewController(editor, animated: true)
    }
}

@MainActor
final class TaskTitleEditorViewController: UIViewController {
    var onSave: (@MainActor (String) -> Void)?
    private let initialTitle: String
    private let field = UITextField()
    private let errorLabel = UILabel()

    init(initialTitle: String) {
        self.initialTitle = initialTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(initialTitle:) for this programmatic example")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit title"
        view.backgroundColor = .systemBackground
        field.text = initialTitle
        field.borderStyle = .roundedRect
        field.accessibilityLabel = "Task title"
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [field, errorLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", primaryAction: UIAction { [weak self] _ in
                self?.save()
            }
        )
    }

    private func save() {
        let clean = (field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean.count <= 80 else {
            errorLabel.text = "Enter a title between 1 and 80 characters."
            return
        }
        onSave?(clean)
        navigationController?.popViewController(animated: true)
    }
}
```

### Walkthrough and setup

1. Add both classes to the UIKit target and set the scene root to UINavigationController(rootViewController: TaskHomeViewController()). The initializer is programmatic; this editor is not designed for storyboard decoding.
2. Tap Edit. The current title is passed by value through the editor's initializer, so the original screen has valid data before editing begins.
3. Change the text and tap Back. Nothing calls onSave, so the original title remains unchanged.
4. Edit again and tap Save. Validation succeeds, the callback updates the parent, and the editor pops itself.
5. The callback captures the parent weakly. This example updates in-memory screen state only; saving to a repository and handling failure will be added later.

**Expected behavior:** A task title with an Edit button. Back discards edits; Save updates the original title and returns. Empty or overlong titles show inline feedback and do not leave the editor.

## Challenge 1: Create two peer tabs

**Level:** Warm-up

Write a function that creates a tab bar with Tasks and Settings destinations, each using its own navigation controller.

### Requirements

- Use separate controller instances.
- Give each tab a title and SF Symbol.
- Do not use a tab item as a Save action.

### Starter

```swift
@MainActor
func makeRootTabs() -> UITabBarController {
    // Build roots
}
```

<details>
<summary>Hints</summary>

- A navigation controller is itself a view controller.
- Configure each navigation controller's tabBarItem.

</details>

### Acceptance checks

- Each tab has its own navigation bar.
- Switching tabs does not create a new root each time.
- Editing in Tasks does not push a screen onto Settings.

<details>
<summary>Worked solution</summary>

```swift
import UIKit

@MainActor
func makeRootTabs() -> UITabBarController {
    let tasks = TaskHomeViewController()
    let settings = UIViewController()
    settings.title = "Settings"
    settings.view.backgroundColor = .systemBackground

    let taskNav = UINavigationController(rootViewController: tasks)
    taskNav.tabBarItem = UITabBarItem(
        title: "Tasks", image: UIImage(systemName: "checklist"), tag: 0
    )
    let settingsNav = UINavigationController(rootViewController: settings)
    settingsNav.tabBarItem = UITabBarItem(
        title: "Settings", image: UIImage(systemName: "gearshape"), tag: 1
    )
    let tabs = UITabBarController()
    tabs.viewControllers = [taskNav, settingsNav]
    return tabs
}
```

Each tab preserves its own stack while the user switches peer destinations. Use this function's return value as the scene window's root controller; do not wrap the entire tab controller in another unnecessary navigation stack.

</details>

## Challenge 2: Present a cancellable sheet

**Level:** Core

Create a simple help controller and present it as a sheet inside a navigation controller. Provide a Done button that dismisses the presented flow.

### Requirements

- Use dismiss rather than pop for the modal flow.
- Support medium and large detents.
- Avoid retaining the controller through its own stored action.

### Starter

```swift
@MainActor
func showHelp(from presenter: UIViewController) {
    // Present modal navigation flow
}
```

<details>
<summary>Hints</summary>

- Configure the sheet on the presented navigation controller.
- The controller's navigation bar can hold a Done UIAction.

</details>

### Acceptance checks

- The sheet displays a navigation bar and Done item.
- Done returns to the original presenter.
- Dragging to the large detent does not create another controller.

<details>
<summary>Worked solution</summary>

```swift
import UIKit

@MainActor
func showHelp(from presenter: UIViewController) {
    let help = UIViewController()
    help.title = "How PocketTasks works"
    help.view.backgroundColor = .systemBackground
    help.navigationItem.rightBarButtonItem = UIBarButtonItem(
        title: "Done", primaryAction: UIAction { [weak help] _ in
            help?.dismiss(animated: true)
        }
    )
    let navigation = UINavigationController(rootViewController: help)
    navigation.modalPresentationStyle = .pageSheet
    if let sheet = navigation.sheetPresentationController {
        sheet.detents = [.medium(), .large()]
        sheet.prefersGrabberVisible = true
    }
    presenter.present(navigation, animated: true)
}
```

The navigation controller is presented modally, so dismiss ends the flow. This help screen has no unsaved state, making interactive dismissal reasonable. Add content as an extension exercise; the solution focuses on presentation behavior.

</details>

## Challenge 3: Implement correct child containment

**Level:** Stretch

Write a helper that embeds a child controller inside a dedicated container view belonging to the parent, and a helper that removes it.

### Requirements

- Use addChild and didMove(toParent:).
- Constrain the child view to all container edges.
- Use the correct removal sequence.

### Starter

```swift
@MainActor
func embed(_ child: UIViewController, in container: UIView, parent: UIViewController) {
    // Containment
}
```

<details>
<summary>Hints</summary>

- The container must already be in the parent's view hierarchy.
- removeFromParent completes the parent-removal operation.

</details>

### Acceptance checks

- The child's parent property is the expected controller after embedding.
- The child fills the container when it resizes.
- After removal, the child has no parent and its view has no superview.

<details>
<summary>Worked solution</summary>

```swift
import UIKit

@MainActor
func embed(_ child: UIViewController,
           in container: UIView,
           parent: UIViewController) {
    precondition(child.parent == nil, "Child already belongs to a parent")
    parent.addChild(child)
    child.view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(child.view)
    NSLayoutConstraint.activate([
        child.view.topAnchor.constraint(equalTo: container.topAnchor),
        child.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        child.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        child.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
    ])
    child.didMove(toParent: parent)
}

@MainActor
func removeEmbedded(_ child: UIViewController) {
    child.willMove(toParent: nil)
    child.view.removeFromSuperview()
    child.removeFromParent()
}
```

Controller ownership and view hierarchy must agree. Merely inserting child.view skips the relationship UIKit uses for appearance forwarding and other container behavior. Use standard containers unless a custom one is actually required.

</details>

## Knowledge check

### 1. Which operation usually reverses a push?

A. dismiss.

B. popViewController.

C. removeFromSuperview alone.

D. Switching the root window.

<details>
<summary>Answer and explanation</summary>

**B. popViewController.**

A navigation controller owns the stack and pops the top pushed controller.

</details>

### 2. Why pass an editing draft as a value?

A. It automatically persists changes.

B. It separates tentative edits from committed source data.

C. It avoids all validation.

D. It prevents using delegates.

<details>
<summary>Answer and explanation</summary>

**B. It separates tentative edits from committed source data.**

The caller can commit on Save and discard on Cancel without leaking partial edits into the original data.

</details>

### 3. A child editor stores a callback that updates its parent. What capture is usually appropriate?

A. A strong capture with no ownership analysis.

B. A weak parent capture when the parent owns or presents the editor.

C. An unowned capture because callbacks never outlive screens.

D. A global variable.

<details>
<summary>Answer and explanation</summary>

**B. A weak parent capture when the parent owns or presents the editor.**

The weak backward reference avoids forming an ownership cycle and safely handles a vanished parent.

</details>

### 4. What does a modal editor need if it should show a navigation bar?

A. Nothing; every modal has one automatically.

B. A UINavigationController wrapper or another intentional container.

C. A second UIApplication.

D. A main storyboard.

<details>
<summary>Answer and explanation</summary>

**B. A UINavigationController wrapper or another intentional container.**

A plain UIViewController does not automatically receive a navigation bar when presented.

</details>

### 5. Which is the correct addition sequence for custom containment?

A. Add the view only.

B. didMove, then addChild, then remove the view.

C. addChild, add/constrain the child's view, then didMove(toParent:).

D. Set child.parent directly.

<details>
<summary>Answer and explanation</summary>

**C. addChild, add/constrain the child's view, then didMove(toParent:).**

This sequence establishes the controller relationship and its view hierarchy with the required lifecycle notification.

</details>

## Common pitfalls

- Using pop for a modal or dismiss for an ordinary pushed detail can produce confusing behavior.
- Passing UIKit views as data entangles screen hierarchies.
- A strong callback to an owning parent can retain the whole flow.
- Interactive sheet dismissal is a cancellation path that needs an explicit unsaved-draft policy.
- Adding a child controller's view without containment skips essential UIKit relationships.

## PocketTasks milestone: Connect list, editor, and settings

1. Create a task-list root and push a task editor with required input.
2. Return a validated draft through a weakly captured callback.
3. Keep Back and Cancel from mutating source data.
4. Add Settings as a peer tab only if it is a genuine destination, and document modal dismissal behavior.

## Before you move on

- Explain why a feature uses push, tab, or modal presentation.
- Demonstrate Save versus Back cancellation without accidental mutation.
- Show the ownership graph of a parent, editor, and callback.
- Embed and remove a child using the full sequence.
- State whether a returned edit is merely validated or durably saved.

## Official references

- [Apple — UINavigationController](https://developer.apple.com/documentation/uikit/uinavigationcontroller)
- [Apple — UITabBarController](https://developer.apple.com/documentation/uikit/uitabbarcontroller)
- [Apple — UISheetPresentationController](https://developer.apple.com/documentation/uikit/uisheetpresentationcontroller)
- [Apple — Implementing a container view controller](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
