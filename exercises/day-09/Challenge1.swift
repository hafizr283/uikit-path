// Find the registration-lifetime bug
// A cell provider constructs a new CellRegistration every time it needs a cell. Move registration creation outside the provider and explain which closure should capture the owner weakly.
// See lessons/day-09.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

// Replace the provider setup in viewDidLoad.
// The registration must not be created inside the provider.
source = UICollectionViewDiffableDataSource(collectionView: collection) {
    collection, indexPath, id in
    return nil
}
