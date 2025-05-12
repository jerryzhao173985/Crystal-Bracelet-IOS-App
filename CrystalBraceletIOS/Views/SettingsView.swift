import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var analysisVM: AnalysisViewModel
    @StateObject private var presetStore = CustomPromptStore.shared

    @State private var showSaveSheet = false
    @State private var newPresetName = ""
    @State private var showNameError = false
    @State private var nameErrorMessage = ""

    @FocusState private var isPromptEditorFocused: Bool
    @FocusState private var isPresetNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Prompt Source Picker + Custom Toggle
                Section("Prompt Source") {
                    Picker("模板", selection: $analysisVM.promptType) {
                        ForEach(analysisVM.promptTemplates.keys.sorted(), id: \.self) { key in
                            Text(key.capitalized).tag(key)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("使用自定义 Prompt", isOn: $analysisVM.customPromptEnabled)
                        .onChange(of: analysisVM.customPromptEnabled) { on in
                            if !on {
                                analysisVM.customPrompt = ""
                            }
                        }
                    
                    // UI hook to JS function editor
                    NavigationLink {
                        HelperEditorView()
                    } label: {
                        Label("编辑 JavaScript 函数文件", systemImage: "hammer")
                    }
                }

                // MARK: Prompt Content Display or Editor
                if analysisVM.customPromptEnabled {
                    // Editable custom prompt
                    Section("自定义 Prompt 编辑") {
                        ZStack(alignment: .topLeading) {
                            if analysisVM.customPrompt.isEmpty {
                                Text("请输入自定义 Prompt……")
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                            TextEditor(text: $analysisVM.customPrompt)
                                .focused($isPromptEditorFocused)
                                .frame(minHeight: 120)
                        }
                        HStack {
                            Spacer()
                            Button("保存预设") {
                                isPromptEditorFocused = false
                                showSaveSheet = true
                            }
                            .disabled(
                                analysisVM.customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                || presetStore.items.contains(where: { $0.prompt == analysisVM.customPrompt.trimmingCharacters(in: .whitespacesAndNewlines) })
                            )
                        }
                    }
                } else {
                    // Read-only preview of selected template
                    Section("Prompt 模板预览") {
                        TextEditor(text: .constant(
                            analysisVM.promptTemplates[analysisVM.promptType] ?? ""
                        ))
                        .disabled(true)
                        .frame(minHeight: 120)
                    }
                }

                // MARK: Saved Presets
                if !presetStore.items.isEmpty {
                    Section("预设列表") {
                        ForEach(presetStore.items) { preset in
                            HStack {
                                Text(preset.name)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // load preset into custom editor
                                analysisVM.customPrompt = preset.prompt
                                analysisVM.customPromptEnabled = true
                            }
                            .contextMenu(menuItems: {
                                Button("复制 Prompt") {
                                    UIPasteboard.general.string = preset.prompt
                                }
                                Button(role: .destructive) {
                                    if let idx = presetStore.items.firstIndex(where: { $0.id == preset.id }) {
                                        presetStore.delete(at: IndexSet(integer: idx))
                                    }
                                } label: {
                                    Text("删除预设")
                                }
                            }, preview: {
                                ScrollView {
                                    Text(preset.prompt)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(width: UIScreen.main.bounds.width * 0.9,
                                       height: UIScreen.main.bounds.height * 0.6)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            })
                        }
                        .onDelete { presetStore.delete(at: $0) }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("收起键盘") {
                        isPromptEditorFocused = false
                        isPresetNameFocused = false
                    }
                }
            }
            .task { analysisVM.loadPromptTemplates() }
            .sheet(isPresented: $showSaveSheet) {
                NavigationStack {
                    Form {
                        Section("预设名称") {
                            TextField("请输入名称", text: $newPresetName)
                                .focused($isPresetNameFocused)
                        }
                    }
                    .navigationTitle("保存 Prompt 预设")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("取消") {
                                showSaveSheet = false
                                newPresetName = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("保存") {
                                let name = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
                                let prompt = analysisVM.customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
                                if presetStore.items.contains(where: { $0.name == name }) {
                                    nameErrorMessage = "已存在名称 \"\(name)\"，请修改后再保存"
                                    showNameError = true
                                } else {
                                    let entry = CustomPromptEntry(name: name, prompt: prompt)
                                    presetStore.add(entry)
                                    newPresetName = ""
                                    showSaveSheet = false
                                }
                                isPresetNameFocused = false
                            }
                            .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("完成") { isPresetNameFocused = false }
                        }
                    }
                    .alert("命名冲突", isPresented: $showNameError) {
                        Button("知道了", role: .cancel) { showNameError = false }
                    } message: {
                        Text(nameErrorMessage)
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AnalysisViewModel())
            .environmentObject(BraceletViewModel())
    }
}

