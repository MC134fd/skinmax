# Skin Nutrients Redesign — Implementation Prompt

You are updating the skin nutrients section of the home screen and adding 3 new fields to the food scan pipeline for an existing iOS app called **Skinmax**. You are working in an Xcode project with SwiftUI, SwiftData, and an OpenAI Vision service layer.

**Read the codebase before making changes.** Especially: `CLAUDE.md`, `SkinModels.swift`, `FoodAnalysisService.swift`, `LocalCache.swift`, `DataStore.swift`, `HomeView.swift`, `HomeViewModel.swift`, `SkinNutrientCard.swift`, `FoodScanResultView.swift`, `MockData.swift`, `GlowbiteColors.swift`.

---

## Scope — What Changes and What Doesn't

### DO change:
- `GlowbiteColors.swift` — add 6 new nutrient signature color pairs (12 tokens)
- `SkinModels.swift` — add `fiber`, `sugar`, `sodium` to `FoodScan`
- `FoodAnalysisService.swift` — update AI prompt JSON schema + parse 3 new fields
- `LocalCache.swift` — add `fiber`, `sugar`, `sodium` to `CachedFoodScan` + both init/toFoodScan
- `MockData.swift` — add `fiber`, `sugar`, `sodium` to sample `FoodScan` entries
- `HomeView.swift` — replace skin nutrients `ScrollView` with paged `TabView` + dot indicators
- `HomeViewModel.swift` — replace hardcoded `SkinNutrient` with real-data computed properties + traffic light zone logic + nutrient configs with signature colors
- `SkinNutrientCard.swift` — make cards wider (fill available width), two-layer color system (signature + traffic light bar)
- `FoodScanResultView.swift` — update nutrition grid to show all 6 nutrients + calories (7 items)

### DO NOT change:
- App name, folder structure, font system, spacing tokens
- Tab bar structure, scan popup behavior
- `SkinAnalysisService.swift`, `AnalysisCoordinator.swift`, `InsightEngine.swift`
- `SkinScan` model (only `FoodScan` changes)
- Camera flow, face scan flow
- `CalorieRingCard.swift`, `GlowScoreTile.swift`, `HydrationTile.swift`, `MealRow.swift`
- `DataStore.swift` — don't touch query logic (the existing `foodScans(for:)` returns `[FoodScan]` which will automatically include the new fields once the model is updated)

---

## Section 1: FoodScan Model Changes

### 1a. Update `SkinModels.swift` — `FoodScan` struct

Add 3 new properties. Keep all existing properties. The new `FoodScan` should be:

```swift
struct FoodScan: Codable, Identifiable, Equatable {
    static func == (lhs: FoodScan, rhs: FoodScan) -> Bool { lhs.id == rhs.id }

    let id: UUID
    let name: String
    let skinImpactScore: Double
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let fiber: Double      // NEW
    let sugar: Double      // NEW
    let sodium: Double     // NEW — stored in grams (e.g. 1.5 = 1500mg)
    let benefits: [String]
    let skinEffects: [SkinEffect]
    let photoData: Data?
    let aiTip: String?
    let createdAt: Date

    init(id: UUID = UUID(), name: String, skinImpactScore: Double, calories: Int,
         protein: Double, fat: Double, carbs: Double,
         fiber: Double = 0, sugar: Double = 0, sodium: Double = 0,
         benefits: [String] = [], skinEffects: [SkinEffect] = [],
         photoData: Data? = nil, aiTip: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.skinImpactScore = min(10, max(1, skinImpactScore))
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.benefits = benefits
        self.skinEffects = skinEffects
        self.photoData = photoData
        self.aiTip = aiTip
        self.createdAt = createdAt
    }
}
```

The new fields default to `0` so existing `FoodScan` init call sites (MockData, etc.) won't break.

### 1b. Update `LocalCache.swift` — `CachedFoodScan`

Add 3 new `@Model` properties:

```swift
@Model
class CachedFoodScan {
    // ... existing properties ...
    var fiber: Double       // NEW
    var sugar: Double       // NEW
    var sodium: Double      // NEW

    init(from scan: FoodScan) {
        // ... existing assignments ...
        self.fiber = scan.fiber
        self.sugar = scan.sugar
        self.sodium = scan.sodium
    }

    func toFoodScan() -> FoodScan {
        // ... existing decode ...
        return FoodScan(
            id: id,
            name: foodName,
            skinImpactScore: skinImpactScore,
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            benefits: benefits,
            skinEffects: skinEffects,
            photoData: nil,
            aiTip: aiTip,
            createdAt: date
        )
    }
}
```

**IMPORTANT:** Since `CachedFoodScan` is a SwiftData `@Model`, adding new non-optional properties requires a default value. Initialize them to `0` in the property declaration:
```swift
var fiber: Double = 0
var sugar: Double = 0
var sodium: Double = 0
```
This allows SwiftData lightweight migration to handle existing cached records (they'll get `0` for the new fields).

### 1c. Update `MockData.swift`

Add the 3 new fields to both sample food scans:

```swift
static let foodScans: [FoodScan] = [
    FoodScan(
        name: "Salmon Bowl",
        skinImpactScore: 8.5,
        calories: 480,
        protein: 35,
        fat: 18,
        carbs: 42,
        fiber: 6,
        sugar: 8,
        sodium: 0.62,
        benefits: ["Rich in Omega-3 for skin elasticity", "High protein for collagen production"],
        skinEffects: [
            SkinEffect(metricType: .hydration, direction: .improved, description: "Healthy fats support moisture barrier"),
            SkinEffect(metricType: .redness, direction: .improved, description: "Omega-3s reduce inflammation"),
        ]
    ),
    FoodScan(
        name: "Green Smoothie",
        skinImpactScore: 9.0,
        calories: 220,
        protein: 8,
        fat: 5,
        carbs: 38,
        fiber: 5,
        sugar: 22,
        sodium: 0.04,
        benefits: ["Vitamin C boosts collagen", "Antioxidants fight free radicals"],
        skinEffects: [
            SkinEffect(metricType: .texture, direction: .improved, description: "Vitamin C brightens skin"),
            SkinEffect(metricType: .darkSpots, direction: .improved, description: "Antioxidants fade dark spots"),
        ]
    ),
]
```

---

## Section 2: AI Prompt Update

### 2a. Update `FoodAnalysisService.swift` — System Prompt

In the `systemPrompt` string inside `analyzeFood(image:foodName:)`, update the example JSON to include the 3 new fields:

```json
{
  "food_name": "Confirmed or corrected food name",
  "skin_impact_score": 7.5,
  "calories": 480,
  "protein": 35.0,
  "fat": 22.0,
  "carbs": 38.0,
  "fiber": 6.0,
  "sugar": 12.0,
  "sodium": 0.62,
  "benefits": [
    "Omega-3 fatty acids (reduces inflammation and redness)",
    "Vitamin E (supports skin cell repair)",
    "Healthy fats (boosts skin hydration)"
  ],
  "skin_effects": [
    {
      "metric_type": "hydration",
      "direction": "improved",
      "description": "Rich in healthy fats that support skin moisture barrier"
    },
    {
      "metric_type": "redness",
      "direction": "improved",
      "description": "Omega-3s have anti-inflammatory properties"
    }
  ],
  "ai_tip": "Pair with citrus for better vitamin C absorption, which boosts collagen production."
}
```

Add this note to the system prompt after the JSON example:

```
IMPORTANT nutrition fields:
- fiber: grams of dietary fiber
- sugar: grams of total sugar (added + natural)
- sodium: in GRAMS (not milligrams). E.g., 1500mg = 1.5g. A typical meal has 0.3-1.5g sodium.

Be accurate with all nutrition estimates based on the photo and portion size.
```

### 2b. Update `FoodAnalysisService.swift` — Response Parsing

In `parseResponse(_:imageData:)`, add parsing for the 3 new fields right after the existing `carbs` line:

```swift
let fiber = (analysis["fiber"] as? Double) ?? (analysis["fiber"] as? Int).map(Double.init) ?? 0
let sugar = (analysis["sugar"] as? Double) ?? (analysis["sugar"] as? Int).map(Double.init) ?? 0
let sodium = (analysis["sodium"] as? Double) ?? (analysis["sodium"] as? Int).map(Double.init) ?? 0
```

Update the `return FoodScan(...)` call to include the new fields:

```swift
return FoodScan(
    name: foodName,
    skinImpactScore: skinImpactScore,
    calories: max(0, calories),
    protein: max(0, protein),
    fat: max(0, fat),
    carbs: max(0, carbs),
    fiber: max(0, fiber),
    sugar: max(0, sugar),
    sodium: max(0, sodium),
    benefits: benefits,
    skinEffects: skinEffects,
    photoData: nil,
    aiTip: aiTip
)
```

---

## Section 2.5: New Nutrient Signature Colors

Each nutrient gets its own **unique signature color** so the cards look vibrant and distinct — not a boring wall of the same traffic light color. The signature color is used for the card's **background tint, label text, and value text**. The **progress bar** still uses traffic light zone colors (green/amber/red) for functional feedback.

### 2.5a. Add to `GlowbiteColors.swift`

Add these new color tokens inside the `GlowbiteColors` enum:

```swift
// MARK: - Nutrient Signature Colors
static let nutrientProtein = Color(hex: "8B5CF6")           // Soft violet — collagen/building blocks
static let nutrientProteinLight = Color(hex: "8B5CF6").opacity(0.10)

static let nutrientCarbs = Color(hex: "D4943A")             // Warm gold — energy/grains
static let nutrientCarbsLight = Color(hex: "D4943A").opacity(0.10)

static let nutrientFat = Color(hex: "2D9C96")               // Soft teal — oils/avocado/freshness
static let nutrientFatLight = Color(hex: "2D9C96").opacity(0.10)

static let nutrientFiber = Color(hex: "5B9A4F")             // Leafy green — plants/gut health
static let nutrientFiberLight = Color(hex: "5B9A4F").opacity(0.10)

static let nutrientSugar = Color(hex: "E8729A")             // Rose pink — sweetness/candy
static let nutrientSugarLight = Color(hex: "E8729A").opacity(0.10)

static let nutrientSodium = Color(hex: "4A7CB8")            // Ocean blue — salt/water
static let nutrientSodiumLight = Color(hex: "4A7CB8").opacity(0.10)
```

These are deliberately soft, muted tones that work well as light-tinted card backgrounds. Each one evokes the nutrient's association:
- **Protein → Violet**: premium, building-block feel
- **Carbs → Gold**: warm, energetic, grain-like
- **Fat → Teal**: fresh, clean, healthy oils
- **Fiber → Leafy green**: natural, plant-based
- **Sugar → Rose pink**: sweet, playful
- **Sodium → Ocean blue**: water/salt/mineral

### 2.5b. Two-Layer Color System for Nutrient Cards

Each `SkinNutrientCard` now receives TWO sets of colors:

1. **`signatureColor` / `signatureLightColor`** — the nutrient's unique identity color. Used for:
   - Card background tint (the light variant)
   - Label text ("PROTEIN", "CARBS", etc.)
   - Value text ("48", "250", etc.)
   - Target text ("/50g")
   - Descriptor text ("Collagen fuel")

2. **`barColor`** — the traffic light zone color (green/amber/red). Used for:
   - The progress bar fill ONLY

This means a Protein card always looks violet regardless of zone, but its progress bar turns green when optimal, amber when borderline, or red when too low/high. The user instantly sees "this is protein" (violet card) AND "am I in a good range?" (green bar).

---

## Section 3: Traffic Light Zone System

### 3a. Add to `HomeViewModel.swift` — Zone Definitions

This is the core logic. Each nutrient has a set of zones that determine the progress bar color. Most nutrients use a 5-zone bell curve (too low → low → optimal → high → too high). Sugar is one-directional (optimal → high → too high).

```swift
// MARK: - Nutrient Traffic Light Zones

enum NutrientZone {
    case tooLow, low, optimal, high, tooHigh

    var color: Color {
        switch self {
        case .tooLow, .tooHigh: return GlowbiteColors.redAlert
        case .low, .high: return GlowbiteColors.amberFair
        case .optimal: return GlowbiteColors.greenGood
        }
    }

    var lightColor: Color {
        switch self {
        case .tooLow, .tooHigh: return GlowbiteColors.redLight
        case .low, .high: return GlowbiteColors.amberLight
        case .optimal: return GlowbiteColors.greenLight
        }
    }
}

struct NutrientConfig {
    let label: String
    let unit: String
    let descriptor: String
    let signatureColor: Color       // unique identity color per nutrient
    let signatureLightColor: Color  // tinted background per nutrient
    let target: Double
    let greenRange: ClosedRange<Double>
    let amberLowRange: ClosedRange<Double>?   // nil for one-directional (sugar)
    let amberHighRange: ClosedRange<Double>
    let maxDisplay: Double

    func zone(for value: Double) -> NutrientZone {
        if greenRange.contains(value) { return .optimal }
        if amberHighRange.contains(value) { return .high }
        if let amberLow = amberLowRange, amberLow.contains(value) { return .low }
        if value > amberHighRange.upperBound { return .tooHigh }
        return .tooLow
    }
}
```

### 3b. Preset Daily Targets (skin-optimized for women 18-35, 2000 cal diet)

```swift
static let nutrientConfigs: [NutrientConfig] = [
    // Page 1
    NutrientConfig(
        label: "PROTEIN", unit: "g", descriptor: "Collagen fuel",
        signatureColor: GlowbiteColors.nutrientProtein,
        signatureLightColor: GlowbiteColors.nutrientProteinLight,
        target: 50, greenRange: 40...80,
        amberLowRange: 25...39, amberHighRange: 81...100,
        maxDisplay: 120
    ),
    NutrientConfig(
        label: "CARBS", unit: "g", descriptor: "Energy source",
        signatureColor: GlowbiteColors.nutrientCarbs,
        signatureLightColor: GlowbiteColors.nutrientCarbsLight,
        target: 250, greenRange: 150...300,
        amberLowRange: 100...149, amberHighRange: 301...375,
        maxDisplay: 400
    ),
    NutrientConfig(
        label: "FAT", unit: "g", descriptor: "Skin barrier",
        signatureColor: GlowbiteColors.nutrientFat,
        signatureLightColor: GlowbiteColors.nutrientFatLight,
        target: 65, greenRange: 44...78,
        amberLowRange: 25...43, amberHighRange: 79...100,
        maxDisplay: 120
    ),
    // Page 2
    NutrientConfig(
        label: "FIBER", unit: "g", descriptor: "Gut-skin axis",
        signatureColor: GlowbiteColors.nutrientFiber,
        signatureLightColor: GlowbiteColors.nutrientFiberLight,
        target: 28, greenRange: 20...35,
        amberLowRange: 10...19, amberHighRange: 36...45,
        maxDisplay: 50
    ),
    NutrientConfig(
        label: "SUGAR", unit: "g", descriptor: "Breakout flag",
        signatureColor: GlowbiteColors.nutrientSugar,
        signatureLightColor: GlowbiteColors.nutrientSugarLight,
        target: 25, greenRange: 0...25,
        amberLowRange: nil, amberHighRange: 26...40,
        maxDisplay: 60
    ),
    NutrientConfig(
        label: "SODIUM", unit: "g", descriptor: "Puffiness risk",
        signatureColor: GlowbiteColors.nutrientSodium,
        signatureLightColor: GlowbiteColors.nutrientSodiumLight,
        target: 1.5, greenRange: 0.8...1.5,
        amberLowRange: 0.4...0.79, amberHighRange: 1.51...2.3,
        maxDisplay: 3.0
    ),
]
```

### 3c. Replace the hardcoded `SkinNutrient` with real-data computed properties

Remove the existing `static let skinNutrients` array and `SkinNutrient` struct. Replace with:

```swift
// MARK: - Skin Nutrients (real data from today's food scans)

struct NutrientDisplayData: Identifiable {
    let id = UUID()
    let config: NutrientConfig
    let currentValue: Double
    let zone: NutrientZone
    let progress: Double  // 0.0 to 1.0, clamped
    var signatureColor: Color { config.signatureColor }
    var signatureLightColor: Color { config.signatureLightColor }
    var barColor: Color { zone.color }  // traffic light color for progress bar only
}

var nutrientPages: [[NutrientDisplayData]] {
    let scans = todayFoodScans

    let totals: [Double] = [
        scans.reduce(0) { $0 + $1.protein },
        scans.reduce(0) { $0 + $1.carbs },
        scans.reduce(0) { $0 + $1.fat },
        scans.reduce(0) { $0 + $1.fiber },
        scans.reduce(0) { $0 + $1.sugar },
        scans.reduce(0) { $0 + $1.sodium },
    ]

    let configs = Self.nutrientConfigs
    let displayData: [NutrientDisplayData] = zip(configs, totals).map { config, value in
        NutrientDisplayData(
            config: config,
            currentValue: value,
            zone: config.zone(for: value),
            progress: min(value / config.maxDisplay, 1.0)
        )
    }

    return [
        Array(displayData[0..<3]),  // Page 1: Protein, Carbs, Fat
        Array(displayData[3..<6]),  // Page 2: Fiber, Sugar, Sodium
    ]
}
```

---

## Section 4: Home Screen — Paged Skin Nutrients Section

### 4a. Replace `skinNutrientsSection` in `HomeView.swift`

Remove the current `skinNutrientsSection` (which uses a `ScrollView(.horizontal)`) and replace with a paged `TabView`:

```swift
// MARK: - Skin Nutrients (paged)

@State private var nutrientPage: Int = 0

private var skinNutrientsSection: some View {
    VStack(spacing: 8) {
        HStack {
            Text("SKIN NUTRIENTS")
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(GlowbiteColors.lightTaupe)

            Spacer()
        }

        TabView(selection: $nutrientPage) {
            // Page 0: Protein, Carbs, Fat
            nutrientRow(nutrients: viewModel.nutrientPages.indices.contains(0)
                ? viewModel.nutrientPages[0] : [])
                .tag(0)

            // Page 1: Fiber, Sugar, Sodium
            nutrientRow(nutrients: viewModel.nutrientPages.indices.contains(1)
                ? viewModel.nutrientPages[1] : [])
                .tag(1)

            // Page 2: Life Score (hardcoded placeholder)
            lifeScorePage
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 140)

        // Custom dot indicators
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(nutrientPage == index ? GlowbiteColors.coral : GlowbiteColors.lightTaupe.opacity(0.35))
                    .frame(width: 6, height: 6)
                    .animation(.easeOut(duration: 0.2), value: nutrientPage)
            }
        }
    }
}

private func nutrientRow(nutrients: [HomeViewModel.NutrientDisplayData]) -> some View {
    HStack(spacing: 8) {
        ForEach(nutrients) { nutrient in
            SkinNutrientCard(
                label: nutrient.config.label,
                value: nutrientValueString(nutrient),
                target: nutrientTargetString(nutrient),
                descriptor: nutrient.config.descriptor,
                signatureColor: nutrient.signatureColor,
                signatureLightColor: nutrient.signatureLightColor,
                barColor: nutrient.barColor,
                progress: nutrient.progress
            )
        }
    }
    .padding(.horizontal, 2)
}

private func nutrientValueString(_ n: HomeViewModel.NutrientDisplayData) -> String {
    if n.config.label == "SODIUM" {
        return String(format: "%.1f", n.currentValue)
    }
    return String(format: "%.0f", n.currentValue)
}

private func nutrientTargetString(_ n: HomeViewModel.NutrientDisplayData) -> String {
    if n.config.label == "SUGAR" {
        return "<\(Int(n.config.target))\(n.config.unit)"
    }
    if n.config.label == "SODIUM" {
        return String(format: "%.1f%@", n.config.target, n.config.unit)
    }
    return "\(Int(n.config.target))\(n.config.unit)"
}
```

### 4b. Life Score Page (hardcoded placeholder)

This is the 3rd swipe page. A single full-width card with a placeholder bar and score.

```swift
private var lifeScorePage: some View {
    VStack(alignment: .leading, spacing: 10) {
        HStack {
            Text("✦ LIFE SCORE")
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(GlowbiteColors.coral)
            Spacer()
            Text("COMING SOON")
                .font(.gbOverline)
                .tracking(1.0)
                .foregroundStyle(GlowbiteColors.lightTaupe)
        }

        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("72")
                .font(.gbDisplayM)
                .foregroundStyle(GlowbiteColors.darkBrown)
            Text("/ 100")
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.lightTaupe)
        }

        Text("Your overall wellness balance")
            .font(.gbCaption)
            .foregroundStyle(GlowbiteColors.mediumTaupe)

        // Hardcoded progress bar
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(GlowbiteColors.border)
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [GlowbiteColors.coral, GlowbiteColors.amberFair, GlowbiteColors.greenGood],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * 0.72, height: 6)
            }
        }
        .frame(height: 6)

        HStack {
            Text("Glow + Nutrition + Habits")
                .font(.gbOverline)
                .foregroundStyle(GlowbiteColors.lightTaupe)
            Spacer()
        }
    }
    .padding(.vertical, 14)
    .padding(.horizontal, 14)
    .background(GlowbiteColors.paper)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(
        RoundedRectangle(cornerRadius: 16)
            .stroke(GlowbiteColors.border, lineWidth: 1)
    )
    .padding(.horizontal, 2)
}
```

---

## Section 5: Update `SkinNutrientCard.swift` — Two-Layer Color System

The card uses **two color layers**:
1. **Signature color** — the nutrient's unique identity (violet for protein, gold for carbs, etc.). Used for background tint, all text.
2. **Bar color** — the traffic light zone color (green/amber/red). Used ONLY for the progress bar fill.

This means each card always looks like "its" nutrient (distinct identity), while the progress bar gives instant zone feedback.

```swift
import SwiftUI

struct SkinNutrientCard: View {
    let label: String
    let value: String
    let target: String
    let descriptor: String
    let signatureColor: Color       // nutrient's unique identity color
    let signatureLightColor: Color  // nutrient's tinted background
    let barColor: Color             // traffic light zone color (green/amber/red)
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(signatureColor)

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.gbTitleM)
                    .foregroundStyle(signatureColor)

                Text("/\(target)")
                    .font(.gbCaption)
                    .foregroundStyle(signatureColor.opacity(0.55))
            }

            Text(descriptor)
                .font(.gbOverline)
                .foregroundStyle(signatureColor.opacity(0.65))

            // Progress bar — uses traffic light zone color, NOT signature color
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(signatureColor.opacity(0.12))
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(width: geo.size.width * min(progress, 1.0), height: 3)
                        .animation(.easeOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 3)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(signatureLightColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
```

**Key changes from current card:**
- Removed fixed `.frame(width: 90)` → now `.frame(maxWidth: .infinity)` to fill available width
- Accepts `signatureColor`, `signatureLightColor`, `barColor` instead of single `color`/`lightColor`
- All text uses `signatureColor` (the nutrient's unique color)
- Progress bar fill uses `barColor` (the traffic light zone color)
- Progress bar track uses `signatureColor.opacity(0.12)` instead of `GlowbiteColors.border` (subtle tint matching the card)
- Added `.animation(.easeOut)` on progress bar for smooth transitions

**Visual result:**
- Protein card = violet tint bg, violet text, green/amber/red progress bar
- Carbs card = warm gold tint bg, gold text, green/amber/red progress bar
- Fat card = teal tint bg, teal text, green/amber/red progress bar
- Fiber card = leafy green tint bg, green text, green/amber/red progress bar
- Sugar card = rose pink tint bg, pink text, green/amber/red progress bar
- Sodium card = ocean blue tint bg, blue text, green/amber/red progress bar

---

## Section 6: Update `FoodScanResultView.swift`

### 6a. Update the nutrition grid to show 7 items (calories + 6 nutrients)

Replace the `nutritionItems` computed property:

```swift
private var nutritionItems: [(value: String, label: String)] {
    [
        ("\(scan.calories)", "CAL"),
        (String(format: "%.0fg", scan.protein), "PROTEIN"),
        (String(format: "%.0fg", scan.fat), "FAT"),
        (String(format: "%.0fg", scan.carbs), "CARBS"),
        (String(format: "%.0fg", scan.fiber), "FIBER"),
        (String(format: "%.0fg", scan.sugar), "SUGAR"),
        (String(format: "%.1fg", scan.sodium), "SODIUM"),
    ]
}
```

### 6b. Update the grid layout

Change the grid from 2 columns to handle 7 items nicely. Use a 4-column grid so the first row shows 4 items and the second row shows 3:

```swift
private var nutritionGrid: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
        ForEach(Array(nutritionItems.enumerated()), id: \.offset) { index, item in
            VStack(spacing: 4) {
                Text(item.value)
                    .font(.gbBodyL)
                    .foregroundStyle(GlowbiteColors.darkBrown)

                Text(item.label)
                    .font(.gbOverline)
                    .tracking(2.0)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(GlowbiteColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
            .opacity(showNutrition ? 1 : 0)
            .offset(y: showNutrition ? 0 : 16)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.75)
                    .delay(Double(index) * 0.08),
                value: showNutrition
            )
        }
    }
}
```

---

## Section 7: Implementation Phases (commit after each)

### Phase 1: Model + AI Pipeline
- Add `fiber`, `sugar`, `sodium` to `FoodScan` in `SkinModels.swift`
- Add the 3 fields to `CachedFoodScan` in `LocalCache.swift` (with defaults of `0`)
- Update `FoodAnalysisService.swift` — AI prompt JSON + parse new fields
- Update `MockData.swift` with sample values
- **Build and verify** — project must compile with no errors
- **Commit:** "Add fiber, sugar, sodium to FoodScan model and AI pipeline"

### Phase 2: Nutrient signature colors + traffic light zone system
- Add 6 nutrient signature color pairs (12 tokens) to `GlowbiteColors.swift`
- Add `NutrientZone`, `NutrientConfig` (with signatureColor fields), `NutrientDisplayData` to `HomeViewModel.swift`
- Add `nutrientConfigs` static array with preset targets and signature colors
- Add `nutrientPages` computed property that sums real food scan data
- Remove old `SkinNutrient` struct and `skinNutrients` static array
- **Build and verify**
- **Commit:** "Add nutrient signature colors and traffic light zone system"

### Phase 3: Home screen nutrients redesign
- Add `@State private var nutrientPage: Int = 0` to `HomeView`
- Replace `skinNutrientsSection` with paged `TabView` implementation
- Add `lifeScorePage` placeholder
- Add helper functions `nutrientRow`, `nutrientValueString`, `nutrientTargetString`
- Update `SkinNutrientCard.swift` — two-layer color system (signature color for card identity, bar color for traffic light zone)
- **Build and verify**
- **Commit:** "Redesign skin nutrients with paged TabView and signature colors"

### Phase 4: Food result screen update
- Update `FoodScanResultView.swift` — add 3 new nutrients to grid
- Change grid to 4 columns for better layout with 7 items
- **Build and verify**
- **Commit:** "Show all 6 nutrients in food scan result view"

---

## Traffic Light Zone Reference

These are the researched optimal ranges for skin health (women 18-35, 2000 cal/day):

| Nutrient | Target | Green (Optimal) | Amber Low | Amber High | Red Low | Red High |
|----------|--------|-----------------|-----------|------------|---------|----------|
| Protein  | 50g    | 40–80g          | 25–39g    | 81–100g    | <25g    | >100g    |
| Carbs    | 250g   | 150–300g        | 100–149g  | 301–375g   | <100g   | >375g    |
| Fat      | 65g    | 44–78g          | 25–43g    | 79–100g    | <25g    | >100g    |
| Fiber    | 28g    | 20–35g          | 10–19g    | 36–45g     | <10g    | >45g     |
| Sugar    | <25g   | 0–25g           | —         | 26–40g     | —       | >40g     |
| Sodium   | 1.5g   | 0.8–1.5g        | 0.4–0.79g | 1.51–2.3g  | <0.4g   | >2.3g   |

Sugar is **one-directional** — there is no "too low" zone. `amberLowRange` is `nil`.

All values displayed in **grams** including sodium (converted: 1500mg → 1.5g).

---

## Hard Constraints

1. **No renaming.** Don't rename Skinmax, files, folders, types, or strings.
2. **Calories stay.** Keep `calories: Int` in FoodScan — it powers the CalorieRingCard.
3. **Sodium in grams.** AI returns sodium in grams. Display as grams (e.g., "1.5g").
4. **New fields default to 0.** All 3 new FoodScan fields have default `= 0` so old init calls work.
5. **Real data only.** Nutrient totals sum from actual today's `FoodScan` entries. No hardcoded values except Life Score.
6. **Life Score is hardcoded.** Score of 72, gradient bar, "COMING SOON" tag. No computed logic.
7. **Standard paging.** Use `TabView` with `.tabViewStyle(.page(indexDisplayMode: .never))` + custom dots.
8. **Keep font tokens.** Use only `.gb*` extensions. Never `.system(...)`.
9. **Keep color tokens.** Use only `GlowbiteColors.*`. Never raw hex inline.
10. **Must compile.** After each phase, the project must build with zero errors.

---

## Data Model Reference (after changes)

```swift
// FoodScan will have:
//   .name: String
//   .skinImpactScore: Double (1-10)
//   .calories: Int
//   .protein: Double
//   .fat: Double
//   .carbs: Double
//   .fiber: Double          ← NEW
//   .sugar: Double          ← NEW
//   .sodium: Double         ← NEW (in grams)
//   .benefits: [String]
//   .skinEffects: [SkinEffect]
//   .photoData: Data?
//   .aiTip: String?
//   .createdAt: Date

// DataStore still has:
//   .foodScans(for: Date) -> [FoodScan]
//   .latestSkinScan() -> SkinScan?
//   .calculateStreak() -> Int
```

---

## Out of Scope

- User-configurable nutrient targets (preset only for now)
- Life Score computation logic (hardcoded placeholder)
- Hydration tracking changes
- Calorie ring changes
- Glow score tile changes
- Tab bar or scan popup changes
- Onboarding, paywall, auth
- SwiftData schema versioning (lightweight migration handles new fields with defaults)
