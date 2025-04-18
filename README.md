# Crystal‑Bracelet Customiser Native iOS app from React + Node 

## Summary

This document chronicles the migration of a Crystal Bracelet Customiser web application (built with React and Node.js) to a fully native iOS application using SwiftUI. It details the complete process, including architecture design (leveraging Vercel for backend serverless functions handling astrology/color analysis via DeepSeek/OpenAI), client-side data flow, state management in Swift using ViewModels, and UI implementation with native features like an interactive circular bracelet canvas, drag-and-drop bead swapping, a dynamic side palette, and animations. The log also covers persistent storage using `UserDefaults`, networking strategies, solutions to specific bugs (like date picker issues and duplicate IDs), and advanced techniques employed. The final result is a robust, interactive, and visually polished iOS app with a reproducible development path.

## Table of Contents

* [Architecture](#architecture)
    * [1 · High‑level Architecture](#1--highlevel-architecture)
    * [2 · Client‑side Data Flow](#2--clientside-data-flow)
* [1 · Backend (Vercel)](#1--backend-vercel)
* [2 · iOS App — Entry & Infrastructure](#2--ios-app--entry--infrastructure)
* [3 · Model Layer](#3--model-layer)
* [4 · View‑Models (business logic)](#4--viewmodels-business-logic)
    * [4.1 `BraceletViewModel.swift`](#41-braceletviewmodelswift)
    * [4.2 `AnalysisViewModel.swift`](#42-analysisviewmodelswift)
* [5 · Views](#5--views)
* [6 · Bug Fixes / Edge‑cases](#6--bug-fixes--edgecases)
* [7 · Advanced Operations](#7--advanced-operations)
* [8 · How It All Fits](#8--how-it-all-fits)
* [Result](#result)
* [Comprehensive Development & Deployment Summary](#comprehensive-development--deployment-summary)
    * [1 · Input & Request Pipeline](#1--input--request-pipeline)
    * [2 · Vercel Deployment Role](#2--vercel-deployment-role)
    * [3 · Client Data Flow & Storage](#3--client-data-flow--storage)
    * [4 · Visualisation Techniques](#4--visualisation-techniques)
    * [5 · Interactive Editing](#5--interactive-editing)
    * [6 · Animations](#6--animations)
    * [7 · Debug & Error Instrumentation](#7--debug--error-instrumentation)
    * [8 · Key Lessons](#8--key-lessons)
    * [9 · Future Enhancements (necessary, not ornamental)](#9--future-enhancements-necessary-not-ornamental)

---

We ported from a React + Node.js crystal bracelet customizer to a robust, native SwiftUI iOS app, from initial structured user input, through API communication with Vercel serverless endpoints (for astrology and color analysis), to advanced state handling and UI design in Swift. The log details technical challenges (like date picker bugs, duplicate IDs, and preserving bead colors), their solutions, and significant UI/UX enhancements—including native animations, interactive bracelets, a floating side palette, and persistent storage. The final codebase achieves seamless user interaction, real-time visualization, and reliable backend integration.

## Architecture

### 1 · High‑level Architecture
| Layer | Purpose | Key Files |
|-------|---------|-----------|
| **Backend (Vercel)** | Serves static React site **+** two serverless functions.<br>• `/api/beads` – returns default bead colours.<br>• `/api/astro` $
| **iOS App (SwiftUI)** | Native client that visualises and edits a bracelet. | `Models/ • Services/ • ViewModels/ • Views/` |

Communication is pure HTTPS JSON; **no sockets** → easier App Store review & caching.

---

### 2 · Client‑side Data Flow

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


## 1 · Backend (Vercel)

| File | What it does | Highlights & Notes |
|------|--------------|--------------------|
| **`vercel.json`** | Declares one **static build** (legacy CRA) and two **Node lambdas**. Routes map `/api/*` to the lambdas and fall back to `index.html` for the SPA. | `"installCommand": "npm install"` solved an NPM CI lockfile mismatch. |
| **`api/beads.js`** | Returns the default palette (`[{id,color}]`). Only supports `GET`. | Synchronous handler; tiny, but lets the iOS app start with colours even without analysis. |
| **`api/astro.js`** | The heavy lambda. 1️⃣ Builds a Chinese prompt, 2️⃣ calls **DeepSeek‑Chat**, 3️⃣ calls **OpenAI Responses** to extract structured JSON, 4️⃣ returns `{analysis, ratios}`. | `module.exports.config = { maxDuration: 60 }` extends execution to 60 s, avoiding 10 s Vercel time‑outs. |
| **`routes/beads.js`** & **`server.js`** | Only used for local React dev; irrelevant in production but kept for parity. |

---

## 2 · iOS App — Entry & Infrastructure

| File | Core Content | Why it matters |
|------|--------------|----------------|
| **`CrystalBraceletIOSAppApp.swift`** | Declares `@main`. Instantiates **`BraceletViewModel`** and **`AnalysisViewModel`** and injects them via `.environmentObject`. | Centralises shared state the SwiftUI tree relies on. |
| **`APIService.swift`** | Generic networking layer (async/await). Key pieces: <br>• `baseURL` constant<br>• `validate(_:data:url:)` – checks HTTP 200‑299 *and* JSON Content‑Type, prints first 200 chars of HTML if wrong.<br>• typed `get` / `post` wrappers. | Removes silent failures; surfaces wrong paths (HTML 404 page) quickly. |
| **`Color+Hex.swift`** | `init(hex:)` converts `#RRGGBB` or `#AARRGGBB` into `Color`. | Used by every bead and histogram bar. |
| **`FisherYatesShuffle.swift`** | `mutating func fisherYatesShuffle()` on `Array` | Guarantees unbiased random bead order. |

---

## 3 · Model Layer

| File | Structures | Notes |
|------|-----------|-------|
| **`Bead.swift`** | `struct Bead: Identifiable` – stores **`colorHex`** and a fresh `UUID()` so each copy has a unique identity (fixes duplicate‑ID warnings). |
| **`ElementRatio.swift`** | Five doubles (金 木 水 火 土). |
| **`AnalysisResponse.swift`** | Mirrors the JSON from `/api/astro`. Nested `RatioContainer` holds `current`, `goal`, `colors`. |

---

## 4 · View‑Models (business logic)

### 4.1 `BraceletViewModel.swift`

* **State**  
  `@Published var bracelet: [Bead]`  
  `@Published var numBeads`, `speed`, `isAnimating`, `growthAnimating`

* **Key routines**

| Function | Algorithm |
|----------|-----------|
| `resizeBracelet(to:)` | Append blanks or truncate **without** touching existing coloured beads. |
| `randomise(for:goal colors:)` | 1. Compute ideal counts `ratio × n /100` → floor. 2. Distribute remainders to hit `n`. 3. Create `Bead` list, shuffle, pad. |
| `flashRandomise` | Loops ≤ `numBeads×2` times with `Task.sleep`. Speed multiplies interval. |
| `growBracelet` | Rebuilds array length 1→20 over 5 s (speed‑aware). |

Persistent storage: `bracelet` encodes to `Data` in `UserDefaults` on every change; on launch the stored array loads if present.

### 4.2 `AnalysisViewModel.swift`

* Holds raw user inputs (`Date`, `String` time, etc.).  
* `analyse()` builds `AstrologyRequest`, calls `AstrologyService.analyse()`, then publishes `analysisText` and `ratios`.  
* On success triggers haptic and an optional callback to `BraceletViewModel` (via `.onChange` in the View).

---

## 5 · Views

| File | Purpose | Implementation nuggets |
|------|---------|------------------------|
| **`ContentView.swift`** | Top‑level UI (DatePicker, Stepper, Slider, Buttons, subviews). | Disables Analyse button until inputs + keys are filled. Listens for `ratios` change to auto‑randomise bracelet. |
| **`BraceletCanvasView.swift`** | Renders beads in a circle, handles tap, drag‑swap, drop from palette, and shows **SidePalette**. | `position(for:index,total,size)` converts polar → cartesian. Drop uses `onDrop(of:[.plainText])`. |
| **`BeadView.swift`** | Single coloured circle with outline + shadow. |
| **`SidePaletteView.swift`** | Slim vertical bar of colour dots. Tap or drag to use. Uses `.thinMaterial` blur and `transition(.scale+opacity)`. |
| **`ElementHistogramView.swift`** | Dual‑bar chart (swift‑charts). Current bars 40 % opacity; goal bars full; `annotation` text shows `%`. |
| **`AnalysisPanelView.swift`** | Collapsible Markdown (GitHub theme). Gradient mask hides overflow; “展开 / 收起” toggles height; copy report button writes combined JSON to clipboard. |

---

## 6 · Bug Fixes / Edge‑cases

| Issue | Root cause | Fix |
|-------|------------|-----|
| DatePicker kept resetting | storing DOB as `String`; SwiftUI couldn’t round‑trip. | Changed to `Date` + formatter for server. |
| Duplicate bead IDs | `Array(repeating:Bead(...))` reused same UUID. | Each loop creates a new `Bead`. |
| Colours lost on bead‑count change | the old `regenerateBracelet()` recreated whole array. | Replaced with `resizeBracelet()` preserving prefix. |
| Analyse button freezing | double‑slash path hit Vercel 308 → HTML, JSON decode hung. | Removed leading `/`, added `validate()`. |
| Palette dismissed too slowly | async `setTimeout` style timer. | Swift `withAnimation + onTap` hide immediately. |

---

## 7 · Advanced Operations

* **OpenAI Responses** schema building inside `api/astro.js` ensures the JSON arrives in deterministic shape; iOS decoding has zero runtime `try?`.
* **Drag & Drop** uses **`NSItemProvider`** with plain text HEX, meaning no custom UTType is required.
* **Concurrency**: All animations run in **detached tasks** so the main run‑loop stays responsive.
* **Haptic coordination**: A single `UIImpactFeedbackGenerator` is cached to avoid Taptic Engine throttling.

---

## 8 · How It All Fits

```
DeepSeek → ratios.colors  ┐
                           ├──▶ SidePaletteView  – chosen HEX → Bead.colorHex
                           │
                           └──▶ BraceletViewModel.randomise()
                                  │
                                  ├─ bracelet array → BraceletCanvasView
                                  │                    (tap ⟷ palette, drag‑swap)
                                  └─ ratios → ElementHistogramView
```

Every component observes a single source of truth (`@Published` state), so updates are immediate and glitch‑free.

---

## Result

The codebase now forms a cohesive, idiomatic SwiftUI application that:

* **Respects** native interaction metaphors (tap, drag, haptics, blur).  
* **Handles** API latency gracefully (placeholder beads, speed slider).  
* **Preserves** user work (non‑destructive resize, persistence).  
* **Extends** easily—new bead shapes, AR preview, or Watch OS can plug into the existing models without rewrites.

---

### Comprehensive Development & Deployment Summary  

Our objective was to transplant a React + Node “Crystal‑Bracelet Customiser” into a fully native SwiftUI experience while preserving every interaction and adding iOS polish. Below is a condensed record of the architecture, critical problems encountered, and their resolutions.

---

#### 1 · Input & Request Pipeline  
The user supplies **date of birth, birth time, gender, DeepSeek key, OpenAI key, bead‑count**. Pressing **开始分析** triggers a Swift async task that:

1. Serialises inputs into an `AstrologyRequest` struct.  
2. POSTs to **`/api/astro`** on Vercel via `APIService`.  
3. `api/astro.js` composes a Chinese prompt, calls DeepSeek‑Chat, pipes the markdown to OpenAI Responses, and returns `{analysis, ratios{current,goal,colors}}`.

Crucial bug: initial paths had double slashes and HTML 308 responses (fixed by removing leading “/” and adding status/Content‑Type validation).

---

#### 2 · Vercel Deployment Role  
`vercel.json` bundles the unused CRA, hosts two Lambda functions, and handles CORS implicitly, giving us HTTPS endpoints with zero server maintenance. iOS builds simply set  
```swift
var baseURL = "https://<project>.vercel.app"
```  
No embedded keys—users enter theirs, avoiding App‑Store rejection.

---

#### 3 · Client Data Flow & Storage  
`AnalysisViewModel` publishes the server response. `BraceletViewModel` observes:

* `ratios.goal` → computes per‑element bead counts with floor+remainder correction.  
* Shuffles via Fisher‑Yates for perceptual distribution.  
* Persists `[Bead]` (UUID + HEX) in `UserDefaults`.  

Resizing bead count now **appends/truncates** instead of regenerating, preserving colours—achieved by replacing `regenerateBracelet()` with `resizeBracelet()`.

---

#### 4 · Visualisation Techniques  
* **BraceletCanvas**: polar layout → `CGPoint` on a ring; `BeadView` is a coloured `Circle`.  
* **Dual‑bar Histogram**: `Charts` `BarMark`, current bars 40 % opacity, goal bars full; inline percentage annotations.  
* **Markdown Analysis**: `MarkdownUI` with GitHub theme, gradient‑masked collapse.

Haptic feedback (`UIImpactFeedbackGenerator`) accompanies bead drop, palette select, and analysis completion.

---

#### 5 · Interactive Editing  
* **Drag‑to‑swap** – detects nearest bead on drag‑end (< 40 pt) and swaps colours.  
* **Floating Side Palette** – tap a bead, palette appears at an offset using local geometry; tap or drag a colour dot (NSItemProvider HEX) to fill. Palette colours switch instantly from defaults to DeepSeek ones when `ratios.colors` arrives.

Main pitfalls solved:
* duplicate UUID warnings (each `Bead` now gets a fresh `UUID()` on creation).  
* palette dismiss logic with background tap & `withAnimation(.spring())`.

---

#### 6 · Animations  
* **Flash Shuffle**: ≤ `numBeads×2` iterations, interval = `200 ms/ speed`, live‑mutable via `@State speed`.  
* **Growth**: bead array grows 1→20 over 5 s; duration scales with speed slider.  
Both run on structured concurrency (`Task.sleep`), cancel automatically if view disappears.

Suggested native add‑ons: `matchedGeometryEffect` for bead morphing, `TimelineView` for continuous rotation preview.

---

#### 7 · Debug & Error Instrumentation  
`APIService.validate` prints  
```
↩️ 200 https://…/api/astro   content‑type: application/json
⚠️ Unexpected non‑JSON … <html>
```  
and throws custom `APIError`, surfaced via `Alert`. This prevented silent hangs and made every network fault immediately visible.

---

#### 8 · Key Lessons  
* **Preserve state, don’t regenerate** – users value colour work; array resizing with minimal mutation is essential.  
* **Guard against HTML responses** even on JSON routes—Vercel 308/404 pages break decoders.  
* **Side palettes** should spring from interaction point, not fixed edges, for one‑hand reachability.  
* Animations need **speed controls** for accessibility and user preference.  
* Early **UserDefaults persistence** eliminates the perceived “blank slate” on cold launch.

---

#### 9 · Future Enhancements (necessary, not ornamental)  
1. **Bracelet image export** (SwiftUI `ImageRenderer` → PNG) for social sharing.  
2. **Watch OS glance** showing today’s ideal five‑element balance and bracelet preview.  
3. **ARKit wrist overlay** for real‑world try‑on (USD torus of spheres).  
4. **Colour‑blind patterns** overlay on beads & histogram bars.  
5. **Server‑side caching** of identical `AstrologyRequest` keyed by DOB + time to cut DeepSeek costs.

---


