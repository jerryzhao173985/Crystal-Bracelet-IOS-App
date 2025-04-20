```swift
// Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var braceletVM:  BraceletViewModel
    @EnvironmentObject var analysisVM:  AnalysisViewModel

    @State private var showHistory = false          // controls the sheet

    var body: some View {

        // ------------------ Navigation root ------------------
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // 1 Inputs & Analyse button
                    analysisSection

                    // 2 Controls (bead count, speed slider, etc.)
                    braceletControls

                    // 3 Bracelet canvas  +  data‑driven hook
                    BraceletCanvasView()
                        .frame(width: 320, height: 320)
                        .onChange(of: analysisVM.ratios) { newValue in
                            guard let r = newValue else { return }
                            Task {    // regenerate + save history
                                braceletVM.randomise(for: r.goal, colors: r.colors)

                                let entry = HistoryEntry(
                                    dob:        analysisVM.dob,
                                    birthTime:  analysisVM.birthTime,
                                    gender:     analysisVM.gender,
                                    numBeads:   braceletVM.numBeads,
                                    analysis:   analysisVM.analysisText,
                                    ratios:     r
                                )
                                HistoryStore.shared.add(entry)
                            }
                        }

                    // 4 Animation buttons
                    animationButtons

                    // 5 Histogram + Markdown analysis
                    if let ratios = analysisVM.ratios {
                        ElementHistogramView(current: ratios.current,
                                             goal:    ratios.goal,
                                             colors:  ratios.colors)
                            .padding(.horizontal)

                        AnalysisPanelView(text: analysisVM.analysisText)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("水晶手串定制")

            // ---------- Toolbar button that opens History ----------
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("历史记录")
                }
            }
        }      // NavigationStack

        // --------------- Sheet presentation -----------------
        .sheet(isPresented: $showHistory) {
            HistoryView()
                .environmentObject(braceletVM)
                .environmentObject(analysisVM)
        }
    }
}
```

**Why this works**

1. **NavigationStack is the root** – the `.toolbar` lives directly inside it, so the button is always visible.  
2. **`showHistory`** controls a `.sheet`; when the button toggles it, SwiftUI slides the *HistoryView* up with the standard card animation.  
3. *HistoryView* gets the same environment objects; on tap it calls `load(entry)` and dismisses itself, restoring the run.

---

### Small UX improvements included

| Improvement | Code detail |
|-------------|-------------|
| **Accessibility label** | `.accessibilityLabel("历史记录")` on the toolbar button. |
| **Vertical padding** | `.padding(.vertical)` on the `VStack` to keep content off safe‑area edges on iPhone SE. |
| **Guard in `onChange`** | Early‑returns if `ratios` becomes `nil`, preventing a crash on reset. |

Re‑build and run: the clock‑arrow button now appears in the upper‑right corner; tapping it reveals the History sheet, and selecting a record re‑loads the bracelet and analysis exactly as requested.
