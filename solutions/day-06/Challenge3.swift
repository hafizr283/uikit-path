// Worked solution: Implement correct child containment
// Controller ownership and view hierarchy must agree. Merely inserting child.view skips the relationship UIKit uses for appearance forwarding and other container behavior. Use standard containers unless a custom one is actually required.
// Read lessons/day-06.md for any surrounding types or setup.

import UIKit

@MainActor
func embed(_ child: UIViewController,
           in container: UIView,
           parent: UIViewController) {
    precondition(child.parent == nil, "Child already belongs to a parent")
    parent.addChild(child)
    child.view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(child.view)
    NSLayoutConstraint.activate([
        child.view.topAnchor.constraint(equalTo: container.topAnchor),
        child.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
        child.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        child.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
    ])
    child.didMove(toParent: parent)
}

@MainActor
func removeEmbedded(_ child: UIViewController) {
    child.willMove(toParent: nil)
    child.view.removeFromSuperview()
    child.removeFromParent()
}
