// Services/CustomPromptStore.swift
import Foundation

@MainActor
final class CustomPromptStore: ObservableObject {
    static let shared = CustomPromptStore()

    @Published private(set) var items: [CustomPromptEntry] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        return docs.appendingPathComponent("custom_prompts.json")
    }()

    init() { load() }

    func add(_ entry: CustomPromptEntry) {
        items.insert(entry, at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("CustomPromptStore save error:", error)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let arr  = try? JSONDecoder().decode([CustomPromptEntry].self, from: data)
        else { return }
        items = arr
    }
}
