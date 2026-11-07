// Convert a segmented control into a domain value
// Represent priority with a three-segment control and convert selection into an enum without a force unwrap. Handle the no-selection case explicitly.
// See lessons/day-05.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

enum FormPriority: Int { case low = 0, normal, high }
// Build UISegmentedControl and a conversion helper.
