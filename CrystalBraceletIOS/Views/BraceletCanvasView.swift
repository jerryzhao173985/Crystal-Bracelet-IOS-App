import SwiftUI

struct BraceletCanvasView: View {
    @EnvironmentObject var braceletVM: BraceletViewModel

    private let radius: CGFloat = 120

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(braceletVM.bracelet.enumerated()), id: \.0) { idx, bead in
                    BeadView(hex: bead.colorHex)
                        .position(position(for: idx, total: braceletVM.bracelet.count, in: geo.size))
                        .gesture(DragGesture()
                                    .onChanged { value in dragState = value.translation }
                                    .onEnded { value in handleDragEnd(idx: idx, translation: value.translation, in: geo.size) })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Helpers ------------------------------------------------------------
    private func position(for index: Int, total: Int, in size: CGSize) -> CGPoint {
        let angle = CGFloat(index) / CGFloat(total) * 2 * .pi
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }

    // Simplified drag handling: if dropped near another bead, swap
    @State private var dragState: CGSize = .zero
    private func handleDragEnd(idx: Int, translation: CGSize, in size: CGSize) {
        // Compute nearest bead index to drop location
        let startPos = position(for: idx, total: braceletVM.bracelet.count, in: size)
        let endPoint = CGPoint(x: startPos.x + translation.width, y: startPos.y + translation.height)
        var nearestIdx: Int? = nil
        var minDist: CGFloat = .infinity
        for j in braceletVM.bracelet.indices {
            let p = position(for: j, total: braceletVM.bracelet.count, in: size)
            let d = hypot(p.x - endPoint.x, p.y - endPoint.y)
            if d < minDist {
                minDist = d; nearestIdx = j
            }
        }
        if let j = nearestIdx, j != idx, minDist < 40 { braceletVM.swapBeads(at: idx, and: j) }
        dragState = .zero
    }
}

