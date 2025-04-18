import Foundation

extension Array where Element: Hashable {
    mutating func fisherYatesShuffle() {
        guard count > 1 else { return }
        for i in indices.dropLast() {
            let j = Int.random(in: i..<count)
            if i != j { swapAt(i, j) }
        }
    }
}
