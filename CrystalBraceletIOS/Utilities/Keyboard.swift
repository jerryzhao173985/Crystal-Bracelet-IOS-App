// Utilities/Keyboard.swift
import SwiftUI

extension UIApplication {
    /// Resigns first-responder everywhere (works across all UIKit widgets)
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil, from: nil, for: nil)
    }
}
