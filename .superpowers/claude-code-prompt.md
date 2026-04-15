# Task: Rebrand and Build Out [NEW_NAMEw] iOS App

## Context
This is a Swift/SwiftUI iOS app (previously called "Skinmax") — an AI-powered food scanning + face scanning app for women 18-35. The app scans your food with AI and shows how it affects your skin (Skin Impact Score), and also does face scans for a Glow Score. The unique angle is connecting diet to skin health.

The app is ~60% built. All core scan pipelines work (OpenAI Vision integration via `SkinAnalysisService` and `FoodAnalysisService`, camera via `CameraManager`, SwiftData persistence via `DataStore`). What's missing: auth, paywall, onboarding, Supabase sync, and the app is being rebranded + repositioned to lead with food scanning over face scanning.

Read CLAUDE.md for the full design system, architecture, and rules.

## What Was Already Fixed (Phase 0 — DONE, do not redo)
These issues have already been resolved:
- ContentView.swift corrupted first line → fixed
- Data retention mismatch (7 days vs 90 days) → aligned to 90 days in `DataStore.pruneExpiredCache()`
- Dead `showFoodLog` navigation in HomeView → removed
- Orphan views `TrendsView.swift` and `SkinAnalyticsView.swift` → deleted and removed from Xcode project
- Duplicate saves in `FaceScanResultView` and `FoodScanResultView` → removed (AnalysisCoordinator is now the single save point)
- Hardcoded hex colors in `SkinmaxComponents.swift` → replaced with `SkinmaxColors` tokens

## Known Issues to Address During Build
1. **`FoodLogView` is unreachable** — the file exists at `Skinmax/Features/FoodScan/FoodLogView.swift` with a full calendar-based food log UI, but nothing navigates to it. The food-first redesign (Phase 2) should give it a proper entry point.
2. **`FaceScanResultView` Save button is cosmetic** — the button shows a toast but doesn't call `dataStore.saveSkinScan()` anymore (coordinator already saves). Either remove the Save button entirely or make it clear the scan was auto-saved.
3. **`FaceScanResultView` has hardcoded "First scan!" text** (line ~120) — should be derived from scan history.

## Current Codebase Structure (43 Swift files, ~6,600 lines)

```
Skinmax/
├── App/
│   ├── SkinmaxApp.swift          — @main, SwiftData container, env injection
│   └── ContentView.swift         — Root: 3 tabs (Home/Analytics/Account) + scan popup + fullScreenCovers
├── Core/
│   ├── Design/
│   │   ├── SkinmaxColors.swift   — Full palette + traffic light helpers
│   │   ├── SkinmaxFonts.swift    — Nunito font tokens
│   │   ├── SkinmaxSpacing.swift  — Layout constants
│   │   └── SkinmaxComponents.swift — ScoreCard, ScoreRing, GlassTabBar, ScanPopupOverlay, WeekDayStrip, etc.
│   ├── Extensions/               — (empty)
│   ├── Network/                  — (empty, no APIClient yet)
│   └── Utilities/
│       ├── Config.swift          — OpenAI API key from Secrets.plist
│       ├── CameraManager.swift   — AVFoundation session, front camera, Vision face detection
│       ├── ImageProcessor.swift  — Resize/compress for face and food
│       ├── HapticManager.swift   — Impact/notification/selection haptics
│       ├── SkinmaxLog.swift      — os.Logger categories
│       └── AnalysisCoordinator.swift — Orchestrates face/food analysis lifecycle, saves on success
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift        — Dashboard: week strip, glow score, metric carousel, recent activity, insights
│   │   ├── HomeViewModel.swift   — Calendar logic, glow/metrics for selected day, trends, food averages
│   │   └── AnalysisHomeCard.swift — In-progress analysis UI
│   ├── FaceScan/
│   │   ├── FaceScanView.swift    — Full-screen camera with oval face guide
│   │   ├── FaceScanViewModel.swift — Camera state machine, capture + process
│   │   ├── CameraPreviewView.swift — UIViewRepresentable preview layer
│   │   ├── FaceScanResultView.swift — Results: glow ring, metrics grid, AI insight
│   │   └── SkinDetailView.swift  — Per-metric detail + static tips
│   ├── FoodScan/
│   │   ├── FoodLogView.swift     — Calendar food log (UNREACHABLE — needs entry point)
│   │   ├── FoodLogViewModel.swift — Date/month logic for food
│   │   ├── FoodLogSheet.swift    — Bottom sheet: name food → take/choose photo → analyze
│   │   ├── FoodLogSheetViewModel.swift — Validation, image prep
│   │   ├── FoodScanResultView.swift — Skin impact score, nutrition grid, benefits, effects tags
│   │   ├── FoodRowView.swift     — List row for food items
│   │   └── ImagePicker.swift     — UIImagePickerController wrapper
│   ├── Analytics/
│   │   └── AnalyticsContainerView.swift — Dual-line chart, AI insights, weekly summary
│   ├── Progress/
│   │   └── ProgressView_.swift   — Before/after comparison (photos are SF Symbol placeholders)
│   └── Profile/
│       ├── AccountView.swift     — Profile, settings, sub-navigation
│       ├── ScanHistoryView.swift — Past face scans list
│       ├── AboutView.swift       — About page (Privacy/Terms links are empty placeholders)
│       ├── DataSettingsView.swift — Data counts + delete all
│       └── NotificationSettingsView.swift — Local notification scheduling
├── Models/
│   ├── SkinModels.swift          — SkinMetricType, SkinMetric, SkinScan, FoodScan, SkinEffect, Trend
│   └── MockData.swift            — Static demo data (unused by any other file)
├── Services/
│   ├── DataStore.swift           — SwiftData CRUD, aggregates, streak, 90-day prune
│   ├── SkinAnalysisService.swift — OpenAI gpt-4.1 vision → SkinScan
│   ├── FoodAnalysisService.swift — OpenAI gpt-4.1 vision → FoodScan
│   └── InsightEngine.swift       — Rule-based insight generation
├── Persistence/
│   └── LocalCache.swift          — SwiftData @Model: CachedSkinScan, CachedFoodScan
└── Resources/
    ├── Info.plist, Secrets.plist, Assets.xcassets, Fonts/, AppStoreMetadata.swift
```

## SPM Dependencies (in project.pbxproj)
- **Kingfisher** 8.x (remote image loading)
- **supabase-swift** 2.x (linked but NOT used anywhere in Swift code yet)

## Phase 1: Rebrand to [NEW_NAME]
Systematically replace "Skinmax"/"skinmax" everywhere:

**User-facing strings (MUST change):**
- `Info.plist`: `CFBundleDisplayName`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`
- `HomeView.swift`: `Text("skinmax")` header → `Text("[new_name]")`
- `AccountView.swift`: "About Skinmax", "Skinmax v1.0"
- `AboutView.swift`: Title, description body, `support@skinmax.app` email
- `FaceScanView.swift`: "Skinmax needs your camera…"
- `AppStoreMetadata.swift`: All marketing copy
- `SkinAnalysisService.swift`: AI system prompt referencing "Skinmax wellness app"

**Identifiers (SHOULD change):**
- `project.pbxproj`: `PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER` (change to `com.marcuschien.[newname].app`)
- `CameraManager.swift`: GCD labels `com.skinmax.camera`, `com.skinmax.facedetection`
- `SkinmaxLog.swift`: Logger subsystem `com.skinmax.app`

**Swift type names (OPTIONAL but recommended):**
- Rename `SkinmaxColors` → `[NewName]Colors`, `SkinmaxFonts` → `[NewName]Fonts`, `SkinmaxSpacing` → `[NewName]Spacing`, `SkinmaxComponents` → rename the file, `SkinmaxApp` → `[NewName]App`, `SkinmaxLog` → `[NewName]Log`
- Update ALL references across the entire codebase when renaming types

**Also update:** `CLAUDE.md` project documentation to reflect new name throughout

## Phase 2: Food-First Home Redesign
Reposition the app to lead with food scanning:

### 2a. Scan Popup (`ScanPopupOverlay` in SkinmaxComponents.swift)
Make food scan the primary action:
- Food scan bubble: larger (wider), left position, bigger emoji/icon, more prominent styling
- Face scan bubble: smaller, right position, secondary styling
- OR: make food scan the default single-tap action on the scan button, with face scan as secondary option

### 2b. Home Dashboard (`HomeView.swift`)
- Add a prominent "Scan Your Food" CTA card near the top (below week strip, above or alongside Glow Score) — this should be the most eye-catching element
- Add a "Food Log" section or button that navigates to `FoodLogView` (currently unreachable)
- Show the latest food scan result summary (food name + skin impact score) if available
- Keep Glow Score but make it feel secondary to the food-first CTA
- Show food streak / today's food count prominently

### 2c. Wire FoodLogView
`FoodLogView` exists with a full calendar UI but is unreachable. Options:
- Make it accessible from the Home "Food Log" section
- OR replace the Analytics tab content with FoodLogView as the primary view, with charts as a sub-section
- OR add a dedicated Food tab

### 2d. Fix FaceScanResultView
- Remove the cosmetic Save button (or change it to "Done" / "Close") — scans are auto-saved by AnalysisCoordinator
- Replace hardcoded "First scan!" text with actual trend comparison from history

## Phase 3: Onboarding Flow (Build New)
Create `Skinmax/Features/Onboarding/`:

1. `OnboardingView.swift` — Container with horizontal TabView paging
2. 3-4 screens:
   - Screen 1: Hook — "Your food is showing on your face" with food → skin visual concept
   - Screen 2: Feature — "Scan any meal. See what it does to your skin."
   - Screen 3: Feature — "Track your Glow Score over time"
   - Screen 4: Permissions — Camera + Notifications request with purpose explanation
3. "Get Started" CTA on final screen
4. Gate with `@AppStorage("hasCompletedOnboarding")` in `SkinmaxApp.swift` or `ContentView.swift`
5. Follow design system: Nunito font, coral/peach palette, spring animations
6. Follow MVVM — create `OnboardingViewModel` if logic warrants it

## Phase 4: Authentication with Supabase (Build New)
Create `Skinmax/Features/Auth/`:

1. `AuthView.swift` — Sign in screen:
   - "Sign in with Apple" button (primary, use `AuthenticationServices`)
   - Email/password fields (secondary option)
   - "Continue without account" option (limited features)
2. `AuthViewModel.swift` — Auth state management
3. `Skinmax/Services/AuthService.swift` — Wraps `supabase-swift` Auth:
   - `signInWithApple()`, `signInWithEmail(email:password:)`, `signUp(email:password:)`, `signOut()`, `currentUser`, `isAuthenticated`
   - Session persistence + auto-refresh
4. `Skinmax/Models/UserProfile.swift` — User model
5. Update `AccountView.swift`: show real user name/email instead of hardcoded "User"
6. Update `SkinmaxApp.swift`: check auth state on launch, show AuthView if needed
7. `supabase-swift` is already in SPM — initialize `SupabaseClient` in a new `Skinmax/Services/SupabaseManager.swift`

## Phase 5: Paywall (Build New)
Create `Skinmax/Features/Paywall/`:

1. `PaywallView.swift` — Paywall screen:
   - Lead with food scanning value: "Unlimited food scans", "AI skin predictions", "Full nutrition breakdown"
   - Monthly ($4.99/mo) and Annual ($29.99/yr, highlight "Save 50%") toggle
   - Feature comparison (Free vs Pro)
   - Restore purchases link
   - Close/skip button
   - Free tier limits: 3 food scans/day, 1 face scan/day
2. `PaywallViewModel.swift` — StoreKit 2 integration
3. `Skinmax/Services/SubscriptionService.swift`:
   - Product fetching from App Store
   - Purchase flow
   - Restore purchases
   - Entitlement checking (`isPro` computed property)
   - Transaction listener for renewals
4. Add scan limit check in `AnalysisCoordinator` before starting analysis — show `PaywallView` when limit reached
5. Store daily scan counts in `@AppStorage` or `DataStore`, reset daily

## Rules — Follow These Exactly
- Read and follow CLAUDE.md for design system, architecture, colors, fonts, spacing
- MVVM architecture: NO business logic in Views — all logic in ViewModels/Services
- All new screens need: empty state, loading state, error state, success state
- Use spring animations: `.spring(response: 0.3, dampingFraction: 0.8)` for personality
- Haptic feedback on: scan capture, score reveal, food log save, purchases, navigation actions
- Keep the liquid glass tab bar style (frosted blur + white overlay)
- Nunito font ONLY — never use system font
- Only colors from the defined palette in `SkinmaxColors`
- Score circles ALWAYS use traffic light colors based on value
- Compress images to JPEG 0.6 quality, max 800px before upload
- Camera sessions on background thread

## Execution Order
Do phases in order (1 → 2 → 3 → 4 → 5). Complete each phase fully before moving to the next. After each phase, verify the app compiles and the changes are coherent. Do NOT skip phases or combine them.
