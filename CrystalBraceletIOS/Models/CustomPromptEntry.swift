// Models/CustomPromptEntry.swift
import Foundation

struct CustomPromptEntry: Identifiable, Codable {
    let id       = UUID()
    let name:     String   // user‑given nickname
    let prompt:   String   // the prompt text
}
