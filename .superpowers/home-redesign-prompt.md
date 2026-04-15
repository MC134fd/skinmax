# Home Screen Redesign — Implementation Prompt

You are redesigning the home screen and updating the color palette for an existing iOS app called **Skinmax**. You are working in an Xcode project with 44 Swift files using SwiftUI, SwiftData, and an OpenAI Vision service layer.

**Read the codebase before making changes.** Especially: `CLAUDE.md`, all files in `Core/Design/`, `HomeView.swift`, `HomeViewModel.swift`, `SkinModels.swift`, `DataStore.swift`, `SkinmaxComponents.swift`, and `ContentView.swift`.

---

## Scope — What Changes and What Doesn't

### DO change:
- Color palette in `SkinmaxColors.swift` (new hex values, see Section 1)
- Shadow colors app-wide (currently warm coral-tinted — update to new accent)
- Gradient definitions in `SkinmaxColors.swift`
- `HomeView.swift` — full rebuild to new layout (see Section 2)
- `HomeViewModel.swift` — add new computed properties for the hero row
- New component files under `Features/Home/Components/`
- Scan popup overlay styling in `SkinmaxComponents.swift` — update colors only (keep structure)

### DO NOT change:
- App name (stays "Skinmax" everywhere — code, strings, filenames)
- Folder structure (`Skinmax/` stays as-is on disk)
- Font system (keep Nunito, keep all `.gb*` token names in `Typography.swift`)
- Spacing tokens in `SkinmaxSpacing.swift`
- Tab bar structure (keep 3 tabs: Home, Analytics, Account + floating scan button)
- Scan popup behavior (keep the two frosted bubbles — just update colors)
- Backend: `SkinAnalysisService`, `FoodAnalysisService`, `AnalysisCoordinator`, `DataStore` — don't touch logic
- Data models: `SkinModels.swift`, `LocalCache.swift` — no schema changes
- Camera flow: `FaceScanView`, `CameraPreviewView`, `CameraManager`
- Food log flow: `FoodLogSheet`, `FoodLogSheetViewModel`

---

## Section 1: New Color Palette (Hermès Editorial)

Replace ALL hex values in `SkinmaxColors.swift`. Keep the existing Swift property names. Map old → new as follows:

```
// MARK: - Primary (update hex values, keep property names)
coral         → #C24A1E    // was #FF7A5C — accent orange, CTAs, scan button
peachLight    → #C24A1E opacity 0.15   // was #FFB89E — light accent wash
peachWash     → #F2ECE2    // was #FFD3B8 — secondary background
creamBG       → #FAF6F0    // was #FAF6F2 — main app background
sunnyButter   → #FFF8E8    // keep as-is — sparkle highlights

// MARK: - Supporting
greenGood     → #4A7C59    // was #66BB6A — positive/good
amberFair     → #C49234    // was #FFB74D — moderate
redAlert      → #B23A2C    // was #E57373 — negative/error
hydrationBlue → #4A7CB8    // was #81D4FA — hydration

// MARK: - Text
darkBrown     → #1A1510    // was #2B1F1A — primary text (now "ink")
warmBrown     → #4B3D36    // keep as-is — body text
mediumTaupe   → #6B5C54    // keep as-is
lightTaupe    → #9A8E82    // was #9B8C85 — secondary text (now "stone")
softTan       → #F2ECE2    // was #F0E8E4 — borders, tracks (now "softBg")
white         → .white     // keep

// MARK: - New colors to ADD (new properties)
static let ink = darkBrown                           // alias for readability
static let paper = Color.white                       // card backgrounds
static let stone = lightTaupe                        // alias for readability
static let softBg = softTan                          // alias for readability
static let accent = coral                            // alias for readability
static let accentLight = coral.opacity(0.08)         // accent backgrounds
static let greenLight = greenGood.opacity(0.10)
static let amberLight = amberFair.opacity(0.12)
static let redLight = redAlert.opacity(0.10)
static let blueLight = hydrationBlue.opacity(0.10)
static let purple = Color(hex: "8B5CF6")             // protein/collagen
static let purpleLight = Color(hex: "8B5CF6").opacity(0.10)
static let border = Color(hex: "1A1510").opacity(0.08)
```

**Update gradients:**
```
heroGradient  → LinearGradient from #C24A1E to #C24A1E.opacity(0.7)
buttonGradient → LinearGradient from #C24A1E to #D4623A
```

**Update shadow colors:**
```
cardShadowColor     → Color(hex: "C24A1E").opacity(0.08)
elevatedShadowColor → Color(hex: "C24A1E").opacity(0.12)
buttonGlowColor     → Color(hex: "C24A1E").opacity(0.25)
subtleShadowColor   → Color(hex: "C24A1E").opacity(0.05)
```

**Update traffic light function** — keep the same thresholds but use new hex values:
```
70-100 → greenGood (#4A7C59)
40-69  → amberFair (#C49234)
0-39   → redAlert (#B23A2C)
```

After updating `SkinmaxColors.swift`, do a project-wide search for any hard-coded hex strings (e.g., `Color(hex: "FF7A5C")`) used directly in views — especially in `SkinmaxComponents.swift` shadow calls — and update them to use the token references instead.

---

## Section 2: Home Screen Rebuild — Layout A

Rebuild `HomeView.swift` from scratch. Keep the same `@Environment` injections and callbacks (`onViewFaceResult`, `onViewFoodResult`). The new layout from top to bottom:

### 2a. Top Bar

```
HStack:
  Left VStack:
    - Date: "Monday, April 13" — .gbCaption, lightTaupe (stone)
    - Greeting: "Good morning" — .gbTitleL, darkBrown (ink)
  Spacer
  Right: Streak pill
    - paper background, 1pt border (use `border` token), corner radius 20, padding 5h/10v
    - Content: "🔥 7" where 7 = dataStore.calculateStreak()
    - Text: .gbCaption, darkBrown
```

Remove the old month navigation and WeekDayStrip from the home screen.

### 2b. Hero Row — 2:1 Split

This is the signature layout. A single `HStack(spacing: 8)` with two children.

**Left card — Calorie Ring (takes 2/3 width via `.frame(maxWidth: .infinity)` with a 2:1 ratio using `GeometryReader` or nested frames)**

- `paper` background, 20pt radius, `1pt border` token, padding 16v × 14h
- Top: "CALORIES LEFT" — `.gbOverline`, `lightTaupe`, uppercased, tracking 2
- Center: 130×130 circular ring, 10pt stroke width
  - Track: `softTan` (softBg)
  - Progress: `darkBrown` (ink), lineCap .round, rotated -90°, animated on appear
  - Fraction: `(dailyGoal - consumedCalories) / dailyGoal`
- Inside ring center:
  - Number (remaining cals): `.gbDisplayL`, `darkBrown`
  - Below: "of 2,000 kcal" — `.gbCaption`, `lightTaupe`

**Data source for calories:**
```swift
// In HomeViewModel — add these properties:
let dailyCalorieGoal: Int = 2000
var consumedCalories: Int {
    // Sum calories from today's food scans (real data from DataStore)
    todayFoodScans.reduce(0) { $0 + $1.calories }
}
var caloriesRemaining: Int {
    max(dailyCalorieGoal - consumedCalories, 0)
}
var calorieProgress: Double {
    guard dailyCalorieGoal > 0 else { return 0 }
    return Double(consumedCalories) / Double(dailyCalorieGoal)
}

// Also add (rename existing for clarity):
var todayFoodScans: [FoodScan] {
    dataStore?.foodScans(for: Date()) ?? []
}
```

Note: `consumedCalories` is NOT hard-coded — it pulls from real `FoodScan` entries in SwiftData for today. If no meals are logged, it shows the full goal as remaining.

**Right column — VStack(spacing: 8), takes 1/3 width**

**Top tile — Glow Score:**
- `darkBrown` (ink) background, 18pt radius, padding 12
- Accent glow: 60×60 blurred circle, `coral.opacity(0.20)`, blur radius 16, anchored top-trailing, clipped
- Top: "✦ GLOW" — `.gbOverline`, `lightTaupe`
- Score: `.gbDisplayM`, `creamBG` (cream) color
  - If scan exists: show score number + trend arrow in `greenGood` (e.g., "↑3") at `.gbCaption`
  - If no scan: show "—"
- Bottom: bucket label in `.gbCaption`, `lightTaupe`
  - 0..<40 → "Low", 40..<60 → "Fair", 60..<75 → "Good", 75..<90 → "Great", 90...100 → "Glowing"
  - No scan: "Scan to start"

**Data source:** Use the existing `latestScan` property on `HomeViewModel` which calls `dataStore?.latestSkinScan()`. The `SkinScan` model already has a `glowScore: Double`. No need to compute it from metrics.

**Bottom tile — Hydration (placeholder):**
- `blueLight` background, 18pt radius, padding 12, 1pt border of `hydrationBlue.opacity(0.20)`
- Top: "💧 WATER" — `.gbOverline`, `hydrationBlue`
- Amount: "1.2" in `.gbTitleL`, `hydrationBlue` + "/ 2.5L" in `.gbCaption`, `hydrationBlue.opacity(0.70)`
- Bottom: 8 dot segments — row of 8 `RoundedRectangle(cornerRadius: 2)` each ~height 4pt, 2pt spacing. First 3 solid `hydrationBlue`, rest `hydrationBlue.opacity(0.20)`.

```swift
// In HomeViewModel — add:
struct HydrationPlaceholder {
    let consumed: Double   // liters
    let goal: Double
    let glasses: Int       // out of 8
}
// TODO: Wire to a real hydration tracking feature later
let hydration = HydrationPlaceholder(consumed: 1.2, goal: 2.5, glasses: 3)
```

### 2c. Skin Nutrients Row (hard-coded placeholders)

Below hero row, 12pt spacing.

- Section header: `HStack` — left: "SKIN NUTRIENTS" in `.gbOverline`, `lightTaupe`, tracking 2. Right: "SWIPE →" in `.gbOverline`, `lightTaupe`.
- `ScrollView(.horizontal, showsIndicators: false)` with `HStack(spacing: 6)`
- 3 nutrient cards, each ~90pt wide:

| Label | Value | Target | Descriptor | Color | Pct |
|-------|-------|--------|------------|-------|-----|
| PROTEIN | 48 | 92g | Collagen fuel | purple / purpleLight | 52% |
| OMEGA-3 | 1.2 | 2g | Glow booster | greenGood / greenLight | 60% |
| SUGAR | 18 | 25g | Breakout flag | redAlert / redLight | 72% |

Each card:
- Tinted background (e.g., `purpleLight`), 14pt radius, padding 10v × 11h
- Top: label in `.gbOverline`, nutrient color
- Middle: value in `.gbTitleM`, nutrient color + "/target" in `.gbCaption`, nutrient color at 70%
- Third line: descriptor in `.gbOverline` size 8, nutrient color at 80%
- Bottom: 3pt progress bar with `Color.black.opacity(0.06)` track, nutrient color fill

```swift
// In HomeViewModel — add:
struct SkinNutrient: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let target: String
    let descriptor: String
    let color: Color
    let lightColor: Color
    let progress: Double
}

// TODO: Derive from FoodScan entries when the model supports these nutrients
static let skinNutrients: [SkinNutrient] = [
    SkinNutrient(label: "PROTEIN", value: "48", target: "92g", descriptor: "Collagen fuel",
                 color: SkinmaxColors.purple, lightColor: SkinmaxColors.purpleLight, progress: 0.52),
    SkinNutrient(label: "OMEGA-3", value: "1.2", target: "2g", descriptor: "Glow booster",
                 color: SkinmaxColors.greenGood, lightColor: SkinmaxColors.greenLight, progress: 0.60),
    SkinNutrient(label: "SUGAR", value: "18", target: "25g", descriptor: "Breakout flag",
                 color: SkinmaxColors.redAlert, lightColor: SkinmaxColors.redLight, progress: 0.72),
]
```

### 2d. Today's Meals List

Section label: "TODAY · {count} MEALS" — `.gbOverline`, `lightTaupe`, tracking 2, 12pt top spacing.

Query: `dataStore.foodScans(for: Date())` — this already exists. Sort by `createdAt` ascending.

Each meal row:
- `paper` background, 12pt radius, `1pt border` token, padding 9v × 12h, 5pt bottom margin
- Left: 36×36 square, `softTan` background, 9pt radius, 🍽 emoji centered
- Middle: HStack with 5×5 colored dot (green ≥7, amber 4..<7, red <4 skin impact), then meal name in `.gbCaption` semibold weight, `darkBrown`. Below: "{calories} cal · {time}" in `.gbCaption`, `lightTaupe`
- Right: skin impact score in `.gbBodyL`, colored to match the dot

**Empty state** (no food scans today):
- `paper` bg, dashed border (`lightTaupe.opacity(0.30)`, dash pattern [6,3]), 12pt radius
- Center: "No meals logged yet" in `.gbBodyM`, `lightTaupe`
- Below: small pill button "Scan your first meal" — `coral` background, white text, `.gbCaption`, 100pt radius, padding 8v/16h. On tap: trigger the existing scan popup (`showScanPopup = true` — pass this binding down or use a callback).

### 2e. Keep the Analysis-in-progress card

Keep the existing `AnalysisHomeCard` component — it shows during active scans. Just make sure it uses design tokens (it already does via `SkinmaxColors` and `SkinmaxSpacing`). Place it between the top bar and the hero row, same as current position.

### 2f. Remove from Home Screen

Remove these sections that exist in the current `HomeView`:
- Month navigation (chevron left/right with month name)
- WeekDayStrip (week day selector)
- Glow Score Card (old horizontal layout — replaced by hero row)
- Metric Carousel (circle metric cards — this data is available on face scan result screen)
- Dismissible Insight Card (can be added back later)

---

## Section 3: New Files to Create

Create these under `Skinmax/Features/Home/Components/`:

1. **CalorieRingCard.swift** — The left 2/3 card from section 2b
2. **GlowScoreTile.swift** — The top-right dark tile from section 2b
3. **HydrationTile.swift** — The bottom-right blue tile from section 2b
4. **SkinNutrientCard.swift** — Single nutrient card from section 2c
5. **MealRow.swift** — Single meal row from section 2d

Each component should:
- Accept its data via init parameters (not reach into environment directly)
- Use only `SkinmaxColors`, `.gb*` fonts, and `SkinmaxSpacing` tokens
- Be a plain `View` struct with no business logic

Also add to `HomeViewModel.swift`:
- `HydrationPlaceholder` struct
- `SkinNutrient` struct + static array
- `consumedCalories`, `caloriesRemaining`, `calorieProgress` computed properties
- `todayFoodScans` computed property
- `glowScoreBucketLabel` computed property

---

## Section 4: Update Other Screens for New Palette

Since `SkinmaxColors.swift` hex values are changing, every screen that uses these tokens will automatically pick up the new palette. But verify these screens still look correct:

- `ContentView.swift` — tab bar uses `SkinmaxColors.coral` and gradient. Check it looks right with `#C24A1E`.
- `SkinmaxComponents.swift` — `GlassTabBar`, `ScanPopupOverlay`, `ActionButton`, etc. all reference color tokens. Verify.
- `FaceScanResultView.swift` — dark card gradient uses `darkSurface` and `darkMid`. Verify.
- `FoodScanResultView.swift` — uses score colors and card shadows. Verify.
- `AccountView.swift`, `ScanHistoryView.swift`, `AnalyticsContainerView.swift` — spot check.

Fix any view where the new palette makes something unreadable (e.g., dark text on dark background, or accent that's too dark on a tinted surface).

---

## Section 5: Implementation Phases (commit after each)

### Phase 1: Design tokens
- Update `SkinmaxColors.swift` with new hex values and new color aliases
- Update shadow colors, gradients, traffic light function
- Search for hard-coded hex strings in all `.swift` files and replace with token references
- Build and verify — all screens should compile and render with new colors
- **Commit:** "Update color palette to Hermès editorial theme"

### Phase 2: Home screen components
- Create the 5 new component files in `Features/Home/Components/`
- Add placeholder structs and new computed properties to `HomeViewModel.swift`
- **Commit:** "Add home screen components for hero row and nutrients"

### Phase 3: Home screen assembly
- Rebuild `HomeView.swift` with the new layout (top bar → analysis card → hero row → nutrients → meals)
- Wire up empty states and scan button callback
- **Commit:** "Rebuild home screen with calorie ring hero layout"

### Phase 4: Verify all screens
- Check every other screen renders correctly with the new palette
- Fix any contrast/readability issues
- **Commit:** "Fix palette issues across all screens"

---

## Hard Constraints

1. **No renaming.** Don't rename Skinmax to anything. Don't rename files, folders, types, or user-facing strings.
2. **No model changes.** Don't touch `SkinModels.swift`, `LocalCache.swift`, or `DataStore.swift`.
3. **No service changes.** Don't touch `SkinAnalysisService`, `FoodAnalysisService`, `AnalysisCoordinator`, `InsightEngine`.
4. **Keep Nunito.** Use only `.gb*` font tokens. Never use `.system(...)` or raw `.custom()`.
5. **Keep tab structure.** 3 tabs + floating scan button. Don't add or remove tabs.
6. **Keep scan popup.** Don't restyle the `ScanPopupOverlay` layout — only the colors change automatically via tokens.
7. **Calories are real data.** `consumedCalories` must sum from actual `FoodScan` entries in SwiftData for today. Not hard-coded.
8. **Glow Score is real data.** Pull from `dataStore.latestSkinScan()?.glowScore`. The `SkinScan` model already stores `glowScore: Double`. Don't try to compute it from individual metrics.
9. **Hydration and nutrients are placeholders.** Hard-code them with `// TODO` comments. No fake DataStore queries.
10. **Must compile.** After each phase, the project must build with zero errors. Fix any issues before moving on.

---

## Data Model Reference (read-only, don't modify)

```swift
// SkinScan has:
//   .glowScore: Double (0-100)
//   .metrics: [SkinMetric] (each has .type: SkinMetricType, .score: Double)
//   .imageURL: String?
//   .aiInsight: String
//   .overallMessage: String
//   .createdAt: Date

// FoodScan has:
//   .name: String
//   .skinImpactScore: Double (1-10)
//   .calories: Int
//   .protein: Double
//   .fat: Double
//   .carbs: Double
//   .benefits: [String]
//   .skinEffects: [SkinEffect]
//   .createdAt: Date

// DataStore has:
//   .foodScans(for: Date) -> [FoodScan]
//   .latestSkinScan() -> SkinScan?
//   .calculateStreak() -> Int
//   .skinScans(for: Date) -> [SkinScan]
```

---

## Out of Scope

- Water logging persistence or UI beyond the placeholder tile
- Real derivation of Omega-3 / Sugar from food scans
- Paywall, StoreKit, onboarding, auth
- App Store assets
- Changes to OpenAI prompts or service layer
- SwiftData model changes
- Tab bar restructuring
- App renaming
