import SwiftUI

struct BraceletCanvasView: View {
    @EnvironmentObject var braceletVM: BraceletViewModel
    @EnvironmentObject var analysisVM: AnalysisViewModel

    // Circle layout
    private let radius: CGFloat = 120

    // Palette state
    @State private var selectedIndex: Int? = nil          // bead tapped
    @State private var palettePos: CGPoint = .zero        // anchor in local coords
    @State private var showPalette: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // —— Bracelet beads ——
                ForEach(Array(braceletVM.bracelet.enumerated()), id: \.0) { idx, bead in
                    BeadView(hex: bead.colorHex)
                        .position(position(for: idx, total: braceletVM.bracelet.count, in: geo.size))
                        // Tap to open palette
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedIndex = idx
                                palettePos = position(for: idx, total: braceletVM.bracelet.count, in: geo.size)
                                palettePos.x += 40                     // horizontal offset so palette sits right side
                                palettePos.y -= 20                     // tweak vertically
                                showPalette = true
                            }
                        }
                        // Drag bead ↔ swap
                        .gesture(DragGesture()
                            .onChanged { value in dragState = value.translation }
                            .onEnded   { value in handleDragEnd(idx: idx, translation: value.translation, in: geo.size) })
                        // Drop from palette (hex string)
                        .onDrop(of: [.plainText], isTargeted: nil) { providers in
                            guard let provider = providers.first else { return false }
                            _ = provider.loadObject(ofClass: String.self) { str, _ in
                                if let hex = str as? String {
                                    DispatchQueue.main.async {
                                        braceletVM.setColor(hex, at: idx)
                                    }
                                }
                            }
                            return true
                        }
                }

                // —— Floating palette ——
                if showPalette, let idx = selectedIndex {
                    SidePaletteView(colors: paletteColors, onSelect: { hex in
                        braceletVM.setColor(hex, at: idx)
                        hidePalette()
                    })
                    .position(palettePos)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Tap anywhere to dismiss palette
            .contentShape(Rectangle())
            .onTapGesture {
                if showPalette { hidePalette() }
            }
        }
    }

    // MARK: - Helpers ------------------------------------------------------------
    private func position(for index: Int, total: Int, in size: CGSize) -> CGPoint {
        let angle = CGFloat(index) / CGFloat(max(total,1)) * 2 * .pi
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }

    private func hidePalette() {
        withAnimation(.easeInOut) {
            showPalette = false; selectedIndex = nil
        }
    }

    // Available palette colours
    private var paletteColors: [String] {
        if let c = analysisVM.ratios?.colors {
            return [c.metal, c.wood, c.water, c.fire, c.earth]
        }
        return ["#FFD700", "#228B22", "#1E90FF", "#FF4500", "#DEB887"]
    }

    // Simplified drag‑swap handling
    @State private var dragState: CGSize = .zero
    private func handleDragEnd(idx: Int, translation: CGSize, in size: CGSize) {
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
        if let j = nearestIdx, j != idx, minDist < 40 {
            braceletVM.swapBeads(at: idx, and: j)
        }
        dragState = .zero
    }
}

