// Models/HistoryEntry.swift
import Foundation

struct HistoryEntry: Identifiable, Codable {
    let id        = UUID()
    let timestamp = Date()

    // inputs
    var dob:        Date
    var birthTime:  String
    var gender:     String
    var numBeads:   Int

    // outputs
    var analysis:   String
    var ratios:     AnalysisResponse.RatioContainer
//    Because ratios.colors already keeps the user‑specific HEX palette, we can drop the full bead array.
//    All we do on restore is randomise (or /api/arrange) again with that palette
//    var beads:      [String]          // ["#RRGGBB", …] – saved after arrange/randomise
}
