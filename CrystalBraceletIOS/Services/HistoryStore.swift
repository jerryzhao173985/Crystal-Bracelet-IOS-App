// Services/HistoryStore.swift
import Foundation

@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    private init() { load() }

    @Published private(set) var items: [HistoryEntry] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("bracelet_history.json")
    }()

    // MARK: CRUD
    func add(_ entry: HistoryEntry) {
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
        } catch { print("History save error:", error) }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let arr  = try? JSONDecoder().decode([HistoryEntry].self, from: data) else { return }
        items = arr
    }
}

