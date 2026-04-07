# Skinmax — iOS App

## What This Is
Skinmax is an AI-powered skin health + food scanning iOS app for women 18-35.
Two core features: face scanner (AI skin analysis with Glow Score) and food scanner (skin impact score + full nutrition).
Unique value: connects what you eat to how your skin looks — no competitor does this.

## Tech Stack
- **Platform:** iOS 17+, iPhone only, portrait only
- **Language:** Swift 5.9+, SwiftUI (NO UIKit unless absolutely necessary)
- **Database:** Supabase (PostgreSQL + Auth + Storage)
- **Local Cache:** SwiftData (last 7 days cached for offline)
- **AI:** OpenAI Vision API (GPT-4o) for face analysis and food identification
- **Charts:** Swift Charts (built-in iOS 16+)
- **Camera:** AVFoundation
- **Dependencies:** supabase-swift, Kingfisher (for remote images)

## Design System — FOLLOW EXACTLY

### Font: Nunito (bundled .ttf files)
```
H1 (App name):       Nunito-Bold      22pt, letter-spacing: -0.3
H2 (Section titles):  Nunito-SemiBold  18pt
H3 (Card titles):     Nunito-SemiBold  14pt
Body:                 Nunito-Regular   13pt
Caption/Labels:       Nunito-Medium    11pt
Small/Tags:           Nunito-Medium    9pt
Score Display:        Nunito-Bold      48pt
Tab Bar Labels:       Nunito-SemiBold  10pt
```

### Colors — Use ONLY these colors
```
PRIMARY:
  Coral:          #E8A08A   (buttons, accents, active states)
  Peach Light:    #F4C7B0   (gradients, highlights)
  Peach Wash:     #FCEEE8   (tag backgrounds, light fills)
  Cream BG:       #FDF8F5   (main app background)

NEUTRAL:
  Dark Brown:     #3A2A24   (primary text, headings)
  Warm Gray:      #7A6A64   (body text)
  Muted Tan:      #B09A92   (secondary text, labels)
  Light Tan:      #F0E8E4   (borders, dividers, inactive)
  White:          #FFFFFF   (card backgrounds)

METRIC ACCENTS:
  Hydration Blue: #81D4FA
  Green Good:     #66BB6A   (also for good food scores 8-10)
  Amber Fair:     #FFB74D   (for fair scores 5-7, also food scores 5-7)
  Red Alert:      #E57373   (for poor scores 0-39, also food scores 1-4)

DARK SURFACES:
  Dark Surface:   #3A2A24   (score card bg)
  Dark Mid:       #5A4A44   (gradient end)
```

### Spacing
```
Screen Padding:       16pt horizontal
Card Padding:         14-18pt
Card Corner Radius:   16-20pt
Card Shadow:          0 2px 8px rgba(0,0,0,0.03)
Button Corner Radius: 14-16pt
Tag Corner Radius:    10pt
Metric Grid:          2-column, 10pt gap
```

### Traffic Light Scoring System
ALL circle progress indicators and score displays must use this system:
- **GREEN (#66BB6A):** Score 70-100 → "Good"
- **AMBER (#FFB74D):** Score 40-69 → "Fair" or "Moderate"
- **RED (#E57373):** Score 0-39 → "Needs work"

## App Structure

### Tab Bar — LIQUID GLASS STYLE
```
Floating bar, inset 10pt from screen edges, rounded 22pt corners.
Background: rgba(255,255,255,0.45) + backdrop blur.
Border: 1px solid rgba(255,255,255,0.5)
Shadow: 0 4px 30px rgba(0,0,0,0.06)
Active tab: coral tint background rgba(244,199,176,0.35)

4 tabs: Home | Analytics | Account | Scan
```

### Scan Tab Behavior
Tapping Scan does NOT navigate to a new screen. Instead:
1. Screen dims with overlay (rgba(58,42,36,0.3))
2. Two frosted glass bubbles appear SIDE BY SIDE above the tab bar
3. Left bubble: "Scan Face" (🧑 icon, peach bg) → opens FaceScanView camera
4. Right bubble: "Log Food" (🍽 icon, green bg) → opens bottom sheet for food entry
5. Tapping anywhere outside dismisses the popup

### Screens (13 total)
```
TAB: HOME
  1. HomeView — Dashboard with Glow Score, 2x2 metrics, 7-day trend chart, AI insight

TAB: ANALYTICS
  2. FoodLogView — Food log with calendar (horizontal day picker + month navigation)
  3. TrendsView — Dual-line chart (skin + food), AI correlations
  4. InsightsView — AI-generated correlations and tips

TAB: ACCOUNT
  5. AccountView — Profile, settings, app info
  6. ProgressView — Before/after photo comparison
  7. ScanHistoryView — Past face scans list

TAB: SCAN (popup overlay, not a screen)
  8. ScanPopupOverlay — Side-by-side frosted bubbles
  9. FaceScanView — Camera with oval face guide
  10. FaceScanResultView — Traffic light circle metrics
  11. SkinDetailView — Single metric score + AI tips
  12. FoodLogSheet — Bottom sheet: type name → take/choose photo → analyze
  13. FoodScanResultView — Skin impact + nutrition + benefits
```

### Food Log Flow (Bottom Sheet)
1. Bottom sheet slides up from bottom
2. Step 1: Text field — "What did you eat?" (required)
3. Step 2: Two options side by side — "Take Photo" (camera) | "Choose Photo" (gallery)
4. CTA button: "Analyze with AI ✨" (disabled until name + photo provided)
5. On submit: loading state → navigates to FoodScanResultView

### Food Result Display
- Skin Impact Score (1-10) with traffic light colors
- Full nutrition: Calories, Protein, Fat, Carbs (4 cards in a row)
- Benefits list (why it's good/bad for skin)
- Skin effect tags (e.g., "Hydration ↑", "Redness ↓")

## Architecture: MVVM
```
View ←→ ViewModel ←→ Service ←→ API/Supabase

Views: SwiftUI only, declarative, no business logic
ViewModels: @Observable classes, own all state and logic
Services: Protocol-based, injectable
Models: Plain structs, Codable
```

## File Structure
```
Skinmax/
├── App/
│   ├── SkinmaxApp.swift
│   ├── ContentView.swift (root TabView)
├── Core/
│   ├── Design/
│   │   ├── SkinmaxColors.swift
│   │   ├── SkinmaxFonts.swift
│   │   ├── SkinmaxSpacing.swift
│   │   └── SkinmaxComponents.swift
│   ├── Extensions/
│   ├── Utilities/
│   │   ├── CameraManager.swift
│   │   ├── HapticManager.swift
│   │   └── ImageProcessor.swift
│   └── Network/
│       ├── APIClient.swift
│       └── APIEndpoints.swift
├── Features/
│   ├── Home/
│   ├── FaceScan/
│   ├── FoodScan/
│   ├── Progress/
│   ├── Trends/
│   └── Profile/
├── Models/
├── Services/
├── Persistence/
│   ├── SupabaseManager.swift
│   ├── LocalCache.swift
│   └── SyncManager.swift
└── Resources/
    ├── Assets.xcassets/
    ├── Fonts/ (Nunito .ttf files)
    └── Info.plist
```

## Key Rules
1. NEVER use system font — always Nunito (bundled)
2. NEVER add colors outside the defined palette
3. NEVER put business logic in Views
4. ALL images compressed to JPEG 0.6 quality, max 800px width before upload
5. Camera sessions MUST run on background thread
6. Every screen needs: empty state, loading state, error state, success state
7. Use spring animations (response: 0.3, dampingFraction: 0.8) for personality
8. Haptic feedback on: scan capture, score reveal, food log save
9. Tab bar is ALWAYS liquid glass style, floating, with blur
10. Score circles ALWAYS use traffic light colors based on value

## Supabase Config
- 90-day data retention policy
- Photos stored in private buckets: "face-scans", "food-scans"
- SwiftData caches last 7 days locally
- Background sync when online

## Performance Targets
- App launch → dashboard: < 1 second
- Camera ready: < 500ms
- Face scan → results: < 4 seconds
- Food scan → results: < 3 seconds
- App size: < 50MB
