# Skinmax — iOS App

## What This Is
Skinmax is an AI-powered skin health + food scanning iOS app for women 18-35.
Two core features: face scanner (AI skin analysis with Glow Score) and food scanner (skin impact score + full nutrition).
Unique value: connects what you eat to how your skin looks — no competitor does this.
Think "Cal AI for skincare." Playful, warm, never clinical.

## Brand Voice
Skinmax talks like a supportive, skin-obsessed best friend — not a dermatologist.
Use emojis naturally. Be encouraging, playful, warm. Short punchy sentences.

Good examples:
- "Your skin is going to LOVE this 🌟"
- "3 glow-boosting foods in this meal. Nice pick!"
- "Skipped breakfast? Your glow score took a hit, bestie 😅"
- "Ooh, avocado toast — your skin says thank you 🥑✨"

Never write:
- "Your dietary intake has been analyzed"
- "You have failed to meet your nutritional goals"
- "Analysis complete. Results are as follows:"
- Anything that sounds like a medical report or lecture

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

### Icon-Derived Visual Language — The Through-Line

The app icon defines the visual language and every screen must feel like a natural extension of it. Five motifs, used consistently, make the system cohere:

**1. Scanner corner brackets** — L-shaped marks in cream/white, rounded caps. The icon has them framing the apple; in-app they frame anything that represents a "moment of measurement": the camera preview, the Glow Score reveal, recent-scan cards, onboarding steps. Default spec: 1.5pt stroke, Cream BG color (#FAF6F0) at 85% opacity (or white at 90% on a coral surface), 24-32pt arm length, rounded stroke caps. Never apply brackets to more than one element per screen — they lose meaning if overused.

**2. Characterful scores** — The apple in the icon has a face (closed-arc eyes + soft smile). Score elements in-app inherit this: the Glow Score ring center shows a tiny emoji-style face that shifts by traffic-light tier (🌟 green 70+ → 😊 amber 40-69 → 💫 red <40). Insight cards, empty states, and achievement badges all get a little character expression.

**3. Sparkles as decorative system** — Static on the icon, animated in-app. Two sizes: "star sparkle" (6pt, 4-point star, filled Sunny Butter #FFF8E8) and "dot sparkle" (3pt, simple circle). Floating pattern around Glow Score >80, around "good food" results, and during streak milestones. Animation: 2s loop, subtle scale 1.0 → 1.1 with fade 0.6 → 1.0. Always in pairs or triplets, never single, never more than 6 per screen.

**4. Soft highlights on coral surfaces** — The apple in the icon has a cream blob highlight on the top-left for dimensionality. Every coral UI surface (score ring, primary button, coral chip, active tab indicator) gets a matching inner highlight: an elliptical overlay at 35-55% opacity of white, positioned top-left at 30-40% of the element's size, rotated roughly -22°. Makes flat color feel hand-painted, not digital.

**5. Warm canvas, no flat whites** — The app's canonical background is not pure white. Use `GlowbiteColors.creamBG` (#FAF6F0) for main surfaces, with optional subtle gradient to Peach Wash (#F2ECE2) at the bottom for hero sections. Cards are white (#FFFFFF) but sit on this warm canvas so everything feels grounded, not sterile.

**Squircle rule:** every RoundedRectangle in SwiftUI must use `style: .continuous`, not the default `.circular`. The icon's corners use iOS's squircle mask; match it everywhere.

### Color Palette — USE ONLY THESE HEX VALUES

> These are the source-of-truth values. They match `Core/Design/GlowbiteColors.swift` exactly. Do not introduce new hex codes, and never reference the older brighter brand-doc palette (#FF7A5C / #FFB89E / etc.) — the app uses a more sophisticated, muted earth palette.

PRIMARY:
- Terracotta Coral: #C24A1E (primary CTAs, brand mark, active states) — this is the "coral" in code
- Peach Light: #C24A1E at 15% opacity (soft coral washes, selected states)
- Peach Wash: #F2ECE2 (secondary surfaces, chip backgrounds, dividers)
- Cream BG: #FAF6F0 (main app background, slightly warmer than pure white)
- Sunny Butter: #FFF8E8 (sparkle highlights, special callouts)

SUPPORTING:
- Forest Green: #4A7C59 (positive scores, good food 8-10, leaf icons, "Good" tier)
- Warm Amber: #C49234 (okay scores 40-69, food scores 5-7, "Fair" tier)
- Muted Red: #B23A2C (negative/alert, scores 0-39, food 1-4, "Needs work" tier)
- Hydration Blue: #4A7CB8 (hydration tracking, water metric)
- Lavender: #CE93D8 (hormone-related insights, rare accent)
- Deep Purple: #8B5CF6 (premium/analytics accents)

TEXT:
- Deep Espresso: #1A1510 (primary text, headings — this is the "darkBrown" in code)
- Warm Brown: #4B3D36 (body text)
- Medium Taupe: #6B5C54 (secondary/supporting text)
- Light Taupe: #9A8E82 (captions, timestamps, placeholders)
- Soft Tan: #F2ECE2 (dividers, borders, inactive elements — same as Peach Wash)
- White: #FFFFFF (card backgrounds)

NUTRIENT SIGNATURE COLORS (for food breakdown cards, charts):
- Protein: #C24A1E (same as coral)
- Carbs: #D4943A (warm gold)
- Fat: #A68B6B (soft taupe-brown)
- Fiber: #66BB6A (bright green — differentiates from Forest Green)
- Sugar: #E57373 (soft pink-red — differentiates from Muted Red)
- Sodium: #5B9EC4 (sky blue)

KEY GRADIENTS:
- Hero Gradient: LinearGradient from #C24A1E to #C24A1E at 70% opacity, topLeading to bottomTrailing
- Button Gradient: LinearGradient from #C24A1E to #D4623A, leading to trailing

### Typography — NUNITO ONLY

Bundle these Nunito .ttf files and register in Info.plist under UIAppFonts:
Nunito-Regular (400), Nunito-Medium (500), Nunito-SemiBold (600), Nunito-Bold (700), Nunito-ExtraBold (800), Nunito-Black (900)

Use ONLY the .gb* Font extensions defined in Core/Design/Typography.swift:

- .gbDisplayXL — Nunito-ExtraBold 40pt (hero numbers, splash)
- .gbDisplayL — Nunito-ExtraBold 32pt (large score display)
- .gbDisplayM — Nunito-ExtraBold 26pt (section hero text)
- .gbTitleL — Nunito-Bold 22pt (screen titles, app name)
- .gbTitleM — Nunito-Bold 18pt (card titles, button text)
- .gbBodyL — Nunito-Regular 16pt (large body text)
- .gbBodyM — Nunito-Regular 14pt (standard body text)
- .gbCaption — Nunito-SemiBold 12pt (labels, chips, metadata)
- .gbOverline — Nunito-Bold 11pt (overline labels, uppercase)

NEVER use .font(.system(...)). NEVER use raw .custom("Nunito-...", size:) inline. Always go through the .gb* extensions so the type scale stays consistent.

### Spacing — 8pt Grid

Named tokens: xs=4, sm=8, md=16, lg=24, xl=32, xxl=48
Screen edge padding: 20pt horizontal
Card padding: 16-20pt
Card corner radius: 20pt (standard), 28pt (large cards, sheets)
Button corner radius: 16pt (rectangular), 100pt (pill buttons)
Input field radius: 14pt
Tag/chip radius: 100pt (fully rounded pill)
Tab bar corner radius: 22pt
Tab bar inset: 10pt from screen edges
Metric grid: 2-column, 10pt gap

### Shadows — ALWAYS Warm Coral-Tinted

NEVER use Color.black.opacity(...) for shadows. Always use the terracotta coral (matches `GlowbiteColors.cardShadowColor` etc. in code):
- Standard card: .shadow(color: Color(hex: "C24A1E").opacity(0.08), radius: 12, x: 0, y: 4)
- Elevated card: .shadow(color: Color(hex: "C24A1E").opacity(0.12), radius: 16, x: 0, y: 6)
- Button glow: .shadow(color: Color(hex: "C24A1E").opacity(0.25), radius: 16, x: 0, y: 6)
- Subtle: .shadow(color: Color(hex: "C24A1E").opacity(0.05), radius: 8, x: 0, y: 2)

### Animations

- Standard transitions: .easeOut(duration: 0.25)
- Interactive elements: .spring(response: 0.4, dampingFraction: 0.75)
- Tab bar switching: .spring(response: 0.35, dampingFraction: 0.75)
- Score reveal: .spring(response: 0.5, dampingFraction: 0.7) with 0.3s delay
- Sparkle pulse: 2s infinite, subtle scale 1.0 to 1.05
- Dismiss/remove: .move(edge:) combined with .opacity

### Traffic Light Scoring System

ALL circle progress indicators and score displays must use this system (matches `GlowbiteColors.trafficLight(for:)` in code):
- FOREST GREEN (#4A7C59): Score 70-100 → "Good" / emoji 🌟
- WARM AMBER (#C49234): Score 40-69 → "Fair" or "Moderate" / emoji ✨
- MUTED RED (#B23A2C): Score 0-39 → "Needs work" / emoji 💫

### Component Patterns

Primary Button (coral pill with gradient + glow):
Background: LinearGradient #C24A1E → #D4623A, leading to trailing. Padding: vertical 16, horizontal 32. Corner radius: 100 (full pill). Shadow: #C24A1E at 25% opacity, radius 16, y offset 6. Text: .gbTitleM, white, center aligned. Haptic: .medium on tap.

Secondary Button (peach outlined pill):
Background: Capsule fill #C24A1E at 15% opacity (use `GlowbiteColors.peachLight`). Border: 1.5pt stroke #C24A1E. Corner radius: 100 (full pill). Text: .gbTitleM, color #C24A1E.

Glow Score Card (signature component — large circular progress ring):
Ring: gradient stroke (Terracotta Coral → 70% opacity coral), 12pt stroke width, round cap. Center: score number in .gbDisplayXL. Above ring: "TODAY'S GLOW" label in .gbOverline, Medium Taupe, tracking 2.0. Below ring: emoji reaction based on score (🌟 80+, ✨ 60-79, 💫 <60). Card bg: Cream BG with subtle Peach Wash gradient, corner radius 28. Shadow: warm coral elevated shadow (#C24A1E at 12%).

Food Chip (compact pill):
Layout: food emoji + name + impact indicator (+/-). Background: #F2ECE2 (Peach Wash). Corner radius: 100. Text: .gbCaption, Deep Espresso.

Metric Card (white card with progress ring):
Ring: traffic light colored, 6pt stroke. Center text: .gbTitleM, score value. Label below: .gbCaption, Medium Taupe. Card: white bg, corner radius 20, warm shadow.

Bottom Sheet:
Grabber: 4pt × 40pt rounded bar, Soft Tan color, centered. Corner radius: 28 top corners only. Padding: 20 edges, 24 top, 32 bottom. Dismiss: drag gesture.

Insight/Tip Card:
Layout: emoji circle (40pt, Cream Peach bg) + title (.gbTitleM) + message (.gbBodyM). Card: white bg, corner radius 20, warm shadow. Dismiss: X button in top-right, Light Taupe color.

## App Structure

### Tab Bar — LIQUID GLASS STYLE

Floating bar, inset 10pt from screen edges, rounded 22pt corners. Background: .ultraThinMaterial + white overlay at 45% opacity. Border: 1px solid rgba(255,255,255,0.5). Shadow: warm coral subtle shadow. Active tab: Hero Coral tint background, Soft Peach at 35% opacity with matchedGeometryEffect. Inactive: Medium Taupe icons and labels. 3 inline tabs: Home | Analytics | Account. Plus floating circular scan button (56pt, coral gradient, camera icon, white).

### Scan Tab Behavior

Tapping the floating scan button does NOT navigate to a new screen. Instead:
1. Screen dims with overlay (Dark Chocolate at 30% opacity)
2. Two frosted glass bubbles appear SIDE BY SIDE above the tab bar
3. Left bubble: "Scan Face" (🧑 icon, Cream Peach bg) → opens FaceScanView camera
4. Right bubble: "Log Food" (🍽 icon, Fresh Green at 15% bg) → opens bottom sheet for food entry
5. Tapping anywhere outside dismisses the popup
6. Scan button rotates 45° when popup is open

### Screens (14 total)

TAB HOME:
1. HomeView — Greeting, Glow Score card, metric carousel, recent activity, AI insight

TAB ANALYTICS:
2. AnalyticsContainerView — Dual-line chart (skin + food), time range toggle, AI insights, weekly summary

TAB ACCOUNT:
3. AccountView — Profile header, stats, menu hub
4. ProgressView — Before/after photo comparison
5. ScanHistoryView — Past face scans list
6. NotificationSettingsView — Notification preferences
7. DataSettingsView — Data/privacy settings
8. AboutView — App info

SCAN FLOWS (popup overlay → full screen covers):
9. ScanPopupOverlay — Side-by-side frosted bubbles
10. FaceScanView — Camera with oval face guide
11. FaceScanResultView — Glow Score + traffic light circle metrics
12. SkinDetailView — Single metric score + AI tips
13. FoodLogSheet — Full screen: type name → take/choose photo → analyze
14. FoodScanResultView — Skin impact + nutrition + benefits + effect tags

### Home Screen Anatomy (top to bottom)

1. Header: app name (.gbTitleL) + avatar circle
2. Month navigation: chevron left | "Month Year" (.gbTitleM) | chevron right
3. WeekDayStrip: horizontal paged Mon-Sun, coral selected state, dot indicators for data days
4. Analysis-in-progress card (conditional, shown during active scan)
5. Glow Score Card: horizontal layout — score text left + ScoreRing right
6. Metric Carousel: 3-per-page paged horizontal scroll of CircleMetricCards
7. Recent Activity: face scan list for selected date with swipe-to-delete
8. Dismissible Insight Card: emoji + title + message + X button

### Food Log Flow (Full Screen Sheet)

1. Full screen sheet slides up
2. Step 1: Text field — "What did you eat?" (required)
3. Step 2: Two options side by side — "Take Photo" (camera) | "Choose Photo" (gallery)
4. CTA button: "Analyze with AI ✨" (disabled until name + photo provided, coral pill style)
5. On submit: loading state with progress → navigates to FoodScanResultView

### Food Result Display

- Skin Impact Score (1-10) with traffic light colors
- Full nutrition: Calories, Protein, Fat, Carbs (metric cards in a row)
- Benefits list (why it's good/bad for skin)
- Skin effect tags as pills (e.g., "Hydration ↑", "Redness ↓")

## Architecture: MVVM

View ←→ ViewModel ←→ Service ←→ API/Supabase

- Views: SwiftUI only, declarative, no business logic
- ViewModels: @Observable @MainActor classes, own all state and logic
- Services: Protocol-based, injectable
- Models: Plain structs, Codable
- Coordinator: AnalysisCoordinator orchestrates scan phases and progress

## File Structure

Skinmax/
├── App/
│   ├── SkinmaxApp.swift
│   └── ContentView.swift (root ZStack with tabs + scan overlay)
├── Core/
│   ├── Design/
│   │   ├── SkinmaxColors.swift (color palette + traffic light helpers)
│   │   ├── Typography.swift (.gb* Font extensions)
│   │   ├── SkinmaxFonts.swift (legacy — prefer Typography.swift)
│   │   ├── SkinmaxSpacing.swift (layout tokens, 8pt grid)
│   │   └── SkinmaxComponents.swift (shared UI: buttons, cards, rings, tab bar, scan overlay)
│   └── Utilities/
│       ├── AnalysisCoordinator.swift (scan pipeline orchestration)
│       ├── CameraManager.swift (AVCaptureSession, permissions, face detection)
│       ├── HapticManager.swift (centralized haptics)
│       ├── ImageProcessor.swift (resize, compress, face crop)
│       └── SkinmaxLog.swift (os.Logger categories)
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   └── AnalysisHomeCard.swift
│   ├── FaceScan/
│   │   ├── FaceScanView.swift
│   │   ├── FaceScanViewModel.swift
│   │   ├── FaceScanResultView.swift
│   │   ├── CameraPreviewView.swift
│   │   └── SkinDetailView.swift
│   ├── FoodScan/
│   │   ├── FoodLogSheet.swift
│   │   ├── FoodLogSheetViewModel.swift
│   │   ├── FoodScanResultView.swift
│   │   ├── FoodLogView.swift
│   │   ├── FoodLogViewModel.swift
│   │   ├── FoodRowView.swift
│   │   └── ImagePicker.swift
│   ├── Analytics/
│   │   └── AnalyticsContainerView.swift
│   ├── Progress/
│   │   └── ProgressView_.swift
│   └── Profile/
│       ├── AccountView.swift
│       ├── ScanHistoryView.swift
│       ├── NotificationSettingsView.swift
│       ├── DataSettingsView.swift
│       └── AboutView.swift
├── Models/
│   ├── SkinModels.swift (SkinScan, FoodScan, SkinMetric, SkinMetricType, etc.)
│   └── MockData.swift (preview/sample data)
├── Services/
│   ├── DataStore.swift (@Observable SwiftData facade)
│   ├── SkinAnalysisService.swift (OpenAI skin analysis)
│   ├── FoodAnalysisService.swift (OpenAI food analysis)
│   └── InsightEngine.swift (rule-based insight generation)
├── Persistence/
│   └── LocalCache.swift (SwiftData @Model entities: CachedSkinScan, CachedFoodScan)
└── Resources/
    ├── Assets.xcassets/
    ├── Fonts/ (Nunito .ttf files)
    ├── Info.plist
    └── AppStoreMetadata.swift

## Key Rules — ALWAYS Follow

ALWAYS:
1. Use ONLY Nunito via .gb* font extensions — never system fonts, never raw .custom() inline
2. Use ONLY hex colors from the palette above — no extra colors, no iOS defaults
3. Apply warm coral-tinted shadows (Color(hex: "C24A1E").opacity(...)) — never Color.black
4. Use corner radius 16-28 for cards, 100 for pills/chips — never below 12
5. Write copy in playful, emoji-natural, encouraging voice
6. Use SF Symbols for system icons (with Nunito for all text)
7. Add haptics: .medium on button taps, .success on scan complete, .selection on tab switch, .warning on delete
8. Build with SwiftUI only (UIKit only for AVFoundation camera bridge)
9. Every screen needs: empty state, loading state, error state, success state
10. Score circles ALWAYS use traffic light colors (green/amber/red) based on value
11. Tab bar is ALWAYS liquid glass style, floating, with blur
12. ALL images compressed to JPEG 0.6 quality, max 800px width before API upload
13. Camera sessions MUST run on background thread
14. Use .spring(response: 0.4, dampingFraction: 0.75) for interactive animations
15. ViewModels are @Observable @MainActor classes — Views never hold business logic
16. Background of every ScrollView is a LinearGradient from Cream Base (top) → Cream Peach (bottom) — never flat white
17. RoundedRectangle corners MUST use `style: .continuous` — iOS squircle, matches the icon
18. One Glow Score ring per screen gets the characterful face in the center (🌟/😊/💫 by tier)
19. Apply scanner corner brackets to exactly ONE "moment of measurement" element per screen — camera preview, score reveal, or onboarding step
20. Every coral surface (score ring, primary button, coral chip) gets a soft white inner highlight (ellipse, 35-55% opacity, top-left, -22° rotation) for dimensionality

NEVER:
1. Use default iOS blue .accentColor — always Terracotta Coral #C24A1E
2. Use system fonts (San Francisco, etc.) — always Nunito
3. Use sharp corners with radius under 12
4. Use Color.black.opacity(...) for shadows — always warm coral tint
5. Write clinical, medical, or preachy copy
6. Use colors outside the defined palette
7. Use harsh red for errors — use Muted Red #B23A2C
8. Skip haptic feedback on interactive elements
9. Put business logic in SwiftUI Views
10. Use UIKit views when SwiftUI can do the job
11. Use flat pure-white screen backgrounds — always peach gradient
12. Use RoundedRectangle without `style: .continuous` — breaks the squircle consistency
13. Put scanner corner brackets on more than one element per screen — they lose meaning
14. Put single sparkles — always pairs or triplets, never alone
15. Use Image(systemName:) for the Glow Score emoji face — that's a custom character slot

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

## Git Workflow — ALWAYS Follow
- **Never commit directly to main.** Every new feature or fix gets its own branch.
- Branch off `main` with naming: `feature/<short-description>` or `fix/<short-description>`
- Make focused, atomic commits within the branch — one logical change per commit.
- When the feature is complete and verified, merge into `main` (fast-forward or squash merge at user's discretion) and delete the feature branch.
- This keeps `main` clean and every feature independently revertable.
- **Only merge and prune branches when the user explicitly asks.** Do not auto-merge or auto-push.
