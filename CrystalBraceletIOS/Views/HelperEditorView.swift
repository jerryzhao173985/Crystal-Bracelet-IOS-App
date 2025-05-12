// HelperEditorView.swift – standalone SwiftUI editor for functions.js
// Includes:
//   • HelperCodeStore  – singleton that manages loading / saving JS text
//   • HelperEditorView – UI for editing, saving, restoring the code
//
// 1.  On first launch we copy Bundle("functions.js") to Application‑Support.
// 2.  Any edits are persisted to disk; re‑opened app reloads same file.
// 3.  The AnalysisService reads HelperCodeStore.shared.javascript when
//     building its request and, if not empty, Base‑64 encodes it into the
//     JSON payload (key: "file").
// ---------------------------------------------------------------------

import SwiftUI

// MARK: - HelperCodeStore ------------------------------------------------
@MainActor
final class HelperCodeStore: ObservableObject {
    static let shared = HelperCodeStore()

    @Published private(set) var javascript: String = ""       // current text

    private let savedURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("functions.js")
    }()

    private let bundleName = "functions"      // functions.js in main bundle

    private init() {
        load()                               // load on first access
    }

    /// load from disk, or copy bundle default
    private func load() {
        if FileManager.default.fileExists(atPath: savedURL.path) {
            javascript = (try? String(contentsOf: savedURL, encoding: .utf8)) ?? ""
        } else if let bundleURL = Bundle.main.url(forResource: bundleName, withExtension: "js"),
                  let txt = try? String(contentsOf: bundleURL, encoding: .utf8) {
            javascript = txt
            try? txt.write(to: savedURL, atomically: true, encoding: .utf8)
        }
    }

    /// Persist current JS text
    func save(_ text: String) throws {
        try text.write(to: savedURL, atomically: true, encoding: .utf8)
        javascript = text
    }

    /// Revert to last‑saved disk version
    func revert() {
        load()
    }

    /// Restore original bundle version (discard all edits)
    func resetToDefault() {
        if let bundleURL = Bundle.main.url(forResource: bundleName, withExtension: "js"),
           let txt = try? String(contentsOf: bundleURL, encoding: .utf8) {
            javascript = txt
            try? txt.write(to: savedURL, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - HelperEditorView ----------------------------------------------
struct HelperEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = HelperCodeStore.shared

    @State private var draft: String = ""
    @State private var showDiscardAlert = false

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            TextEditor(text: $draft)
                .font(.system(.body, design: .monospaced))
                .padding()
                .focused($isFocused)
                .onAppear { draft = store.javascript }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("恢复默认") {
                            showDiscardAlert = true
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button("还原") {
                            draft = store.javascript
                            isFocused = false
                        }
                        Button("保存") {
                            try? store.save(draft)
                            dismiss()
                        }
                        .disabled(draft == store.javascript)
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("收起键盘") { isFocused = false }
                    }
                }
                .alert("恢复为应用默认?", isPresented: $showDiscardAlert) {
                    Button("取消", role: .cancel) {}
                    Button("确定", role: .destructive) {
                        store.resetToDefault()
                        draft = store.javascript
                    }
                } message: {
                    Text("这将丢弃您所有的自定义函数并恢复为出厂版本。")
                }
                .navigationTitle("functions.js")
        }
    }
}

// MARK: - Integration Helpers -------------------------------------------
extension HelperCodeStore {
    /// Base‑64 of current JS for JSON transport (\"file\" key)
    var base64: String? {
        let data = javascript.data(using: .utf8)
        return data?.base64EncodedString()
    }
}

