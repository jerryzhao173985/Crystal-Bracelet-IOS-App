### Crystal Bracelet iOS — Development Log & Architecture Guide  
*(April 2025 — current state)*

---

#### 1 · High‑level Architecture
| Layer | Purpose | Key Files |
|-------|---------|-----------|
| **Backend (Vercel)** | Serves static React site **+** two serverless functions.<br>• `/api/beads` – returns default bead colours.<br>• `/api/astro` – orchestrates DeepSeek + OpenAI, returns `analysis + ratios`. | `api/beads.js`, `api/astro.js`, `vercel.json` |
| **iOS App (SwiftUI)** | Native client that visualises and edits a bracelet. | `Models/ • Services/ • ViewModels/ • Views/` |

Communication is pure HTTPS JSON; **no sockets** → easier App Store review & caching.

---

#### 2 · Client‑side Data Flow

```
┌──── inputs (DOB / time / gender / keys) ────┐
│ user taps “开始分析”                         │
└─────────────────────────────────────────────┘
            ▼  POST api/astro (APIService)
            JSON { analysis, ratios }
            ▼
AnalysisViewModel.ratios (current+goal+colors)
            ▼
BraceletViewModel.randomise()
            ▼
View updates:
  • BraceletCanvasView  → bead colours
  • ElementHistogram    → dual‑bar chart
  • AnalysisPanel       → Markdown text
  • SidePalette         → dynamic palette
```

*Errors* bubble up through `Result` and show an `alert`.

---

#### 3 · Model Contracts

```swift
struct ElementRatio   { var metal, wood, water, fire, earth: Double }
struct ElementColors  { var metal, wood, water, fire, earth: String } // #RRGGBB

struct AnalysisResponse: Decodable {
    var analysis: String            // Markdown
    var ratios: struct {
        var current: ElementRatio
        var goal:    ElementRatio
        var colors:  ElementColors
    }
}

struct Bead: Identifiable {
    let id = UUID()                 // stable ForEach key
    var colorHex: String            // CSS‑hex
}
```

---

#### 4 · Bracelet Logic

| Feature | Implementation |
|---------|----------------|
| **Non‑destructive resize** | `resizeBracelet(to:)` only appends or truncates, preserving existing colours. |
| **Randomise to goal** | Float‑counts → floor + remainder fixing → Fisher‑Yates shuffle. |
| **Animations** | *FlashShuffle*: ≤ `numBeads×2` iterations with `Task.sleep`. <br>*Growth*: counts up to 20 beads over 5 s. |
| **Persistence** | `UserDefaults` stores `[Bead]` (Codable) on every mutation; loaded at `init()`. |

---

#### 5 · UI Components

| View | Notes |
|------|-------|
| **BraceletCanvasView** | Polar‑to‑Cartesian layout; each bead interactive. |
| **SidePaletteView** | `.thinMaterial` blur, tap/drag, auto‑dismiss on background tap. |
| **ElementHistogramView** | `Charts` dual‑bar with opacity + annotation labels. |
| **AnalysisPanelView** | `MarkdownUI` themed `.gitHub`, collapsible gradient mask. |
| **ContentView** | Hosts sections, haptics, alerts, navigation. |

Visual choices (blur, rounded rectangles, tactile spacing) echo modern iOS design for instant familiarity.

---

#### 6 · Networking & Error Handling

* `APIService` validates:  
  * HTTPS status 200‑299  
  * `Content‑Type: application/json`  
  * Debug‑printed first 200 chars of HTML on error.

* On error → `AnalysisViewModel` sets `.errorMessage` → `Alert`.

---

#### 7 · Timeline of Key Enhancements (excerpt)

| Date | Change |
|------|--------|
| **Apr 16** | Ported React logic → SwiftUI skeleton; basic API hookup. |
| **Apr 17** | Added randomise & growth animations; Date/Time picker bug fixed. |
| **Apr 18** | Floating palette (tap + drag), colour‑persistence on bead‑resize, haptics, dark‑mode polish. |

---

#### 8 · Ideas for Next Iteration

| Area | Enhancement | Effort |
|------|-------------|--------|
| **Export** | Share‑sheet: save bracelet SVG/PNG to Files / Photos. | ⭐⭐ |
| **Watch Companion** | Display bracelet and percentages on Apple Watch (WidgetKit + WatchConnectivity). | ⭐⭐⭐ |
| **AR Preview** | QuickLook USDZ bracelet on wrist using RealityKit.* | ⭐⭐⭐⭐ |
| **Offline Caching** | Cache last `analysis` so the app opens full UI offline. | ⭐ |
| **Colour‑blind A11y** | Pattern overlays or voice‑over labels “红色 Fire 30 %”. | ⭐⭐ |

\*Would require generating a 3‑D torus of spheres in USD.

---

#### 9 · Deployment Tips

1. **Vercel secrets** → name them `DEEPSEEK_KEY` & `OPENAI_KEY`; the iOS app needn’t embed keys (user‑supplied).  
2. Use **`vercel env pull .env.local`** locally; the serverless functions read `process.env`.  
3. In Xcode, add ATS exception only for `http://localhost:5050` during development.

---

### 🎉  Outcome

We reproduced every feature of the original web customiser **natively**:

* fluid drag‑and‑drop editing  
* instant analysis visualisation  
* lively animations & haptics  
* elegant, iOS‑consistent aesthetics.

