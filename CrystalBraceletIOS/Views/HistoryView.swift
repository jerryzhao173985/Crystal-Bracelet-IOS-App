// Views/HistoryView.swift
import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var braceletVM:  BraceletViewModel
    @EnvironmentObject var analysisVM:  AnalysisViewModel
    @ObservedObject var store = HistoryStore.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.items) { entry in
                    // in cell label:
                    Button {
                        load(entry); dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.dob, format: .dateTime.year().month().day())
                                Text(entry.birthTime).font(.caption)
                                Text(entry.gender == "male" ? "男" : "女")
                            }
                            .font(.caption2)

                            ColorDotsRow(colors: [entry.ratios.colors.metal,
                                                  entry.ratios.colors.wood,
                                                  entry.ratios.colors.water,
                                                  entry.ratios.colors.fire,
                                                  entry.ratios.colors.earth])
//                            Spacer()
//                            VStack(alignment: .trailing) {
//                                Text(entry.timestamp, style: .date).font(.caption)
//                                Text("\(entry.numBeads) beads").font(.caption2)
//                            }
//                            .foregroundStyle(.secondary)

                            MicroHistogram(current: entry.ratios.current, goal: entry.ratios.goal)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
//                        Add a trailing bead‑count:
                        .overlay(
                            Text("\(entry.numBeads)")
                                .font(.footnote.monospacedDigit())
                                .padding(.trailing, 4),
                            alignment: .trailing
                        )
                    }
                }
                .onDelete { store.delete(at: $0) }
            }
            .navigationTitle("历史记录")
            .toolbar { EditButton() }
        }
    }

    private func load(_ e: HistoryEntry) {
        analysisVM.source     = .history            // ← add History load sets flag
        braceletVM.numBeads  = e.numBeads
        analysisVM.dob       = e.dob
        analysisVM.birthTime = e.birthTime
        analysisVM.gender    = e.gender
        analysisVM.analysisText = e.analysis
        analysisVM.ratios    = e.ratios
//        braceletVM.bracelet  = e.beads.map { Bead(colorHex: $0) }
        
        // re‑arrange bracelet colours using stored palette
        braceletVM.randomise(for: e.ratios.goal, colors: e.ratios.colors)
    }
}

