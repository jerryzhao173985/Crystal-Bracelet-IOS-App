import Foundation

struct AstrologyRequest: Encodable {
    var dob: String      // YYYY‑MM‑DD
    var birthTime: String // HH:mm
    var gender: String    // "male" | "female"
    var deepseekKey: String
    var openaiKey: String
    
    // NEW:
    let promptType: String
    let customPrompt: String?
}
