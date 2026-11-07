// Worked solution: Preserve the result when Reduce Motion is enabled
// The setting changes the transition rather than the outcome. A production component that can receive overlapping reveal/hide commands should also manage or cancel the previous animation, then apply the requested final state.
// Read lessons/day-18.md for any surrounding types or setup.

import UIKit
@MainActor
func reveal(_ banner: UIView) {
    banner.isHidden = false
    let finish = {
        banner.alpha = 1
        banner.transform = .identity
    }

    if UIAccessibility.isReduceMotionEnabled {
        finish()
    } else {
        banner.alpha = 0
        banner.transform = CGAffineTransform(
            translationX: 0, y: -12
        )
        UIView.animate(withDuration: 0.2, animations: finish)
    }
}
