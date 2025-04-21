// Models/HistoryEntry.swift
import Foundation

struct HistoryEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date

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
    
    // NEW
    var beads: [String]?          // optional colour array

    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         dob: Date, birthTime: String, gender: String,
         numBeads: Int, analysis: String,
         ratios: AnalysisResponse.RatioContainer,
         beads: [String]? = nil) {
        self.id = id;
        self.timestamp = timestamp
        self.dob = dob;
        self.birthTime = birthTime;
        self.gender = gender
        self.numBeads = numBeads;
        self.analysis = analysis;
        self.ratios = ratios
        self.beads = beads
    }
}
