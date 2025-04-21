import Foundation

struct AstrologyService {
    static func analyse(_ req: AstrologyRequest) async throws -> AnalysisResponse {
        try await APIService.shared.post("api/astro", body: req, decodeTo: AnalysisResponse.self)
    }
}
