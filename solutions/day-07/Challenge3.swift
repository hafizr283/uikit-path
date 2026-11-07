// Worked solution: Animate feedback while respecting Reduce Motion
// Opacity changes presentation, while the caller's state remains authoritative. Keeping the label in layout avoids a simultaneous jump in surrounding geometry. The accessibility setting prevents visually hidden feedback from remaining in the accessibility sequence. For a layout-collapsing message, design a separate stack/constraint transition.
// Read lessons/day-07.md for any surrounding types or setup.

import UIKit

@MainActor
func setFeedbackVisible(_ visible: Bool, label: UILabel) {
    let targetAlpha: CGFloat = visible ? 1 : 0
    label.isHidden = false
    label.accessibilityElementsHidden = !visible
    if UIAccessibility.isReduceMotionEnabled {
        label.layer.removeAllAnimations()
        label.alpha = targetAlpha
        return
    }
    UIView.animate(
        withDuration: 0.2,
        delay: 0,
        options: [.beginFromCurrentState, .allowUserInteraction]
    ) {
        label.alpha = targetAlpha
    }
}
