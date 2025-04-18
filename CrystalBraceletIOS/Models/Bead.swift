import SwiftUI

struct Bead: Identifiable, Hashable {
    /// Client‑side unique ID – guarantees ForEach stability even if server gives duplicates
    let id = UUID()
    var colorHex: String   // #RRGGBB
    var color: Color { Color(hex: colorHex) }
}

/// Raw object exactly as returned by `/api/beads` (id: Int, color: String)
struct ServerBead: Decodable {
    let id: Int
    let color: String
}

// 2.2 ElementRatio.swift
struct ElementRatio: Codable, Hashable {
    var metal:  Double
    var wood:   Double
    var water:  Double
    var fire:   Double
    var earth:  Double

    static let zero = ElementRatio(metal: 0, wood: 0, water: 0, fire: 0, earth: 0)
}

// 2.3 AnalysisResponse.swift
struct AnalysisResponse: Codable {
    var analysis: String
    var ratios: RatioContainer

    struct RatioContainer: Codable, Equatable {
        var current: ElementRatio
        var goal:    ElementRatio
        var colors:  ElementColors
    }

    struct ElementColors: Codable, Hashable {
        var metal:  String
        var wood:   String
        var water:  String
        var fire:   String
        var earth:  String
    }
}
