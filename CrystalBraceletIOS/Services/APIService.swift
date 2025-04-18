import Foundation

struct APIService {
    static let shared = APIService()
    private init() {}
    
    enum APIError: Error { case invalidURL, nonHTTPResponse, badStatus(Int), notJson }
    
    private func validate(_ response: URLResponse, data: Data, url: URL) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.nonHTTPResponse }
        #if DEBUG
        print("↩️ \(http.statusCode) \(url.absoluteString)")
        if let ct = http.value(forHTTPHeaderField: "Content-Type") { print("   content-type: \(ct)") }
        #endif
        guard (200..<300).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
        if let ct = http.value(forHTTPHeaderField: "Content-Type"), !ct.contains("application/json") {
            if let html = String(data: data, encoding: .utf8) {
                print("⚠️ Unexpected non‑JSON (first 200 chars):", html.prefix(200))
            }
            throw APIError.notJson
        }
        guard (200..<300).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
        if let ct = http.value(forHTTPHeaderField: "Content-Type"), !ct.contains("application/json") {
            if let html = String(data: data, encoding: .utf8) { print("Unexpected HTML response:", html.prefix(200)) }
            throw APIError.notJson
        }
    }
    
    func get<T: Decodable>(_ path: String, decodeTo type: T.Type) async throws -> T {
        guard let url = URL(string: baseURL)?.appendingPathComponent(path) else { throw APIError.invalidURL }
        let (data, resp) = try await URLSession.shared.data(from: url)
        try validate(resp, data: data, url: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func post<T: Decodable, Body: Encodable>(_ path: String, body: Body, decodeTo type: T.Type) async throws -> T {
        guard let url = URL(string: baseURL)?.appendingPathComponent(path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try validate(resp, data: data, url: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Configuration
    var baseURL: String = "https://crystal-bracelet-customization.vercel.app" // ← Replace / env
}
