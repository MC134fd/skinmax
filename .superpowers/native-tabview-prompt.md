# Native iOS 26 Liquid Glass TabView — Migration Prompt

You are migrating the tab bar in an existing iOS app called **Skinmax** from a custom `GlassTabBar` component to Apple's native iOS 26 `TabView` with Liquid Glass. This gives us the stock translucent floating tab bar that Apple uses in Clock, News, and other first-party apps — the same design Cal AI uses.

**Read the codebase before making changes.** Especially: `CLAUDE.md`, `ContentView.swift`, `GlowbiteComponents.swift` (the `GlassTabBar`, `TabItem`, and `ScanPopupOverlay` structs), `GlowbiteColors.swift`, `HomeView.swift`, `AnalyticsContainerView.swift`, `AccountView.swift`.

---

## Scope — What Changes and What Doesn't

### DO change:
- `ContentView.swift` — replace the custom ZStack+GlassTabBar with a native `TabView` using `Tab(...)` API
- `GlowbiteComponents.swift` — remove the `GlassTabBar` struct (it becomes dead code). Keep `ScanPopupOverlay`, `TabItem` enum, and all other components.
- Wire up the scan popup overlay to work with the new native TabView layout
- Ensure content scrolls underneath the native glass tab bar properly

### DO NOT change:
- `GlowbiteColors.swift` — no color changes
- `Typography.swift` — no font changes
- `HomeView.swift`, `AnalyticsContainerView.swift`, `AccountView.swift` — no content changes (only wrapping adjustments if needed)
- `ScanPopupOverlay` — keep the existing two-bubble popup design and behavior
- Any service, model, or data layer files
- `FaceScanView`, `FoodLogSheet`, result views — no changes
- The `TabItem` enum — keep it for reference but the native `Tab` API will handle tab definitions

---

## Section 1: Rewrite ContentView.swift

Replace the current `ContentView` which uses a manual ZStack with a `GlassTabBar` overlay at the bottom. The new version uses Apple's native `TabView` with the `Tab(...)` structural API.

### Current architecture (remove):
```
ZStack {
    creamBG background
    Group { switch selectedTab... }    ← manual tab switching
    VStack { Spacer(); GlassTabBar }   ← custom tab bar overlay
    if showScanPopup { ScanPopupOverlay }
}
```

### New architecture:
```
ZStack {
    TabView(selection: $selectedTab) {
        Tab("Home", systemImage: "house.fill", value: TabItem.home) { ... }
        Tab("Analytics", systemImage: "chart.bar.fill", value: TabItem.analytics) { ... }
        Tab("Account", systemImage: "person.fill", value: TabItem.account) { ... }
    }
    .tint(GlowbiteColors.coral)

    // Scan popup overlay (on top of everything, same as before)
    if showScanPopup { ScanPopupOverlay(...) }
}
```

### Implementation details:

```swift
import SwiftUI

struct ContentView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showScanPopup = false
    @State private var showFaceScan = false
    @State private var showFoodLogSheet = false
    @State private var showFaceResult = false
    @State private var showFoodResult = false
    @State private var faceResultScan: SkinScan?
    @State private var foodResultScan: FoodScan?

    @Environment(AnalysisCoordinator.self) private var coordinator

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house.fill", value: TabItem.home) {
                    HomeView(
                        onViewFaceResult: { scan in
                            faceResultScan = scan
                            showFaceResult = true
                        },
                        onViewFoodResult: { scan in
                            foodResultScan = scan
                            showFoodResult = true
                        },
                        onScanMeal: {
                            showScanPopup = true
                        }
                    )
                }

                Tab("Analytics", systemImage: "chart.bar.fill", value: TabItem.analytics) {
                    AnalyticsContainerView()
                }

                Tab("Account", systemImage: "person.fill", value: TabItem.account) {
                    NavigationStack {
                        AccountView()
                    }
                }
            }
            .tint(GlowbiteColors.coral)
            .tabViewBottomAccessory {
                Button {
                    HapticManager.impact(.medium)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        showScanPopup.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                        Text("Scan")
                    }
                    .font(.gbTitleM)
                }
                .tint(GlowbiteColors.coral)
            }

            // Scan popup overlay
            if showScanPopup {
                ScanPopupOverlay(
                    isPresented: $showScanPopup,
                    onScanFace: {
                        showFaceScan = true
                    },
                    onLogFood: {
                        showFoodLogSheet = true
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showFaceScan) {
            FaceScanView()
        }
        .fullScreenCover(isPresented: $showFoodLogSheet) {
            FoodLogSheet()
        }
        .fullScreenCover(isPresented: $showFaceResult) {
            if let scan = faceResultScan {
                FaceScanResultView(scan: scan)
            }
        }
        .fullScreenCover(isPresented: $showFoodResult) {
            if let scan = foodResultScan {
                FoodScanResultView(scan: scan)
            }
        }
    }
}
```

### Key decisions:

1. **`.tabViewBottomAccessory`** — This is the iOS 26 API that places a floating Liquid Glass button above the tab bar. It replaces our custom 56pt coral circle scan button. The button automatically gets the glass treatment from the system. Use `HapticManager.impact(.medium)` on tap, same as before.

2. **`.tint(GlowbiteColors.coral)`** — This makes the active tab icon and label use our Hero Coral instead of iOS default blue. The system handles the inactive state (system gray) automatically.

3. **`TabItem` enum** — Keep it as-is since we use it for the `selection` binding. The enum already conforms to `Int` and `CaseIterable`. The `Tab(value:)` parameter accepts it directly.

4. **No `.tabViewStyle(.sidebarAdaptable)`** — We're iPhone-only, portrait-only. The default tab bar style is what we want. Don't add sidebar adaptable unless we need iPad support later.

5. **`ScanPopupOverlay`** stays in a ZStack on top of the TabView — this overlay dims the screen and shows the two frosted bubbles. Its `.padding(.bottom, 90)` may need adjustment since the native tab bar has different height than our custom one. Test and adjust so the bubbles sit just above the tab bar.

6. **Background color** — The native TabView handles its own background. Each tab's content view should handle its own background (HomeView already sets creamBG). Remove the top-level `GlowbiteColors.creamBG.ignoresSafeArea()` that was in the old ZStack — let each screen own its background.

---

## Section 2: Update ScanPopupOverlay positioning

The `ScanPopupOverlay` currently has `.padding(.bottom, 90)` to sit above the old custom tab bar. The native Liquid Glass tab bar has a different height. Adjust the bottom padding so the two frosted bubbles (Scan Face / Log Food) appear just above the native tab bar.

- Try `.padding(.bottom, 100)` as a starting point — the native tab bar is slightly taller due to the glass material's padding.
- If `.tabViewBottomAccessory` is visible, account for its height too.
- Test on multiple iPhone sizes (SE, 15, 16 Pro Max) in preview/simulator.

---

## Section 3: Remove GlassTabBar from GlowbiteComponents.swift

Delete the entire `GlassTabBar` struct (lines 449-525 approximately in `GlowbiteComponents.swift`). It's now dead code since the native TabView replaces it.

**Keep these in GlowbiteComponents.swift:**
- `TabItem` enum — still used by ContentView's `selection` binding
- `ScanPopupOverlay` — still used for the scan action popup
- All other components (buttons, cards, rings, etc.)

---

## Section 4: Content scrolling under the tab bar

For the Liquid Glass effect to look its best, content should scroll underneath the translucent tab bar. The system handles this automatically for `List` and `ScrollView` within a `TabView` tab. However:

- If `HomeView` uses a `ScrollView`, it should NOT have manual bottom padding to account for the old custom tab bar. Remove any `.padding(.bottom, 80)` or similar that was added to clear the old GlassTabBar.
- Same for `AnalyticsContainerView` and `AccountView` — remove any manual bottom padding that was compensating for the custom tab bar.
- The native TabView automatically adds safe area insets for the tab bar. Content will scroll under the glass naturally.

Search all view files for patterns like:
- `.padding(.bottom, 80)` or similar large bottom padding values
- `.safeAreaInset(edge: .bottom)` related to tab bar height
- Any manual spacing meant to clear the old custom tab bar

Remove these — the system handles it now.

---

## Section 5: Optional enhancements (apply if straightforward)

### 5a. Tab bar minimize on scroll
Add this to the TabView for a premium feel — the tab bar shrinks when the user scrolls down and reappears on scroll-up:

```swift
.tabBarMinimizeBehavior(.onScrollDown)
```

Only add this if the content views use `ScrollView` or `List`. If they use custom scroll implementations, test first.

### 5b. Haptic on tab switch
The old `GlassTabBar` called `HapticManager.selection()` on tab switch. The native TabView doesn't do this automatically. Add an `.onChange(of: selectedTab)` modifier to the TabView:

```swift
.onChange(of: selectedTab) { _, _ in
    HapticManager.selection()
}
```

### 5c. Scan button alternative — if `.tabViewBottomAccessory` doesn't look right

If the `.tabViewBottomAccessory` button doesn't match our desired scan button design (we want a prominent coral action button, not just a text link), we can instead overlay a custom scan button on top of the TabView:

```swift
ZStack {
    TabView(selection: $selectedTab) { ... }
        .tint(GlowbiteColors.coral)

    // Custom scan button floating above native tab bar
    VStack {
        Spacer()
        Button {
            HapticManager.impact(.medium)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                showScanPopup.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(GlowbiteColors.heroGradient)
                    .frame(width: 56, height: 56)
                    .shadow(color: GlowbiteColors.buttonGlowColor, radius: 8, x: 0, y: 4)

                Image(systemName: "camera.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(showScanPopup ? 45 : 0))
            }
        }
        .padding(.bottom, 70) // position above the native tab bar
    }

    // Scan popup overlay
    if showScanPopup { ScanPopupOverlay(...) }
}
```

**Decision rule:** Try `.tabViewBottomAccessory` first. If it looks native and clean, use it. If we need the big coral circle button for brand identity, use the overlay approach instead. The overlay approach is closer to what we had before but now sits on top of the native glass tab bar.

---

## Section 6: Availability check

The `Tab(...)` structural API requires iOS 18+. The `.tabViewBottomAccessory` requires iOS 26+. Since we target iOS 17+ per CLAUDE.md:

**Option A (simplest, recommended):** Bump minimum deployment target to iOS 26. The Liquid Glass tab bar only exists on iOS 26. If the whole point is to use the native design, just target iOS 26.

**Option B (backward compat):** Wrap in `#available` checks:
```swift
if #available(iOS 26, *) {
    // native TabView with .tabViewBottomAccessory
} else if #available(iOS 18, *) {
    // native TabView with Tab(...) API, custom scan button overlay
} else {
    // old GlassTabBar approach (keep as fallback)
}
```

This is more work. Recommend Option A unless you need to support older devices.

**Choose one approach and implement it consistently.** Don't half-migrate.

---

## Hard Constraints

1. **No color changes.** Use existing `GlowbiteColors` tokens exactly as-is.
2. **No font changes.** Keep all `.gb*` font extensions.
3. **Keep 3 tabs.** Home, Analytics, Account — same icons, same labels.
4. **Keep scan popup.** The `ScanPopupOverlay` two-bubble design stays identical — only positioning may adjust.
5. **Keep all fullScreenCover presentations.** FaceScan, FoodLogSheet, FaceScanResult, FoodScanResult — wired the same way.
6. **Keep `AnalysisCoordinator` environment.** The `@Environment(AnalysisCoordinator.self)` stays in ContentView.
7. **Must compile.** After the migration, the project must build with zero errors.
8. **Don't touch view content.** HomeView, AnalyticsContainerView, AccountView internal layouts don't change — only how they're hosted inside the TabView.

---

## Implementation Phases (commit after each)

### Phase 1: Migrate ContentView to native TabView
- Rewrite `ContentView.swift` with native `TabView` + `Tab(...)` API
- Add `.tint(GlowbiteColors.coral)` and `.onChange` haptic
- Wire scan button via `.tabViewBottomAccessory` or overlay (pick one)
- Keep all fullScreenCover and ScanPopupOverlay wiring
- Build and verify
- **Commit:** "Migrate to native iOS 26 Liquid Glass TabView"

### Phase 2: Clean up dead code
- Remove `GlassTabBar` struct from `GlowbiteComponents.swift`
- Keep `TabItem` enum and `ScanPopupOverlay`
- Remove any bottom padding hacks from content views that were compensating for the custom tab bar
- Build and verify
- **Commit:** "Remove custom GlassTabBar and tab bar padding workarounds"

### Phase 3: Polish and test
- Adjust `ScanPopupOverlay` bottom positioning for native tab bar
- Test on multiple device sizes in simulator
- Add `.tabBarMinimizeBehavior(.onScrollDown)` if scroll views support it
- Verify all screens render correctly
- **Commit:** "Polish native tab bar integration and scan popup positioning"
