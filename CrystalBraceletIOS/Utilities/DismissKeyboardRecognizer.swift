import SwiftUI

/// A view that lives on top of everything, listens for taps,
/// and calls `onOutsideTap` **only** when the tap is OUTSIDE `safeRect`.
/// `cancelsTouchesInView = false`  → gestures continue to the real UI.
struct DismissKeyboardRecognizer: UIViewRepresentable {
    var safeRect: CGRect          // usually the code editor’s frame
    var onOutsideTap: () -> Void  // what to do

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.cancelsTouchesInView = false        // <-- IMPORTANT
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.safeRect   = safeRect
        context.coordinator.onOutside  = onOutsideTap
    }

    func makeCoordinator() -> Coordinator { Coordinator(safeRect, onOutside: onOutsideTap) }

    final class Coordinator: NSObject {
        var safeRect: CGRect
        var onOutside: () -> Void

        init(_ rect: CGRect, onOutside: @escaping () -> Void) {
            self.safeRect = rect; self.onOutside = onOutside
        }

        @objc func handleTap(_ gr: UITapGestureRecognizer) {
            let pt = gr.location(in: gr.view?.window)
            if !safeRect.contains(pt) { onOutside() }
        }
    }
}

