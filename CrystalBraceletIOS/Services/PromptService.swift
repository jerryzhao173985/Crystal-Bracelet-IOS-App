// Services/PromptService.swift
import Foundation

struct PromptService {
    static func fetchTemplates() async throws -> [String:String] {
        try await APIService.shared.get(
            "api/prompt",
            decodeTo: [String:String].self
        )
    }
}
