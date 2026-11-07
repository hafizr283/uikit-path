# UIKit Path

A practical 20-day field guide for a developer who knows basic Swift and wants to build, debug, and maintain UIKit apps.

**Course:** [hafizr283.me/uikit-path](http://hafizr283.me/uikit-path/) · **Start:** [Day 01](lessons/day-01.md) · **Native app:** [PocketTasks Xcode starter](native/PocketTasks/)

## What you get

- 20 daily tutorials with 100 teaching sections and 20 worked examples.
- 60 coding challenges, each with a starter, hints, solution, explanation, and acceptance checks.
- 100 quiz questions with explained answers and repeatable attempts.
- An ongoing PocketTasks capstone that connects daily concepts to one app.
- A browser workspace with saved notes, Swift drafts, progress, search, and JSON backup/import.
- An illustrated UIKit property lab with editable Swift source and a phone preview.
- A real programmatic UIKit Xcode project and automated checks.
- Local Markdown chapters and individual source files for IDE-based study.

The browser lab interprets a **small, documented set of literal properties** to illustrate a fixed layout with HTML. It does not compile Swift, execute UIKit, solve constraints, or grade exercise code. Run and debug the native code in **Xcode on a Mac**. The Swift sample in the UI lab intentionally has no button action.

## Start on your Mac

1. Install Xcode 16 or newer with an iOS Simulator runtime.
2. Clone this repository:

   ```sh
   git clone https://github.com/hafizr283/uikit-path.git
   cd uikit-path
   open native/PocketTasks/PocketTasks.xcodeproj
   ```

3. Choose the **PocketTasks** scheme, choose an iPhone simulator, and press **⌘R**.
4. Read the [native README](native/PocketTasks/README.md) for the starter's features, tests, signing, and extension points.
5. Start [Day 01](lessons/day-01.md), then implement that day's capstone milestone in your own branch.

The course targets **Swift 6 and iOS 17+**, using UIKit exclusively. Simulator builds do not require a paid Apple developer account. A physical device needs your signing team; App Store distribution and some services require appropriate Apple membership and configuration.

Examples and exercise solutions are **independent educational units**, not one combined application. Some explicitly build on types from a previous day or require an Xcode data model. Read the walkthrough before adding files to a target. Do not add all `examples/` or `solutions/` files to one target: repeated type names are intentional.

## Daily rhythm

Plan for about 3–4 focused hours: 45–60 minutes reading and tracing, 60–90 minutes coding, 30–45 minutes extending PocketTasks, and 15–30 minutes for the quiz and notes. Repeat a day when the core idea has not clicked. Twenty days builds a strong foundation; production fluency comes from continued development and review.

| Day | Focus |
| --- | --- |
| [01](lessons/day-01.md) | Swift application fundamentals |
| [02](lessons/day-02.md) | ARC and ownership |
| [03](lessons/day-03.md) | UIKit, scenes, and view-controller lifecycle |
| [04](lessons/day-04.md) | Auto Layout |
| [05](lessons/day-05.md) | Controls, forms, scrolling, and keyboard |
| [06](lessons/day-06.md) | Navigation and screen communication |
| [07](lessons/day-07.md) | Reusable UI, gestures, and animations |
| [08](lessons/day-08.md) | Table views |
| [09](lessons/day-09.md) | Collection views |
| [10](lessons/day-10.md) | Concurrency and cancellation |
| [11](lessons/day-11.md) | Networking and API contracts |
| [12](lessons/day-12.md) | Reliable API-powered screens |
| [13](lessons/day-13.md) | MVC, MVVM, dependency injection, and coordinators |
| [14](lessons/day-14.md) | Persistence and offline data |
| [15](lessons/day-15.md) | Authentication and session management |
| [16](lessons/day-16.md) | Unit, async, and UI testing |
| [17](lessons/day-17.md) | Debugging, memory, and performance |
| [18](lessons/day-18.md) | Accessibility and localization |
| [19](lessons/day-19.md) | Platform integration |
| [20](lessons/day-20.md) | Professional delivery and distribution |

## Run the course locally

Install Node.js 20 or newer. No npm packages or installation step are needed.

```sh
npm run dev
# Open http://127.0.0.1:4173
```

Open `uikit-path.code-workspace` in VS Code for tasks to preview, validate, regenerate the course, and open the native project on macOS. VS Code is useful for the course source and Markdown; Xcode provides UIKit compilation and the iOS Simulator.

```sh
npm test          # Content contracts, progress handling, scoring, routing, safe rendering, UI lab
npm run validate # Content-only validation
npm run build    # Regenerate Markdown/source extracts and static dist/
```

`content/day-XX.json` is the source of truth. The build generates `lessons/`, `examples/`, `exercises/`, and `solutions/`; edit the JSON, then rebuild instead of changing generated files directly.

## Progress and privacy

Notes, practice drafts, quiz attempts, and completed days stay in local storage in the current browser and origin. No account, analytics, backend, or external code-execution service is used. Export progress in **Setup** or a day's **Notes** tab before changing devices, clearing browser data, or moving between HTTP and HTTPS. Import downloads a backup of the current state, then merges completed work and uses imported notes/drafts when present.

## Hosting and validation

GitHub Actions builds the dependency-free static site and publishes the `dist/` artifact to this repository's GitHub Pages project path. It inherits the existing `hafizr283.me` user-site domain. No custom-domain file is needed in this project, and the existing website remains independent.

Validation evidence and current limitations are recorded in [VALIDATION.md](VALIDATION.md). The native app and worked examples have separate macOS workflows. CI typechecking confirms language/API compatibility for its documented scope; it does not replace running the examples, testing accessibility on a device, or validating a real backend.

The Xcode starter is a working capstone foundation. The daily milestones ask you to extend it; it does not include finished production authentication, a hosted API, or push-notification services.
