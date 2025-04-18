import SwiftUI

struct ContentView: View {
    @EnvironmentObject var braceletVM: BraceletViewModel
    @EnvironmentObject var analysisVM: AnalysisViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    analysisSection
                    braceletControls
                    BraceletCanvasView()
                        .frame(width: 320, height: 320)
                        .onChange(of: analysisVM.ratios) { newValue in
                            if let r = newValue {
                                braceletVM.randomise(for: r.goal, colors: r.colors)
                            }
                        }
                    animationButtons
                    if let ratios = analysisVM.ratios {
                        ElementHistogramView(current: ratios.current, goal: ratios.goal, colors: ratios.colors)
                            .padding(.horizontal)
                        AnalysisPanelView(text: analysisVM.analysisText)
                    }
                }
                .padding()
            }
            .navigationTitle("水晶手串定制")
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

