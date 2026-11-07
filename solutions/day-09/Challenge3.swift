// Worked solution: Show one task in two distinct placements
// The two placements are different presentation items even though they refer to one domain entity. Change the collection data source's item type to Placement when integrating this design. On selection, resolve the placement and use its taskID to find or mutate the task. Reconfigure both placements after a shared model change.
// Read lessons/day-09.md for any surrounding types or setup.

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
