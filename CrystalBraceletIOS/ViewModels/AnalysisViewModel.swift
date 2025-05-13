import SwiftUI
import Foundation

private let kDeepSeekKey = "deepseekKey"
private let kOpenAIKey   = "openaiKey"

enum SessionSource { case live, history }

@MainActor
final class AnalysisViewModel: ObservableObject {
    @Published var analysisText: String = ""
    @Published var ratios: AnalysisResponse.RatioContainer? = nil
    @Published var isLoading = false
    @Published var source: SessionSource = .live

    // User inputs
    @Published var dob: Date = Date()          // native type      // YYYY‑MM‑DD
    @Published var birthTime = "" // HH:mm
    @Published var gender = ""   // male | female
    @Published var deepseekKey: String = KeychainHelper.shared.read(kDeepSeekKey) ?? ""
    @Published var openaiKey:  String = KeychainHelper.shared.read(kOpenAIKey)  ?? ""
    @Published var currentHistoryID: UUID? = nil
    
    // Customized astro user prompt
    @Published var promptTemplates: [String:String] = [:]
    @Published var promptType: String = "basic"
    @Published var customPrompt: String = ""
    @Published var customPromptEnabled: Bool = false
    
    private var lastSentSHA: String?
    
    func loadPromptTemplates() {
        Task {
            do {
                let templates = try await PromptService.fetchTemplates()
                promptTemplates = templates
                // default to “basic” if available
                if templates.keys.contains("basic") { promptType = "basic" }
            } catch {
                print("Failed to load prompts:", error)
            }
        }
    }
    
    @MainActor   // -- good practice, ensures UI + file ops on main
    func analyse() async {
//        Reset to .live at the start of analyse()
        source = .live
        guard !birthTime.isEmpty, !gender.isEmpty,
              !deepseekKey.isEmpty, !openaiKey.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        // -------- helper JS payload (≤12 KB) -----------------
        let payload = JSFileStore.shared.payload          // (sha,b64) or nil
        let b64      = payload?.1

        if let sha = payload?.0, sha != lastSentSHA {
            lastSentSHA = sha            // remember fingerprint we just sent
        }

        let dobString = DateFormatter.serverDate.string(from: dob)   // ← format once
        let req = AstrologyRequest(
            dob: dobString,
            birthTime: birthTime,
            gender: gender,
            deepseekKey: deepseekKey,
            openaiKey: openaiKey,
            promptType: promptType,
            customPrompt: self.customPromptEnabled ?
                customPrompt.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            file: b64  // JSFileStore.shared.base64  // the service will send the Base-64 string functions.js
        )

        do {
            let resp = try await AstrologyService.analyse(req)
            analysisText = resp.analysis
            ratios = resp.ratios
            
            KeychainHelper.shared.save(deepseekKey, for: kDeepSeekKey)
            KeychainHelper.shared.save(openaiKey,  for: kOpenAIKey)
            
            /// At the end of a fresh Analyse run, reset to live:
            // at end when finish or at start of analyse() // After restoring a history entry, revert the session flag when the user taps “开始分析” again:
            source = .live
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
