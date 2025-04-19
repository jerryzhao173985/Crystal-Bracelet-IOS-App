// Models/ArrangeRequest.swift
struct ArrangeRequest: Encodable {
    var numBeads: Int
    var ratios: AnalysisResponse.RatioContainer   // we reuse the exact struct from /api/astro
    var seed: Int?                                // optional
}

// Models/ArrangeResponse.swift
struct ArrangeResponse: Decodable {
    var beads: [String]                           // ["#RRGGBB", …]
}

