import SwiftUI

struct SidePaletteView: View {
    var colors: [String]                   // HEX strings
    var onSelect: (String) -> Void         // called on tap

    var body: some View {
        VStack(spacing: 10) {
            ForEach(colors, id: \..self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    // Tap to choose colour
                    .onTapGesture { onSelect(hex) }
                    // Drag token carrying HEX text
                    .onDrag { NSItemProvider(object: hex as NSString) }
            }
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(radius: 5)
    }
}
