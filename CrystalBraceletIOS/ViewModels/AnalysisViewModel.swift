import SwiftUI

@MainActor
final class AnalysisViewModel: ObservableObject {
    @Published var analysisText: String = ""
    @Published var ratios: AnalysisResponse.RatioContainer? = nil
    @Published var isLoading = false

    // User inputs
    @Published var dob: Date = Date()          // native type      // YYYY‑MM‑DD
    @Published var birthTime = "" // HH:mm
    @Published var gender = ""   // male | female
    @Published var deepseekKey = ""
    @Published var openaiKey  = ""

    func analyse() async {
        guard !birthTime.isEmpty, !gender.isEmpty,
              !deepseekKey.isEmpty, !openaiKey.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        let dobString = DateFormatter.serverDate.string(from: dob)   // ← format once
        let req = AstrologyRequest(
            dob: dobString,
            birthTime: birthTime,
            gender: gender,
            deepseekKey: deepseekKey,
            openaiKey: openaiKey
        )

        do {
            let resp = try await AstrologyService.analyse(req)
            analysisText = resp.analysis
            ratios = resp.ratios
        } catch {
            print("Astrology API error:", error)
        }
    }

    // Clipboard copy
    func copyReport() {
        guard let ratios else { return }
        let report = ["analysis": analysisText, "ratios": ratios] as [String : Any]
        if let data = try? JSONSerialization.data(withJSONObject: report, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = str
        }
    }
}
