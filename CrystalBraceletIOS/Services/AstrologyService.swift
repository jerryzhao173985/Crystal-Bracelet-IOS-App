import Foundation

struct AstrologyRequest: Encodable {
    var dob: String      // YYYY‑MM‑DD
    var birthTime: String // HH:mm
    var gender: String    // "male" | "female"
    var deepseekKey: String
    var openaiKey: String
}

struct AstrologyService {
    static func analyse(_ req: AstrologyRequest) async throws -> AnalysisResponse {
        try await APIService.shared.post("api/astro", body: req, decodeTo: AnalysisResponse.self)
    }
}
