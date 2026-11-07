// Fix stale hidden state
// A reusable subtitle view hides its label when text is empty, but never unhides it for the next item. Replace the configuration logic with a complete assignment.
// See lessons/day-07.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

func configure(subtitle: String) {
    subtitleLabel.text = subtitle
    if subtitle.isEmpty { subtitleLabel.isHidden = true }
}
