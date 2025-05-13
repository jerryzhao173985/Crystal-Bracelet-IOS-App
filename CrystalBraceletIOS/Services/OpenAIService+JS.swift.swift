//  Services/OpenAIService.swift

import Foundation

@MainActor
enum OpenAIError: LocalizedError {
    case badStatus(Int)
    case emptyReply
    case noAPIKey
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): return "OpenAI 返回 \(code)"
        case .emptyReply:          return "模型未返回内容"
        case .noAPIKey:            return "未配置 OpenAI Key"
        case .network(let err):    return err.localizedDescription
        }
    }
}

struct OpenAIService {

    static let shared = OpenAIService()
    private init() {}

    // MARK: – Public ----------------------------------------------------
    /// Generate a JavaScript helper file from a natural-language prompt.
    /// - Returns: plain JS source (never empty – falls back to whole reply).
    func generateJS(prompt: String, apiKey: String) async throws -> String {

        guard !apiKey.isEmpty else { throw OpenAIError.noAPIKey }

        //----------------------------------------------------------------
        // 1. Build JSON request body
        //----------------------------------------------------------------
        struct Request: Encodable {
            let model  = "gpt-4.1"
            let input: String
        }
        let body = Request(input:
        """
        Write a JavaScript helper file.

        \(prompt)

        **Requirements**
        1. Use doc-comments for every function.
        2. No Node-only APIs (`require` / `import`) – browser-safe JS only.
        3. Return *only* the code inside a Markdown ```js block.
        """
        )

        var rq = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        rq.httpMethod = "POST"
        rq.timeoutInterval = 60                // network + model time
        rq.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        rq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        rq.httpBody = try JSONEncoder().encode(body)

        //----------------------------------------------------------------
        // 2. Fire request
        //----------------------------------------------------------------
        let (data, resp): (Data, URLResponse)
        do {
            (data, resp) = try await URLSession.shared.data(for: rq)
            rq.timeoutInterval = 120
        } catch {
            throw OpenAIError.network(error)
        }

        guard let http = resp as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw OpenAIError.badStatus((resp as? HTTPURLResponse)?.statusCode ?? -1)
        }

        //----------------------------------------------------------------
        // 3. Mine *any* string field that contains a fenced block
        //----------------------------------------------------------------
        guard let md = firstStringWithFence(in: data) else {
            throw OpenAIError.emptyReply
        }

        return bestEffortExtract(from: md)
    }

    // MARK: – Private helpers ------------------------------------------

    /// Depth-first search through arbitrary JSON for the *first* String that
    /// contains ``` (fence) to signal code / markdown.
    private func firstStringWithFence(in raw: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: raw) else { return nil }
        func dfs(_ any: Any) -> String? {
            if let s = any as? String, s.contains("```") { return s }
            if let arr = any as? [Any]     { for v in arr  { if let s = dfs(v) { return s } } }
            if let dict = any as? [String:Any] {
                for v in dict.values { if let s = dfs(v) { return s } }
            }
            return nil
        }
        return dfs(json)
    }

    /// 1) ```js``` → 2) *any* fenced block → 3) raw markdown
    private func bestEffortExtract(from markdown: String) -> String {
        // Preferred: ```js / ```javascript
        if let rng = markdown.range(
            of: #"```(?:js|javascript)\s*([\s\S]*?)```"#,
            options: .regularExpression) {
            return String(markdown[rng])
                .replacingOccurrences(of: #"```(?:js|javascript)"#,
                                       with: "", options: .regularExpression)
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Fallback: first fenced block of *any* language
        if let rng = markdown.range(
            of: #"```[a-zA-Z0-9]*\s*([\s\S]*?)```"#,
            options: .regularExpression) {
            return String(markdown[rng])
                .replacingOccurrences(of: #"```[a-zA-Z0-9]*"#,
                                       with: "", options: .regularExpression)
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Last-resort: whole reply
        return markdown.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
