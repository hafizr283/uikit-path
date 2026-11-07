// Worked solution: Switch to a readable list for accessibility sizes
// Adaptive design can change the structure, not merely shrink text. For this exercise also set content.textProperties.numberOfLines = 0 in the registration so list rows can show all the text. Built-in content configuration supports Dynamic Type; verify the entire screen instead of assuming one API guarantees accessibility.
// Read lessons/day-09.md for any surrounding types or setup.

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
