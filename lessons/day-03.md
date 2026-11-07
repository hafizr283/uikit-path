# Day 03: UIKit, scenes, and view-controller lifecycles

Know how an iOS app reaches the screen and where each responsibility belongs.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/3/lesson) · [Course overview](../README.md)

## Outcomes

- Trace an app from application launch to a scene, window, and root controller.
- Distinguish one-time view setup from repeated appearance and layout callbacks.
- Understand view hierarchy, responder chain, and main-actor UI access.
- Work with Storyboards, XIBs, and programmatic UIKit without mixing entry points accidentally.

## Before you begin

- Days 1–2: classes, closures, and ownership.
- A Mac with Xcode and an iOS app target using UIKit; the web preview cannot execute the native lifecycle.

## Application, scene, window, controller, view

UIApplication represents the running app process. AppDelegate handles application-level coordination. A UIScene represents one instance of the app's UI; a UIWindowScene connects windows to that scene. A UIWindow hosts a root view controller, which manages a view hierarchy. Keep these levels separate: the process can outlive a particular UI scene, and apps can support multiple scenes.

With the scene lifecycle, scene-specific UI work belongs in SceneDelegate rather than treating AppDelegate as the owner of one universal window. A root UINavigationController is a common entry point for an app with a list and detail screens. Retain the UIWindow in a property: a local variable alone does not express the scene delegate's ownership. The scene connection receives a general UIScene, so verify that it is a UIWindowScene before constructing the window.

## View loading is not the same as visibility

A view controller can exist before its view is loaded. Accessing view or calling loadViewIfNeeded() triggers loading when necessary. loadView creates the root view; override it when you intentionally supply a custom root view, and assign self.view. viewDidLoad follows loading and is the usual home for one-time control creation, constraint installation, and event wiring for that view instance.

viewWillAppear and viewDidAppear relate to appearance and may run repeatedly as navigation, tabs, or presentations change. viewWillDisappear and viewDidDisappear relate to leaving the visible hierarchy; disappearance does not necessarily mean permanent destruction. Call super in lifecycle overrides. Do not start the same observer or install the same constraints on every appearance without a corresponding lifecycle design. Use deinit for ownership diagnosis, not as a substitute for all visibility handling.

## Layout can repeat many times

Auto Layout and UIKit can perform layout when the window changes size, text changes, traits change, or constraints are invalidated. viewDidLayoutSubviews therefore may run many times. It is appropriate for geometry-dependent adjustments that cannot be expressed directly with constraints, but it should not repeatedly fetch data, recreate the whole interface, or append subviews.

Before layout, a view's bounds may not match its final display size. Do not save a frame from viewDidLoad and assume it stays valid after rotation or split-screen resizing. In this first example, a label uses an autoresizing mask to fill its container; tomorrow you will replace fixed geometry assumptions with constraints. Learning when sizes are valid makes Auto Layout failures much easier to understand.

## Events travel through responders, UI stays on the main actor

Views, view controllers, and the application participate in a responder chain. A text field can become first responder to receive keyboard input, and an action can be routed to an appropriate responder instead of requiring every sender to know every receiver. View hierarchy describes visual containment; responder chain describes an event-routing relationship. They are related but not identical diagrams.

UIKit view work belongs on the main actor. An @MainActor controller makes that isolation explicit in Swift code. Concurrency does not mean moving a view controller to a background thread: background or asynchronous work should produce data, then the UI applies that data on its required actor. Day 10 covers task isolation in depth. For now, recognize that lifecycle methods and control actions are places for fast UI coordination, not blocking network calls or heavy computation.

## Storyboards, XIBs, and code are construction choices

A storyboard describes screens and transitions in Interface Builder. A XIB usually describes a reusable view or controller's view without an entire navigation graph. Programmatic UIKit constructs and configures objects in Swift. All three use the same UIKit objects and lifecycle; Storyboards are not SwiftUI. Learn to inspect outlets, actions, custom classes, module settings, and reuse identifiers because existing company codebases often use them.

Do not accidentally create two launch paths. If a scene configuration names a storyboard, the system can create its initial window and controller; if your SceneDelegate then creates another root hierarchy, setup becomes confusing. For a fully programmatic app, remove the main storyboard name from both app-level settings and scene configuration, while keeping the launch screen configuration. Never delete a launch screen simply because you no longer use a main storyboard.

## Worked example: A programmatic root screen with lifecycle logging

**File:** Day03Lifecycle.swift

```swift
import UIKit

@MainActor
final class LifecycleViewController: UIViewController {
    private let messageLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        title = "PocketTasks"
        view.backgroundColor = .systemBackground

        messageLabel.text = "Your first UIKit screen"
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.font = .preferredFont(forTextStyle: .title2)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.frame = view.bounds
        messageLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(messageLabel)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("viewDidLayoutSubviews")
    }
}

// Replace the generated SceneDelegate; do not keep two classes with this name.
@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(
            rootViewController: LifecycleViewController()
        )
        self.window = window
        window.makeKeyAndVisible()
    }
}
```

### Walkthrough and setup

1. Use a UIKit iOS app target with the scene lifecycle and its existing AppDelegate. Replace the generated SceneDelegate with the one above, then add LifecycleViewController to the same target.
2. In the target's Info settings, preserve Application Scene Manifest and the scene delegate class entry. Remove a Storyboard Name from the application scene configuration if present, and remove the app's main storyboard setting if present. Keep the launch screen settings.
3. The scene delegate creates a window for the connected UIWindowScene, gives it a navigation controller, retains it, and makes it visible.
4. viewDidLoad creates the label once for that loaded view. The autoresizing mask stretches it with the container; no fixed device width is encoded.
5. Run on an iOS simulator, rotate it, and inspect Xcode's console. Layout logging may repeat; appearance logging is not a promise of one immutable sequence under all transitions.

**Expected behavior:** A navigation bar titled PocketTasks and a centered label. The console shows viewDidLoad, appearance callbacks, and one or more layout callbacks. Exact layout-callback counts are intentionally not fixed.

## Challenge 1: Separate setup from repeated refresh

**Level:** Warm-up

Build a controller that creates its label once but updates an appearance count every time the screen is about to appear.

### Requirements

- Create and add the label in viewDidLoad.
- Increment the count in viewWillAppear.
- Call super and avoid adding duplicate labels.

### Starter

```swift
import UIKit
@MainActor
final class VisitViewController: UIViewController {
    private let label = UILabel()
    private var visits = 0
    // Lifecycle overrides
}
```

<details>
<summary>Hints</summary>

- A controller instance can appear more than once.
- An autoresizing label is sufficient for this lifecycle exercise.

</details>

### Acceptance checks

- Only one label exists after repeated appearances.
- The count increases when the same instance reappears.
- Rotating alone does not intentionally increment the appearance counter.

<details>
<summary>Worked solution</summary>

```swift
import UIKit

@MainActor
final class VisitViewController: UIViewController {
    private let label = UILabel()
    private var visits = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        label.frame = view.bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.textAlignment = .center
        view.addSubview(label)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visits += 1
        label.text = "Appearance \(visits)"
    }
}
```

This counts appearances of this controller instance, not app launches. Returning from a pushed detail screen increments it without constructing another label. Use it as a root controller and navigate away and back once you implement navigation on Day 6.

</details>

## Challenge 2: Own a custom root view

**Level:** Core

Use loadView to give a controller a custom root view. Keep view construction in the view type and controller-level configuration in viewDidLoad.

### Requirements

- Assign the root view in loadView.
- Do not access self.view before assigning it inside loadView.
- Avoid force casting the root view.

### Starter

```swift
import UIKit
@MainActor final class WelcomeView: UIView { /* Build label */ }
@MainActor final class WelcomeViewController: UIViewController {
    // Store a WelcomeView and use it as the root
}
```

<details>
<summary>Hints</summary>

- A stored contentView gives a typed reference.
- Implement required init?(coder:) when creating a UIView subclass with a custom initializer.

</details>

### Acceptance checks

- The root view is the stored WelcomeView.
- The example runs when used as a programmatic root controller.
- No recursive self.view access occurs during loadView.

<details>
<summary>Worked solution</summary>

```swift
import UIKit

@MainActor
final class WelcomeView: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        label.text = "Welcome to PocketTasks"
        label.textAlignment = .center
        label.frame = bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("This example supports programmatic construction only")
    }
}

@MainActor
final class WelcomeViewController: UIViewController {
    private let contentView = WelcomeView(frame: .zero)

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Welcome"
    }
}
```

The controller has a typed reference without an unsafe cast, and the view can be reused or previewed independently. The coder initializer intentionally rejects storyboard/XIB construction; do not connect this particular class in Interface Builder.

</details>

## Challenge 3: Diagnose a duplicate interface

**Level:** Stretch

A controller adds a new banner every time viewDidLayoutSubviews runs. Refactor it so layout changes do not create more banners.

### Requirements

- Create and attach the banner once.
- Update only geometry during layout.
- Keep layout work idempotent: repeating it must not change the number of subviews.

### Starter

```swift
override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let banner = UILabel()
    banner.text = "Tasks"
    view.addSubview(banner)
    banner.frame = CGRect(x: 20, y: 100, width: 240, height: 44)
}
```

<details>
<summary>Hints</summary>

- Move the banner to a stored property.
- Use the safe-area layout frame when calculating geometry.

</details>

### Acceptance checks

- Rotating does not increase the view's banner count.
- The banner uses the current safe area.
- There are no network requests or event registrations inside layout.

<details>
<summary>Worked solution</summary>

```swift
import UIKit

@MainActor
final class BannerViewController: UIViewController {
    private let banner = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        banner.text = "Tasks"
        view.addSubview(banner)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safe = view.safeAreaLayoutGuide.layoutFrame
        banner.frame = CGRect(
            x: safe.minX + 20, y: safe.minY + 16,
            width: max(0, safe.width - 40), height: 44
        )
    }
}
```

The exercise uses manual layout to isolate the lifecycle issue. Tomorrow's constraints express the same relationships more declaratively. Calling this layout method repeatedly changes the frame but does not allocate another label.

</details>

## Knowledge check

### 1. In a scene-based UIKit app, what connects a window to a particular UI scene?

A. A global UserDefaults instance.

B. UIWindowScene.

C. A SwiftUI View.

D. An outlet collection.

<details>
<summary>Answer and explanation</summary>

**B. UIWindowScene.**

Constructing UIWindow(windowScene:) associates the window with its UIWindowScene.

</details>

### 2. Where should a controller usually install its one-time constraints?

A. Every viewDidLayoutSubviews call.

B. Every viewWillAppear call.

C. viewDidLoad, once for the loaded view.

D. Only in AppDelegate.

<details>
<summary>Answer and explanation</summary>

**C. viewDidLoad, once for the loaded view.**

One-time view setup belongs in viewDidLoad. Repeated installation can duplicate constraints.

</details>

### 3. What does viewDidDisappear guarantee?

A. The controller was destroyed.

B. The app was terminated.

C. The view left its visible appearance state, but the controller may remain alive.

D. All network requests were cancelled.

<details>
<summary>Answer and explanation</summary>

**C. The view left its visible appearance state, but the controller may remain alive.**

Visibility and object lifetime are distinct. A controller in a navigation stack can disappear and later return.

</details>

### 4. When overriding loadView to construct a custom root, what is essential?

A. Assign self.view to the constructed root view.

B. Read self.view recursively before construction.

C. Call a network service synchronously.

D. Install another app entry point.

<details>
<summary>Answer and explanation</summary>

**A. Assign self.view to the constructed root view.**

loadView is responsible for supplying the root view; accessing the getter before assigning it can recurse.

</details>

### 5. Does removing the main storyboard mean the launch screen should be removed?

A. Yes, both are the same interface.

B. No; launch-screen configuration has a separate purpose.

C. Only when using navigation controllers.

D. Only in Swift 6.

<details>
<summary>Answer and explanation</summary>

**B. No; launch-screen configuration has a separate purpose.**

The launch screen and the app's initial interactive UI are separate concerns.

</details>

## Common pitfalls

- Leaving a storyboard launch path active while also building a second root window can duplicate setup.
- Placing repeated observers or subview creation in appearance/layout callbacks can accumulate work.
- Assuming viewDidDisappear means deinit leads to incorrect cleanup decisions.
- Accessing view during a custom loadView before assigning it can recurse.
- The simulator's lifecycle logs are observations, not a universal exact ordering contract.

## PocketTasks milestone: Launch PocketTasks through UIKit

1. Create a UIKit app target and choose one intentional UI construction approach.
2. Use a navigation controller with a placeholder TaskListViewController as the scene root.
3. Keep lifecycle logging temporarily to observe navigation and rotation.
4. Document the app's minimum iOS version and which setup belongs in AppDelegate versus SceneDelegate.

## Before you move on

- Draw UIApplication → scene → window → root controller → views.
- Explain when a controller can exist without a loaded view.
- Place setup, visibility refresh, and geometry work in appropriate callbacks.
- Describe how an outlet connection differs from programmatic construction.
- Run the example and explain why layout logs repeat.

## Official references

- [Apple — Managing your app's life cycle](https://developer.apple.com/documentation/uikit/managing-your-app-s-life-cycle)
- [Apple — UIViewController](https://developer.apple.com/documentation/uikit/uiviewcontroller)
- [Apple — UIWindowSceneDelegate](https://developer.apple.com/documentation/uikit/uiwindowscenedelegate)
- [Apple — UIResponder](https://developer.apple.com/documentation/uikit/uiresponder)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
