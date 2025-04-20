// Views/FloatingHistoryButton.swift
import SwiftUI

struct FloatingHistoryButton: View {
    @Binding var showHistory: Bool
    var body: some View {
        Button {
            showHistory = true
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .hoverEffect(.highlight)
    }
}

