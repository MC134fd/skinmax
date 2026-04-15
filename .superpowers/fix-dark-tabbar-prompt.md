# Fix Dark Tab Bar on Tab Switch — Implementation Prompt

The native iOS 26 Liquid Glass tab bar turns dark when switching from Home to Analytics (and potentially other tabs). The glass material refracts whatever content sits behind it — when darker content (charts, colored cards) is near the bottom of the screen, the tab bar picks up those tones and appears dark.

**The fix:** Increase bottom padding on all tab content views so that only the light cream background (`GlowbiteColors.creamBG`) sits behind the tab bar area. This keeps the glass consistently light across all tabs.

**Read before making changes:** `ContentView.swift`, `HomeView.swift`, `AnalyticsContainerView.swift`, `AccountView.swift`.

---

## What to Change

### 1. Increase bottom padding on all three tab content ScrollViews

The native tab bar + bottom accessory button together take roughly 100pt of space at the bottom. Content needs enough bottom padding so no cards/charts/colored elements are behind the glass.

**HomeView.swift** — line 42:
```
// Change:
.padding(.bottom, 20)
// To:
.padding(.bottom, 120)
```

**AnalyticsContainerView.swift** — line 119:
```
// Change:
.padding(.bottom, 20)
// To:
.padding(.bottom, 120)
```

**AccountView.swift** — line 33:
```
// Change:
.padding(.bottom, 20)
// To:
.padding(.bottom, 120)
```

120pt gives comfortable clearance so the last content element scrolls well above the tab bar zone, leaving only cream background behind the glass.

### 2. That's it

Don't change `ContentView.swift`. Don't change colors. Don't change the TabView setup. Don't add `.toolbarBackgroundVisibility` — we want to keep the Liquid Glass effect, just ensure it always has a light background behind it.

---

## Hard Constraints

1. **Only change bottom padding values** in the three tab content views listed above.
2. **Don't touch ContentView.swift** — the TabView, tint, bottom accessory, and scan popup are correct.
3. **Don't change any colors, fonts, or layouts.**
4. **Don't add `.toolbarBackgroundVisibility(.hidden)`** — we want the glass effect, just with consistent light background.
5. **Must compile** after changes.

---

## Verification

After applying the fix:
1. Build the project — should compile with zero errors.
2. Run on simulator.
3. Switch between Home → Analytics → Account tabs.
4. The tab bar should look consistently light/translucent on all three tabs.
5. Scroll content on each tab — the tab bar should stay light because only cream background is behind it.
6. The tab bar minimize-on-scroll behavior (`.tabBarMinimizeBehavior(.onScrollDown)`) should still work.
