import SwiftUI
import UniformTypeIdentifiers
import CryptoKit

// MARK: - JSFileEntry ----------------------------------------------------
struct JSFileEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var url: URL            // persisted location on disk

    init(name: String, url: URL) {
        self.id   = UUID()
        self.name = name
        self.url  = url
    }
}

// MARK: - JSFileStore (multi‑file) --------------------------------------
@MainActor
final class JSFileStore: ObservableObject {
    static let shared = JSFileStore()

    @Published private(set) var files: [JSFileEntry] = []
    @Published var currentID: UUID?              // selected file

    private let dir: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sub  = docs.appendingPathComponent("helpers", isDirectory: true)
        try? FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        return sub                               // ⬅︎ WAS applicationSupport
    }()

    private let defaultsKey = "helperFileList"

    private init() {
        loadFileList()
        if files.isEmpty { createFirstDefault() }
        if currentID == nil { currentID = files.first?.id }
    }

    // Base‑64 of currently selected file (nil if none)
    var base64: String? {
        guard let entry = files.first(where: { $0.id == currentID }),
              let data  = try? Data(contentsOf: entry.url) else { return nil }
        return data.base64EncodedString()
    }

    // MARK: CRUD ---------------------------------------------------------
    func create(_ initial: String, named name: String) {
        let fileURL = dir.appendingPathComponent(name + ".js")
        try? initial.write(to: fileURL, atomically: true, encoding: .utf8)
        let entry = JSFileEntry(name: name, url: fileURL)
        files.append(entry)
        currentID = entry.id
        persistList()
    }

    func rename(_ id: UUID, to newName: String) {
        guard var entry = files.first(where: { $0.id == id }) else { return }
        let newURL = dir.appendingPathComponent(newName + ".js")
        try? FileManager.default.moveItem(at: entry.url, to: newURL)
        entry.name = newName
        entry.url  = newURL
        if let idx = files.firstIndex(where: { $0.id == id }) { files[idx] = entry }
        persistList()
    }

    func delete(_ ids: IndexSet) {
        for idx in ids {
            let entry = files[idx]
            try? FileManager.default.removeItem(at: entry.url)
        }
        files.remove(atOffsets: ids)
        if currentID == nil || !files.contains(where: { $0.id == currentID }) {
            currentID = files.first?.id
        }
        persistList()
    }

    func save(code: String) {
        guard let entry = files.first(where: { $0.id == currentID }) else { return }
        try? code.write(to: entry.url, atomically: true, encoding: .utf8)
        persistList()
    }

    func loadCode() -> String {
        guard let entry = files.first(where: { $0.id == currentID }),
              let text = try? String(contentsOf: entry.url, encoding: .utf8) else { return "" }
        return text
    }

    // MARK: Persist list --------------------------------------------------
    private func persistList() {
        let data = try? JSONEncoder().encode(files)
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func loadFileList() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let arr  = try? JSONDecoder().decode([JSFileEntry].self, from: data) {
            files = arr.filter { FileManager.default.fileExists(atPath: $0.url.path) }
            currentID = files.first?.id
        }
    }

    private func createFirstDefault() {
        if let bundleURL = Bundle.main.url(forResource: "functions", withExtension: "js"),
           let text = try? String(contentsOf: bundleURL, encoding: .utf8) {
            create(text, named: "default")
        } else {
            create("// write your helper functions here\n", named: "default")
        }
    }
}

// MARK: - Syntax‑highlight TextEditor wrapper ---------------------------
/// Very lightweight JS keyword tinting using AttributedString (iOS 17+).
struct CodeTextEditor: UIViewRepresentable {
    @Binding var text: String

    private let keywords = ["function", "return", "const", "let", "var", "=>"]

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.delegate = context.coordinator
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
        applyHighlight(to: uiView)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CodeTextEditor
        init(_ p: CodeTextEditor) { parent = p }
        func textViewDidChange(_ tv: UITextView) { parent.text = tv.text }
    }

    private func applyHighlight(to tv: UITextView) {
        guard let str = tv.text else { return }
        let attr = NSMutableAttributedString(string: str)
        let full = NSRange(location: 0, length: (str as NSString).length)
        attr.addAttribute(.foregroundColor, value: UIColor.label, range: full)
        for kw in keywords {
            let regex = try? NSRegularExpression(pattern: "\\b" + kw + "\\b")
            regex?.enumerateMatches(in: str, range: full) { match, _, _ in
                if let r = match?.range {
                    attr.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: r)
                }
            }
        }
        tv.attributedText = attr
    }
}

// MARK: - HelperEditorView ----------------------------------------------
struct HelperEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = JSFileStore.shared

    @State private var draft: String = ""
    @State private var savedSnapshot  = ""   // <-- NEW
    @State private var saveTask: Task<Void, Never>? // Bonus: modernising the autosave delay
    
    @State private var newFileName = ""
    @State private var showNewFileSheet = false
    @State private var showRenameSheet = false

    @FocusState private var isEditorFocused: Bool

    // load draft when selection changes
    private func refreshDraft() {
        let text = store.loadCode()
        draft          = text
        savedSnapshot  = text                // <-- keep them in sync
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ---------- top bar file picker ----------
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.files) { file in
                            Text(file.name)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(file.id == store.currentID
                                                   ? Color.accentColor.opacity(0.25)
                                                   : Color.secondary.opacity(0.12))
                                )
                                .overlay(                           // ● unsaved dot
                                    Group {
                                        //  ● badge
                                        if draft != savedSnapshot && file.id == store.currentID {
                                            Circle().fill(Color.red).frame(width:6,height:6)
                                                .offset(x:10,y:-10)
                                        }
                                    }
                                )
                                .cornerRadius(6)
                                .onTapGesture { store.currentID = file.id; refreshDraft() }
                                .contextMenu {
                                    Button("重命名") { newFileName = file.name; showRenameSheet = true; store.currentID = file.id }
                                    Button("删除", role: .destructive) {
                                        if let idx = store.files.firstIndex(of: file) {
                                            store.delete(IndexSet(integer: idx))
                                            refreshDraft()
                                        }
                                    }
                                }
                        }
                        Button(action: { showNewFileSheet = true }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                    .padding(.horizontal)
                }
                Divider()

                // ------------ code editor ---------------
                CodeTextEditor(text: $draft)
                    .focused($isEditorFocused)
                    .onChange(of: draft) { newValue in                  // NEW
                        // cancel any previous 2-second countdown
                        // Auto-save every 2 s while typing
                        // (Manual 保存 still persists immediately and resets the red dot.)
                        saveTask?.cancel()
                        saveTask = Task { @MainActor in
                            try? await Task.sleep(for: .seconds(2))
                            store.save(code: newValue)   // ← write to disk
                            savedSnapshot = newValue     // ← clear the red dot
                        }
                   }
            }
            .onAppear { refreshDraft() }
            .onDisappear { saveTask?.cancel() }
            .navigationTitle("functions.js")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        store.save(code: draft)
                        savedSnapshot = draft          // mark clean
                        dismiss()
                    }
                    .disabled(draft == store.loadCode())
                }
                
                // — File-size badge —
                  ToolbarItem(placement: .navigationBarTrailing) {
                    if let entry = store.files.first(where: { $0.id == store.currentID }),
                       let vals  = try? entry.url.resourceValues(forKeys: [.fileSizeKey]),
                       let bytes = vals.fileSize
                    {
                      Text(bytes < 1_024 ? "\(bytes) B" : "\(bytes/1_024) KB")
                        .font(.caption)
                        .foregroundColor(bytes > 12_288 ? .red : .secondary)
                    }
                  }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("收起键盘") { isEditorFocused = false }
                }
            }
            // New file sheet
            .alert("新建文件", isPresented: $showNewFileSheet, actions: {
                TextField("文件名", text: $newFileName)
                Button("创建") {
                    let name = newFileName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty { store.create("// \(name).js\n", named: name) }
                    newFileName = ""
                    refreshDraft()
                }
                Button("取消", role: .cancel) { newFileName = "" }
            }, message: { Text("请输入文件名") })
            // Rename sheet
            .alert("重命名", isPresented: $showRenameSheet, actions: {
                TextField("文件名", text: $newFileName)
                Button("保存") {
                    let name = newFileName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let id = store.currentID, !name.isEmpty { store.rename(id, to: name) }
                    newFileName = ""; refreshDraft()
                }
                Button("取消", role: .cancel) { newFileName = "" }
            }, message: { Text("输入新的文件名") })
        }
    }
}

extension JSFileStore {
    /// Returns (sha, b64) if file ≤ 12 KB, else nil
    var payload: (String,String)? {
        guard let entry = files.first(where: { $0.id == currentID }),
              let data  = try? Data(contentsOf: entry.url),
              data.count <= 12_288 else {               // 12 KB hard-cap
            return nil
        }
        let sha = Insecure.SHA1.hash(data: data)         // 20-byte, cheap
            .map { String(format: "%02hhx", $0) }
            .joined()
        return (sha, data.base64EncodedString())
    }
}

// MARK: - Preview
struct HelperEditorView_Previews: PreviewProvider {
    static var previews: some View {
        HelperEditorView()
    }
}

