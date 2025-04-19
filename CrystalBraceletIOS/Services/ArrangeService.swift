// Services/ArrangeService.swift
struct ArrangeService {
    static func arrange(_ req: ArrangeRequest) async throws -> ArrangeResponse {
        try await APIService.shared.post(
            "api/arrange",
            body: req,
            decodeTo: ArrangeResponse.self
        )
    }
}

