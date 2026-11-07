// Worked solution: Move focus on Return
// The identity check prevents a future second text field from accidentally using the same behavior. Keyboard type alone does not implement navigation between inputs.
// Read lessons/day-05.md for any surrounding types or setup.

// In viewDidLoad:
// titleField.delegate = self
// titleField.returnKeyType = .next
// The controller must conform to UITextFieldDelegate.

func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard textField === titleField else { return true }
    notesView.becomeFirstResponder()
    return true
}
