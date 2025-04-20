import SwiftUI

extension ElementRatio {
    /// Helper to fetch a component by key
    func value(for key: String) -> Double {
        switch key {
        case "metal":  return metal
        case "wood":   return wood
        case "water":  return water
        case "fire":   return fire
        case "earth":  return earth
        default:       return 0
        }
    }
}

struct MicroHistogram: View {
    let current: ElementRatio
    let goal:    ElementRatio

    private var data: [(c: Double, g: Double, color: Color)] {
        [("metal", "#FFD700"),
         ("wood",  "#228B22"),
         ("water", "#1E90FF"),
         ("fire",  "#FF4500"),
         ("earth", "#DEB887")].map { key, hex in
            (current.value(for: key), goal.value(for: key), Color(hex: hex))
        }
    }

    var body: some View {
        HStack(spacing: 1) {
            ForEach(data.indices, id:\.self) { i in
                let item = data[i]
                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        Capsule().fill(item.color.opacity(0.25))
                            .frame(height: geo.size.height * item.g / 100)
                        Capsule().fill(item.color)
                            .frame(height: geo.size.height * item.c / 100)
                    }
                }
            }
        }
        .frame(height: 20)
    }
}
