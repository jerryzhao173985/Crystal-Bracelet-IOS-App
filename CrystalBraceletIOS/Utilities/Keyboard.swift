import UIKit

extension UIApplication {
    /// Sends resignFirstResponder to the entire app.
    /// Works for *all* editors, even inside sheets & split-view.
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil, from: nil, for: nil)
    }
}
