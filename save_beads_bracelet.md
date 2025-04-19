1. **Add persistence & toggle at top of the class**
   ```swift
   private let storageKey = "braceletJSON"
   @Published var useServerArrange: Bool = true
   ```

2. **Replace `init()` with**
   ```swift
   init() {
       if let data = UserDefaults.standard.data(forKey: storageKey),
          let stored = try? JSONDecoder().decode([Bead].self, from: data) {
           bracelet = stored
           numBeads = stored.count
       } else {
           resizeBracelet(to: numBeads)
       }
       Task { await fetchPalette() }
   }
   ```

3. **Implement `save()`**
   ```swift
   private func save() {
       if let data = try? JSONEncoder().encode(bracelet) {
           UserDefaults.standard.set(data, forKey: storageKey)
       }
   }
   ```

4. **Call `save()`** at the end of  
   * `resizeBracelet`, `setColor`, `swapBeads`, and `randomise`.

5. **Add server arrangement helper**
   ```swift
   @MainActor
   func arrangeViaServer(using ratios: AnalysisResponse.RatioContainer) async {
       guard useServerArrange else {
           randomise(for: ratios.goal, colors: ratios.colors); return
       }
       let req = ArrangeRequest(numBeads: numBeads, ratios: ratios,
                                seed: Int(Date().timeIntervalSince1970))
       do {
           let resp = try await ArrangeService.arrange(req)
           bracelet = resp.beads.map { Bead(colorHex: $0) }
           save()
           UIImpactFeedbackGenerator(style: .light).impactOccurred()
       } catch {
           print("/api/arrange failed → fallback:", error)
           randomise(for: ratios.goal, colors: ratios.colors)
       }
   }
   ```

6. **Wire it in `ContentView`**
   ```swift
   .onChange(of: analysisVM.ratios) { r in
       if let r = r { Task { await braceletVM.arrangeViaServer(using: r) } }
   }
   ```

