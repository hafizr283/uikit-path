// Worked solution: Find the registration-lifetime bug
// The data source retains its provider, which retains the registration. A strong capture of the controller inside that registration could complete an ownership cycle because the controller owns the data source. One weak capture breaks that cycle while maintaining one reusable registration identity.
// Read lessons/day-09.md for any surrounding types or setup.

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
