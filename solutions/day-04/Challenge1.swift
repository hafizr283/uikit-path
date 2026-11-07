// Worked solution: Center a fixed-size icon correctly
// The two center constraints determine position, and the two size constraints determine dimensions. Fixed sizes can be intentional for icons; they are often inappropriate for labels containing variable text.
// Read lessons/day-04.md for any surrounding types or setup.

import UIKit

@MainActor
func addCenteredIcon(to container: UIView) {
    let icon = UIImageView(image: UIImage(systemName: "checkmark.circle"))
    icon.contentMode = .scaleAspectFit
    icon.tintColor = .systemGreen
    icon.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(icon)
    NSLayoutConstraint.activate([
        icon.centerXAnchor.constraint(equalTo: container.safeAreaLayoutGuide.centerXAnchor),
        icon.centerYAnchor.constraint(equalTo: container.safeAreaLayoutGuide.centerYAnchor),
        icon.widthAnchor.constraint(equalToConstant: 80),
        icon.heightAnchor.constraint(equalToConstant: 80)
    ])
}
