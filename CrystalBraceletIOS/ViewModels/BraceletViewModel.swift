import SwiftUI
import Combine

@MainActor
final class BraceletViewModel: ObservableObject {
    // MARK: - Published State
    @Published var beads: [Bead] = []              // palette beads
    @Published var bracelet: [Bead] = []           // user bracelet (≤ MAX_BEADS)
    @Published var numBeads: Int = 10 { didSet { regenerateBracelet() } }
    @Published var isAnimating = false
    @Published var growthAnimating = false
    @Published var speed: Double = 1.0             // 0.5…2.0

    // MARK: - Constants
    let MAX_BEADS = 20

    // MARK: - Dependencies
    private var cancellables = Set<AnyCancellable>()

    init() {
        regenerateBracelet()            // show placeholder beads immediately
        Task { await fetchPalette() }
    }

    // MARK: - Network
    func fetchPalette() async {
        do {
            let raw: [ServerBead] = try await APIService.shared.get("api/beads", decodeTo: [ServerBead].self)
            await MainActor.run {
                self.beads = raw.map { Bead(colorHex: $0.color) }
            }
        } catch {
            print("Palette fetch error: \(error)")
        }
    }

    // MARK: - Bracelet Generation & Editing --------------------------------------------------
    func regenerateBracelet(defaultColor: String = "#CCCCCC") {
        bracelet = Array(repeating: Bead(colorHex: defaultColor), count: numBeads)
    }

    func setColor(_ hex: String, at index: Int) {
        guard bracelet.indices.contains(index) else { return }
        bracelet[index].colorHex = hex
    }

    func swapBeads(at i: Int, and j: Int) {
        guard bracelet.indices.contains(i), bracelet.indices.contains(j) else { return }
        bracelet.swapAt(i, j)
    }

    // MARK: - Randomisation based on goal ratios ---------------------------------------------
    func randomise(for ratio: ElementRatio, colors: AnalysisResponse.ElementColors) {
        bracelet = generateBeadArray(n: numBeads, goal: ratio, colors: colors)
    }

    private func generateBeadArray(n: Int, goal: ElementRatio, colors: AnalysisResponse.ElementColors) -> [Bead] {
        let elems: [(Double, String)] = [
            (goal.metal, colors.metal), (goal.wood, colors.wood), (goal.water, colors.water),
            (goal.fire,  colors.fire),  (goal.earth, colors.earth)
        ]
        // 1. Calc float counts
        var counts: [(Int, String, Double)] = elems.map { (percentage, hex) in
            let f = percentage * Double(n) / 100.0
            return (Int(floor(f)), hex, f - floor(f))
        }
        // 2. Adjust diff
        var diff = n - counts.reduce(0) { $0 + $1.0 }
        counts.sort { $0.2 > $1.2 } // sort by remainder desc
        var idx = 0
        while diff > 0 {
            counts[idx].0 += 1; diff -= 1; idx = (idx + 1) % counts.count
        }
        // 3. Build beads
        var arr: [Bead] = []
        counts.forEach { (cnt, hex, _) in arr.append(contentsOf: Array(repeating: Bead(colorHex: hex), count: cnt)) }
        // 4. Shuffle
        arr.fisherYatesShuffle()
        // 5. Pad
        while arr.count < n { arr.append(Bead(colorHex: "#CCCCCC")) }
        return arr
    }

    // MARK: - Flash Randomise Animation -------------------------------------------------------
    func flashRandomise(goal: ElementRatio, colors: AnalysisResponse.ElementColors) {
        guard !isAnimating else { return }
        isAnimating = true
        let iterations = 25
        Task {
            for i in 0..<iterations {
                try await Task.sleep(for: .milliseconds(Int(200 / speed)))
                randomise(for: goal, colors: colors)
                if i == iterations - 1 { isAnimating = false }
            }
        }
    }

    // MARK: - Growth Animation ----------------------------------------------------------------
    func growBracelet(goal: ElementRatio, colors: AnalysisResponse.ElementColors) {
        guard !growthAnimating else { return }
        growthAnimating = true
        bracelet = []
        Task {
            for len in 1...MAX_BEADS {
                bracelet = generateBeadArray(n: len, goal: goal, colors: colors)
                try await Task.sleep(for: .milliseconds(Int(5000.0 / Double(MAX_BEADS - 1) / speed)))
            }
            growthAnimating = false
        }
    }
}
