import Foundation

struct AstrologyRequest: Encodable {
    var dob: String      // YYYY‑MM‑DD
    var birthTime: String // HH:mm
    var gender: String    // "male" | "female"
    var deepseekKey: String
    var openaiKey: String
    
    // prompt controls
    let promptType: String
    let customPrompt: String?
    
    // base-64 helpers.js  (nil → omitted)
    // Swift’s default Encodable will automatically emit "file": "…" when non-nil.
    var file: String?
}
