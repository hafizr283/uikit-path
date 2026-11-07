// Worked solution: Present an iPad-safe share sheet
// Anchoring avoids the common iPad exception for an unconfigured popover. The caller should pass a currently visible view and avoid presenting while another conflicting presentation is active.
// Read lessons/day-19.md for any surrounding types or setup.

import UIKit
@MainActor
func share(text: String, from controller: UIViewController,
           sourceView: UIView) {
    let activity = UIActivityViewController(
        activityItems: [text],
        applicationActivities: nil
    )
    if let popover = activity.popoverPresentationController {
        popover.sourceView = sourceView
        popover.sourceRect = sourceView.bounds
    }
    controller.present(activity, animated: true)
}
