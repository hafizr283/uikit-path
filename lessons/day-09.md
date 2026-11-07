# Day 09: Collection views and compositional layouts

Turn one task model into flexible lists, grids, and sectioned interfaces.

**Time:** 3–4 hours · **Target:** Swift 6 / iOS 17+

[Interactive lesson](http://hafizr283.me/uikit-path/#/day/9/lesson) · [Course overview](../README.md)

## Outcomes

- Describe the roles of collection-view layout, registration, and data source.
- Build adaptive sections using compositional layout.
- Configure reusable cells with cell registrations and stable identifiers.
- Update presentation without losing model identity or creating duplicate items.

## Before you begin

- Day 8: reusable cells and diffable snapshots.
- Day 4: layout priorities, safe areas, and adaptive sizing.

## 1. Choose the layout for the information

UICollectionView separates the arrangement of items from their content. The same data can become a vertical list, a two-column task board, or a screen of horizontally scrolling sections. Use a table when a straightforward vertical list meets the need; use a collection when section geometry or richer arrangements improve scanning. More layout flexibility also means more edge cases to test.

Flow layout is useful for simple wrapping grids with similar item sizes. Compositional layout describes items inside groups inside sections. A section provider can choose a layout from the section index and layout environment. A collection-view list configuration is another strong option for list-shaped interfaces that also need collection-view capabilities. Choose one intentionally rather than mixing unfamiliar layout mechanisms at random.

## 2. Think in items, groups, and sections

A layout item represents one cell's dimensions. A group arranges one or more items; its dimensions describe the repeated unit in a section. A section adds outer insets, spacing, supplementary elements, and optional orthogonal scrolling. Fractional dimensions are relative to the containing group or container, absolute dimensions are fixed points, and estimated dimensions permit the content to influence the final size.

For an adaptive board, inspect environment.container.effectiveContentSize.width. Choose a column count and construct a horizontal group that fills the available width. Avoid reading UIScreen.main.bounds: your collection may occupy a split view, a resizable window, or a smaller container. The effective collection-container width describes the space actually available to your layout.

## 3. Register once, configure repeatedly

Cell registrations bundle a cell type with its configuration handler. Create each registration once, typically during viewDidLoad, and reuse it in the data-source provider. Creating a registration inside the provider gives UIKit a fresh registration identity repeatedly and defeats the intended reuse arrangement. Configure all model-dependent properties in the handler just as you did for table cells.

A UICollectionViewCell can use UIListContentConfiguration for convenient labels and images, or a custom content view for a richer card. UIBackgroundConfiguration controls the background independently. Supplementary registrations provide headers and footers; the layout must request their element kind and the data source must supply a compatible view. A header is not an ordinary item in your task model.

## 4. Snapshot changes and cell changes are different

Use a diffable snapshot to describe ordered sections and the identifiers in each section. Identifiers must be unique across the whole snapshot, not just inside a section. If the same task appears in two different sections simultaneously, introduce a separate presentation identifier that includes the placement, while preserving the underlying task ID for business operations.

A changed task title, completion badge, or favorite flag usually needs reconfigureItems for the existing identifier. Moving a task from Today to Later changes its placement and needs a new or edited snapshot. Resolve selection through itemIdentifier(for:) rather than assuming that your model array still matches a captured index path after filtering or updates.

## 5. Adaptivity is a behavior to test

Test the collection in a narrow phone width, landscape, iPad split view, and large Dynamic Type sizes. A layout can be mathematically valid yet unusable if cards are too narrow to read. Prefer fewer columns and sufficient vertical growth over forcing dense content into a fixed-height tile. Decorative cards can have fixed heights; meaningful variable-length text often requires estimated sizing and complete constraints.

For images, show a placeholder immediately, cache prepared results, and ensure an old request cannot overwrite a reused cell. Prefetching can reduce waiting but does not replace identity checks or cancellation. When a section scrolls orthogonally, verify that horizontal gestures feel deliberate and that VoiceOver users can discover all its content. Performance and accessibility are part of a correct layout, not separate visual polish.

## Worked example: An adaptive PocketTasks board

**File:** TaskBoardViewController.swift

```swift
import UIKit

@MainActor
final class TaskBoardViewController: UIViewController {
    private enum Section: Hashable { case main }
    private let names = [
        UUID(): "Design the task card",
        UUID(): "Handle empty content",
        UUID(): "Test a narrow layout",
        UUID(): "Review cell reuse"
    ]
    private var source: UICollectionViewDiffableDataSource<Section, UUID>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Task board"
        view.backgroundColor = .systemBackground

        let layout = UICollectionViewCompositionalLayout { _, environment in
            let columns = environment.container.effectiveContentSize.width > 600 ? 3 : 2
            let item = NSCollectionLayoutItem(layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(1)
            ))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: .init(
                    widthDimension: .fractionalWidth(1),
                    heightDimension: .absolute(132)
                ),
                repeatingSubitem: item,
                count: columns
            )
            group.interItemSpacing = .fixed(12)
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 12
            section.contentInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
            return section
        }

        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.backgroundColor = .systemBackground
        view.addSubview(collection)
        NSLayoutConstraint.activate([
            collection.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collection.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collection.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collection.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let registration = UICollectionView.CellRegistration<UICollectionViewCell, UUID> {
            [weak self] cell, _, id in
            var content = UIListContentConfiguration.cell()
            content.text = self?.names[id]
            content.textProperties.numberOfLines = 3
            content.image = UIImage(systemName: "checklist")
            cell.contentConfiguration = content
            var background = UIBackgroundConfiguration.clear()
            background.backgroundColor = .secondarySystemBackground
            background.cornerRadius = 14
            cell.backgroundConfiguration = background
        }

        source = UICollectionViewDiffableDataSource(
            collectionView: collection
        ) { collection, indexPath, id in
            collection.dequeueConfiguredReusableCell(
                using: registration, for: indexPath, item: id
            )
        }
        var snapshot = NSDiffableDataSourceSnapshot<Section, UUID>()
        snapshot.appendSections([.main])
        let ids = names.keys.sorted { names[$0, default: ""] < names[$1, default: ""] }
        snapshot.appendItems(ids)
        source.apply(snapshot, animatingDifferences: false)
    }
}
```

### Walkthrough and setup

1. Add this file to an iOS UIKit app and present TaskBoardViewController in a navigation controller. It is independent of Day 8's example and uses a small local dictionary as its data source.
2. The layout provider uses the collection container's effective width to switch between two and three columns. The sample uses a fixed card height to keep the initial geometry easy to inspect.
3. The item fills the slot assigned by the horizontal repeating group. The group manages the requested number of columns and the spacing between them.
4. Registration is created once and captured by the data-source provider. The registration itself captures the controller weakly.
5. The sorted identifiers make initial ordering deterministic. A dictionary's iteration order should not be used as the user-facing task order.
6. This fixed-height, three-line card is a layout demonstration. Use the adaptive list exercise or a self-sizing custom cell before displaying unrestricted user-entered text.

**Expected behavior:** Four rounded task cards appear in two columns on a narrow container and three columns when the available width exceeds 600 points.

## Challenge 1: Find the registration-lifetime bug

**Level:** Warm-up

A cell provider constructs a new CellRegistration every time it needs a cell. Move registration creation outside the provider and explain which closure should capture the owner weakly.

### Requirements

- Create one registration for the cell type.
- Use the existing names dictionary and source property in TaskBoardViewController.
- Configure the title for each requested identifier.

### Starter

```swift
// Replace the provider setup in viewDidLoad.
// The registration must not be created inside the provider.
source = UICollectionViewDiffableDataSource(collectionView: collection) {
    collection, indexPath, id in
    return nil
}
```

<details>
<summary>Hints</summary>

- The provider can retain an already-created registration.
- The registration needs self only to read the model dictionary.

</details>

### Acceptance checks

- Scroll a larger dataset repeatedly without registration-related errors.
- Navigate away and use Memory Graph to confirm the controller can be released.

<details>
<summary>Worked solution</summary>

```swift
let registration = UICollectionView.CellRegistration<UICollectionViewCell, UUID> {
    [weak self] cell, _, id in
    var content = UIListContentConfiguration.cell()
    content.text = self?.names[id]
    cell.contentConfiguration = content
}
source = UICollectionViewDiffableDataSource(collectionView: collection) {
    collection, indexPath, id in
    collection.dequeueConfiguredReusableCell(
        using: registration, for: indexPath, item: id
    )
}
```

The data source retains its provider, which retains the registration. A strong capture of the controller inside that registration could complete an ownership cycle because the controller owns the data source. One weak capture breaks that cycle while maintaining one reusable registration identity.

</details>

## Challenge 2: Switch to a readable list for accessibility sizes

**Level:** Core

Replace the layout provider with one that uses a self-sizing collection list whenever the preferred content size category is an accessibility category. Keep a two-column grid for normal categories.

### Requirements

- Read the trait collection from the layout environment.
- Use UICollectionLayoutListConfiguration for the accessibility layout.
- Return a valid section in both branches.

### Starter

```swift
let layout = UICollectionViewCompositionalLayout { _, environment in
    // Choose list or grid.
    return nil
}
```

<details>
<summary>Hints</summary>

- UIContentSizeCategory has isAccessibilityCategory.
- NSCollectionLayoutSection.list(using:layoutEnvironment:) builds a list section.

</details>

### Acceptance checks

- At a normal text size, see two columns.
- At an accessibility text size, see a vertical list with readable wrapped titles.
- Rotate and change text size again without losing task identities.

<details>
<summary>Worked solution</summary>

```swift
let layout = UICollectionViewCompositionalLayout { _, environment in
    if environment.traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
        let config = UICollectionLayoutListConfiguration(appearance: .plain)
        return NSCollectionLayoutSection.list(
            using: config, layoutEnvironment: environment
        )
    }
    let item = NSCollectionLayoutItem(layoutSize: .init(
        widthDimension: .fractionalWidth(1),
        heightDimension: .fractionalHeight(1)
    ))
    let group = NSCollectionLayoutGroup.horizontal(
        layoutSize: .init(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(132)
        ),
        repeatingSubitem: item,
        count: 2
    )
    group.interItemSpacing = .fixed(12)
    let section = NSCollectionLayoutSection(group: group)
    section.interGroupSpacing = 12
    section.contentInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    return section
}
```

Adaptive design can change the structure, not merely shrink text. For this exercise also set content.textProperties.numberOfLines = 0 in the registration so list rows can show all the text. Built-in content configuration supports Dynamic Type; verify the entire screen instead of assuming one API guarantees accessibility.

</details>

## Challenge 3: Show one task in two distinct placements

**Level:** Stretch

Design identifiers for a task that appears in both Pinned and All sections. Build a snapshot without using the same item identifier twice.

### Requirements

- Preserve a shared underlying task UUID.
- Use a unique presentation identifier for each section placement.
- Explain how selection resolves back to the task.

### Starter

```swift
enum BoardSection: Hashable { case pinned, all }
struct Placement: Hashable {
    // Add identity components.
}
```

<details>
<summary>Hints</summary>

- Synthesized Hashable can combine section and task ID.
- Business operations use taskID; the collection diff uses the full placement.

</details>

### Acceptance checks

- The snapshot contains two distinct identifiers with the same taskID.
- Toggling the underlying task updates both visible placements.
- Removing the Pinned placement leaves the All placement intact.

<details>
<summary>Worked solution</summary>

```swift
enum BoardSection: Hashable { case pinned, all }

struct Placement: Hashable {
    let section: BoardSection
    let taskID: UUID
}

func makeSnapshot(taskID: UUID)
    -> NSDiffableDataSourceSnapshot<BoardSection, Placement> {
    var snapshot = NSDiffableDataSourceSnapshot<BoardSection, Placement>()
    snapshot.appendSections([.pinned, .all])
    snapshot.appendItems(
        [Placement(section: .pinned, taskID: taskID)], toSection: .pinned
    )
    snapshot.appendItems(
        [Placement(section: .all, taskID: taskID)], toSection: .all
    )
    return snapshot
}
```

The two placements are different presentation items even though they refer to one domain entity. Change the collection data source's item type to Placement when integrating this design. On selection, resolve the placement and use its taskID to find or mutate the task. Reconfigure both placements after a shared model change.

</details>

## Knowledge check

### 1. Which size describes the space available to a compositional layout most accurately?

A. UIScreen.main.bounds in every situation

B. The layout environment's effective container size

C. A hardcoded phone width

D. The app icon dimensions

<details>
<summary>Answer and explanation</summary>

**B. The layout environment's effective container size**

The collection may live inside a smaller or resizable container. The environment describes its actual available layout space.

</details>

### 2. When should you create a CellRegistration?

A. Every time the provider is called

B. Once for reuse, such as during setup

C. Only after a cell scrolls offscreen

D. Only inside prepareForReuse

<details>
<summary>Answer and explanation</summary>

**B. Once for reuse, such as during setup**

Registration carries reusable cell configuration and identity. Constructing it repeatedly inside the provider defeats that lifecycle.

</details>

### 3. Can the same diffable item identifier appear once in each of two sections?

A. Yes, sections isolate item identity

B. Yes, if the cells look different

C. No, item identifiers must be unique in the snapshot

D. Only when animations are disabled

<details>
<summary>Answer and explanation</summary>

**C. No, item identifiers must be unique in the snapshot**

Identifiers are globally unique within a snapshot. Use distinct presentation placements when one domain model appears more than once.

</details>

### 4. Which relationship is correct in compositional layout?

A. A cell contains a section that contains a group

B. Items form groups, and groups form a section's arrangement

C. A section must contain exactly one visible item

D. Every group must scroll horizontally

<details>
<summary>Answer and explanation</summary>

**B. Items form groups, and groups form a section's arrangement**

Items define cell slots, groups arrange slots, and sections repeat and decorate groups. Orthogonal scrolling is an optional section behavior.

</details>

### 5. Why might a layout change from a grid to a list at large text sizes?

A. To keep the same fixed height by clipping

B. Because collection views cannot show large text

C. To provide enough readable width and vertical space

D. To change model UUIDs

<details>
<summary>Answer and explanation</summary>

**C. To provide enough readable width and vertical space**

Accessibility may require structural adaptation. Preserving readable content is more valuable than forcing an unchanged column count.

</details>

## Common pitfalls

- Creating registrations inside the diffable provider.
- Using the same item identifier twice in one snapshot.
- Deriving layout width from the whole screen rather than the actual container.
- Giving variable-length text a rigid height with no accessible alternative.
- Forgetting to provide a supplementary view requested by the layout.

## PocketTasks milestone: PocketTasks milestone: an adaptive board

1. Add a board screen using the same stable task identifiers as the inbox.
2. Group tasks into meaningful sections such as Today and Later.
3. Make large-text layouts readable and document when you choose a list instead of a grid.
4. Keep task mutation in the model so both list and board reflect the same values.

## Before you move on

- Explain item, group, and section with your own board as the example.
- Demonstrate a layout change at a wider container size.
- Keep identity stable while updating a card title.
- Explain the ownership chain through data source, provider, and registration.
- Test a large accessibility text size and a narrow container.

## Official references

- [UICollectionView](https://developer.apple.com/documentation/uikit/uicollectionview)
- [UICollectionViewCompositionalLayout](https://developer.apple.com/documentation/uikit/uicollectionviewcompositionallayout)
- [UICollectionView.CellRegistration](https://developer.apple.com/documentation/uikit/uicollectionview/cellregistration)

## Reflection

- What can I now explain without the example?
- What did I build and test in Xcode?
- Which bug or design tradeoff do I want to revisit?
