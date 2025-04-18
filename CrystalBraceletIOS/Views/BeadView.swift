import SwiftUI

struct BeadView: View {
    var hex: String
    var body: some View {
        Circle()
            .fill(Color(hex: hex))
            .frame(width: 36, height: 36)
            .overlay(Circle().stroke(Color.black.opacity(0.5), lineWidth: 1.5))
            .shadow(radius: 2)
    }
}
