// Views/ColorDotsRow.swift
import SwiftUI

struct ColorDotsRow: View {
    let colors: [String]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(colors, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 10, height: 10)
            }
        }
    }
}
