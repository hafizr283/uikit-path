// Worked solution: Fix stale hidden state
// The old code only handled the transition into an empty state. Direct assignment makes the result depend solely on the current input, so configuration order no longer changes the result.
// Read lessons/day-07.md for any surrounding types or setup.

// Inside a view type that owns subtitleLabel:
func configure(subtitle: String) {
    subtitleLabel.text = subtitle
    subtitleLabel.isHidden = subtitle.isEmpty
}
