# Integrating the new **`/api/arrange`** endpoint

The new serverless function returns a *complete bead‑color array* and makes the iOS client lighter and fully deterministic.  

## Revised data‑flow

```
user → /api/astro ──► ratios
                ▼
            /api/arrange  (numBeads,  ratios,  optional seed)
                ▼
     { beads:[HEX,…] }  ──► BraceletViewModel.applyServerBracelet()
```

*If `arrange` fails (network, timeout) we fall back to the existing on‑device `randomise()`.*

---

## 1 · Models

```swift
// Models/ArrangeRequest.swift
struct ArrangeRequest: Encodable {
    var numBeads: Int
    var ratios: AnalysisResponse.RatioContainer   // we reuse the exact struct from /api/astro
    var seed: Int?                                // optional
}

// Models/ArrangeResponse.swift
struct ArrangeResponse: Decodable {
    var beads: [String]                           // ["#RRGGBB", …]
}
```

Add both files under *Models/*.

---

## 2 · Service

```swift
// Services/ArrangeService.swift
struct ArrangeService {
    static func arrange(_ req: ArrangeRequest) async throws -> ArrangeResponse {
        try await APIService.shared.post(
            "api/arrange",
            body: req,
            decodeTo: ArrangeResponse.self
        )
    }
}
```

---

## 3 · BraceletViewModel extension

Append to **`BraceletViewModel.swift`**:

```swift
// MARK: - Remote arrangement (via /api/arrange)
@MainActor
func arrangeViaServer(using ratios: AnalysisResponse.RatioContainer) async {
    let req = ArrangeRequest(
        numBeads: numBeads,
        ratios:   ratios,
        seed: Int(Date().timeIntervalSince1970)   // or nil for random
    )
    do {
        let resp = try await ArrangeService.arrange(req)
        bracelet = resp.beads.map { Bead(colorHex: $0) }
        save()                                    // persist to UserDefaults
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    } catch {
        print("⚠️ /api/arrange failed → local randomise():", error)
        randomise(for: ratios.goal, colors: ratios.colors)
    }
}
```

*No other logic is touched; local randomise is now a fallback.*

---

## 4 · Automatic invocation

In **`ContentView.swift`** update the `.onChange` block:

```swift
.onChange(of: analysisVM.ratios) { newValue in
    guard let r = newValue else { return }
    Task { await braceletVM.arrangeViaServer(using: r) }
}
```

---

## 5 · Manual “随机排珠” button

Replace its action so both code‑paths match:

```swift
Button("随机排珠") {
    if let r = analysisVM.ratios {
        Task { await braceletVM.arrangeViaServer(using: r) }
    }
}
.disabled(analysisVM.ratios == nil)
```

(If the server call fails, local randomise still kicks in.)

---

## 6 · Optional toggle (if you want offline/local option)

Add inside *ContentView* near the speed slider:

```swift
Toggle("服务器排列", isOn: $braceletVM.useServerArrange)
    .toggleStyle(.switch)
    .frame(width: 140)
```

and guard the call:

```swift
if braceletVM.useServerArrange {
    await braceletVM.arrangeViaServer(using: r)
} else {
    braceletVM.randomise(for: r.goal, colors: r.colors)
}
```

*(Wire `@Published var useServerArrange = true` inside `BraceletViewModel`).*

---

## 7 · Nothing else to touch

* `SidePaletteView`, histogram, persistence, animations, drag‑swap ––– all continue to read the `bracelet` array and are automatically fed by the new server data.
* No Info.plist change: we still use the same Vercel domain already whitelisted.

---

### Why this fits cleanly

* **Single responsibility:** server now owns count logic and optional seeding; client only displays.
* **Backward compatibility:** offline mode still works (local randomise).
* **Consistency across platforms:** web and iOS now share one canonical arrangement algorithm.


