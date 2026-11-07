// Day 09: Collection views and compositional layouts
// Independent educational example. Read lessons/day-09.md for setup.
// Add this file to an iOS UIKit app and present TaskBoardViewController in a navigation controller. It is independent of Day 8's example and uses a small local dictionary as its data source.
// The layout provider uses the collection container's effective width to switch between two and three columns. The sample uses a fixed card height to keep the initial geometry easy to inspect.
// The item fills the slot assigned by the horizontal repeating group. The group manages the requested number of columns and the spacing between them.
// Registration is created once and captured by the data-source provider. The registration itself captures the controller weakly.
// The sorted identifiers make initial ordering deterministic. A dictionary's iteration order should not be used as the user-facing task order.
// This fixed-height, three-line card is a layout demonstration. Use the adaptive list exercise or a self-sizing custom cell before displaying unrestricted user-entered text.

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
