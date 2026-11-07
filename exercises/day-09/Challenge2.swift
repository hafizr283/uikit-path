// Switch to a readable list for accessibility sizes
// Replace the layout provider with one that uses a self-sizing collection list whenever the preferred content size category is an accessibility category. Keep a two-column grid for normal categories.
// See lessons/day-09.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

let layout = UICollectionViewCompositionalLayout { _, environment in
    // Choose list or grid.
    return nil
}
