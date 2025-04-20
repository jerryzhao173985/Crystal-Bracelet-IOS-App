// Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var braceletVM:  BraceletViewModel
    @EnvironmentObject var analysisVM:  AnalysisViewModel

    @State private var showHistory = false          // controls the sheet // keep existing sheet

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
                                
                                // save only if this is a *live* session
                                if analysisVM.source == .live {
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
//                .coordinateSpace(name: "scroll")      // ← gives GeometryReader a space
            }
            .navigationTitle("水晶手串定制")
            .navigationBarTitleDisplayMode(.inline)   // compact title stops large‑title push // compact title = no push
            
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

    // MARK: - Subviews -----------------------------------------------------------
    private var analysisSection: some View {
        GroupBox("命理五行分析") {
            VStack(alignment: .leading, spacing: 12) {
                DatePicker("出生日期",
                           selection: $analysisVM.dob,
                           displayedComponents: .date)
                TextField("出生时间 (HH:mm)", text: $analysisVM.birthTime)
                    .textFieldStyle(.roundedBorder)
                Picker("性别", selection: $analysisVM.gender) {
                    Text("男").tag("male")
                    Text("女").tag("female")
                }.pickerStyle(.segmented)
                SecureField("DeepSeek API Key", text: $analysisVM.deepseekKey)
                    .textFieldStyle(.roundedBorder)
                SecureField("OpenAI API Key", text: $analysisVM.openaiKey)
                    .textFieldStyle(.roundedBorder)
                let inputsReady = !analysisVM.birthTime.isEmpty && !analysisVM.gender.isEmpty && !analysisVM.deepseekKey.isEmpty && !analysisVM.openaiKey.isEmpty
                    Button(analysisVM.isLoading ? "分析中…" : (inputsReady ? "开始分析" : "填写完整信息")) {
                        Task { await analysisVM.analyse() }
//                        /// At the end of a fresh Analyse run, reset to live:
//                        analysisVM.source = .live      // append to end of analyse() after success
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!inputsReady || analysisVM.isLoading)
                }
                .buttonStyle(.borderedProminent)
                .disabled(analysisVM.isLoading)
            
        }
    }

    private var braceletControls: some View {
        HStack(alignment: .center, spacing: 16) {
            Stepper(value: $braceletVM.numBeads, in: 1...braceletVM.MAX_BEADS) {
                Text("珠子数量: \(braceletVM.numBeads)")
            }
            .disabled(braceletVM.isAnimating || braceletVM.growthAnimating)
            Slider(value: $braceletVM.speed, in: 0.5...2.0, step: 0.1) {
                Text("速度")
            }
            .frame(width: 120)
            Text("\(braceletVM.speed, specifier: "%.1f")×").font(.subheadline)
        }
        .padding(.horizontal, 8)            // adds breathing room
    }

    private var animationButtons: some View {
        HStack(spacing: 16) {
            Button("随机排珠") {
                if let r = analysisVM.ratios {
                    braceletVM.randomise(for: r.goal, colors: r.colors)
                }
            }
            .disabled(analysisVM.ratios == nil)
            .buttonStyle(.borderedProminent)

            Button(braceletVM.isAnimating ? "动画中…" : "闪动动画") {
                if let r = analysisVM.ratios {
                    braceletVM.flashRandomise(goal: r.goal, colors: r.colors)
                }
            }
            .disabled(braceletVM.isAnimating || braceletVM.growthAnimating || analysisVM.ratios == nil)

            Button(braceletVM.growthAnimating ? "增长中…" : "增长动画") {
                if let r = analysisVM.ratios {
                    braceletVM.growBracelet(goal: r.goal, colors: r.colors)
                }
            }
            .disabled(braceletVM.isAnimating || braceletVM.growthAnimating || analysisVM.ratios == nil)
        }
    }
}

