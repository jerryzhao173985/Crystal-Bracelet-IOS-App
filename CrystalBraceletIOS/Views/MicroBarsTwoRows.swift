import SwiftUI

private struct BarRow: View {
    let ratios: [Double]
    let colors: [Color]
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(ratios.indices, id:\.self) { i in
                    Rectangle()
                        .fill(colors[i])
                        .frame(width: geo.size.width * ratios[i] / 100)
                }
            }
        }
        .frame(height: 4)
        .clipShape(Capsule())
    }
}

struct MicroBarsTwoRows: View {
    let current: ElementRatio
    let goal:    ElementRatio
    private let order = ["metal","wood","water","fire","earth"]
    private let palette: [Color] = [
        Color(hex:"#FFD700"), Color(hex:"#228B22"),
        Color(hex:"#1E90FF"), Color(hex:"#FF4500"),
        Color(hex:"#DEB887")]

    func values(_ src: ElementRatio) -> [Double] {
        order.map { key in
            switch key {
            case "metal":  return src.metal
            case "wood":   return src.wood
            case "water":  return src.water
            case "fire":   return src.fire
            default:       return src.earth
            }
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            BarRow(ratios: values(goal),
                   colors: palette.map { $0.opacity(0.25) })
            BarRow(ratios: values(current),
                   colors: palette)
        }
        .frame(height: 10)
    }
}

