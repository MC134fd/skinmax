# Claude Code Prompt — Build Analytics v7

Copy everything below the `---` line into Claude Code to build this out.

---

# Task: Rebuild `AnalyticsContainerView` based on the design at `designs/analytics-v7.html`

I've mocked up a new Analytics/Progress screen for Glowbite at `/Users/marcuschien/code/MC134fd/skinmax/designs/analytics-v7.html`. Before writing any code, open that file and the existing `Skinmax/Features/Analytics/AnalyticsContainerView.swift` so you understand both the target design and what's currently shipping. Also read `CLAUDE.md` — the design system is fully documented there and you must follow it exactly (palette, fonts, shadows, squircle rule, scanner brackets rule, etc.).

Do not invent colors or fonts. Use only what exists in `GlowbiteColors.swift` and the `.gb*` extensions in `Typography.swift`.

## What to build

A full rewrite of `AnalyticsContainerView.swift` plus the supporting subviews it needs. The screen has five top-to-bottom sections:

### 1. Sticky header + time-range toggle
- Brand mark + "Progress" label on the left, user avatar on the right (match `HomeView`'s header pattern)
- Underneath: a 4-pill segmented control with options `Today / Week / Month / Year`, default `Week`. Active pill gets `Deep Espresso (#1A1510)` fill with white text; inactive pills are white with a hairline border and taupe text. Shape is a single pill container with segmented backgrounds.
- The header + toggle should stay at the top of the scroll area (not the system nav bar).

### 2. Shareable Moments row
Horizontal scrolling carousel of 4 share cards, each with `9:16` aspect ratio, 120pt wide. Each card is `RoundedRectangle(cornerRadius: 16, style: .continuous)` with its own color treatment:

- **Glow-up card**: warm beige gradient, emoji top-left (✨), big delta bottom-left (`+18`), subcopy (`30 days`)
- **Best month card**: dark espresso bg (`#1A1510`), emoji (🏆), big number (`78`), subcopy (`personal best`)
- **MVP food card**: forest green gradient (`#5B8A63` → `#4A7C59`), emoji (🥑), `+8.8`, subcopy (`avocado`)
- **Streak card**: coral gradient (`#E07A5C` → `#C24A1E`), 🔥 emoji, `12`, subcopy (`days`)

Cards use `ScrollView(.horizontal, showsIndicators: false)`. Add a small "NEW" gold pill badge (top-right) on cards the user hasn't tapped yet. Above the row, a small uppercase eyebrow label in `Terracotta Coral` that reads `• SHAREABLE MOMENTS` with a pulsing coral dot prefix (`Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)`).

Tapping a card opens a full-screen `ShareCardSheet` (SwiftUI sheet, detents `.large`) that will eventually render the final share-card at full resolution — for now, just present a placeholder sheet with the same card content scaled up and a "Share to TikTok / Reels" button.

### 3. The 4 feature sections (from top to bottom, alternating backgrounds)

Each section is a full-width container with `28pt` vertical padding and `20pt` horizontal padding. Backgrounds alternate to make the sections obvious at a glance:

| # | Section | Background |
|---|---------|------------|
| 1 | The Glow-Up | `Blush` (new color — add to `GlowbiteColors`: `#FFE5D9`) |
| 2 | The Trend | `Cream BG` (existing) |
| 3 | What's Working | White |
| 4 | Cycle & Skin | `Cream BG` |

Each section starts with a section header in this format:
- Numbered eyebrow label (numbered circle + uppercase tag text, e.g. `1 · THE GLOW-UP`) in coral
- Optional right-aligned "More →" link in taupe
- Big bold 24pt headline using `.gbTitleL` in Deep Espresso
- 13pt subhead in Medium Taupe

#### Section 1 — The Glow-Up
- Two side-by-side photo tiles (`1:1.3` aspect ratio) inside a 6pt-gap `HStack`, `cornerRadius: 10, style: .continuous`
- Left photo is "before", right photo is "after"
- Each has a top-left caption overlay with the date (e.g. `MAR 19`) in 9pt caps white on dark scrim
- Each has a bottom-left score pill (white bg, `glow 64` / `glow 82`)
- The after-pill uses coral text; before-pill uses Deep Espresso
- Below the photos: a 3-column `HStack` with delta stats (`Glow ↑18`, `Clarity ↑18`, `Redness ↓15`) separated by thin `Divider()`s. Each has a 9pt uppercase label + big number. Up arrows in Forest Green, down arrows in Coral.
- At the bottom: a dark **Share Preview panel** — `RoundedRectangle(cornerRadius: 18, style: .continuous)` with Deep Espresso fill, white text. Inside: a small (`64pt × 114pt`) 9:16 thumbnail on the left showing a mini version of what will be shared, then copy ("Share your glow-up" + "A 9:16 before/after reel for TikTok or Reels"), and two buttons: a white primary button ("Share") and a secondary outlined button ("Edit").

#### Section 2 — The Trend
- Hero row: big 68pt number (`78`) on the left using `.gbDisplayL` in Deep Espresso; on the right: a small green delta pill (`▲ +8 pts`) above a 10pt caption (`30-DAY AVG · WAS 70`).
- Horizontal rule (1pt hairline using `Color(hex: "1A1510").opacity(0.06)`).
- Sparkline chart area, 140pt tall. Use `Swift Charts` with:
  - Line in Deep Espresso at 2.2pt stroke
  - Three horizontal dashed gridlines in `#E8DFD0`
  - Dashed average line in Light Taupe
  - A gold dot (`#C9A24E`) at the personal-best point with a tiny 🏆 label above it
  - A coral dot (`#C24A1E`) at today's point, white stroke 2.5pt
  - X-axis labels below in 9pt caps taupe (e.g. `MAR 19 / APR 2 / APR 18`)
- **Personal Best callout** — a gold-tinted card (`#FFF3D4` → `#F5E3B3` gradient, `cornerRadius: 12, style: .continuous`, `rgba(201,162,78,.25)` border). Inside: a 🏆 emoji (22pt), then "New personal best: 89 on April 10" as title, a subcopy ("Your highest glow score ever. Salmon lunch + 8h sleep."), and a small white Share pill button on the right.
- **2×2 metric grid** — four white cards in a `LazyVGrid` with 10pt spacing. Each card: top row with colored-dot name (Hydration/Texture/Clarity/Redness) + delta, big value (24pt), and a 3pt bar with color fill. Use the existing semantic colors (Hydration Blue, Forest Green, Coral, Warm Amber).
- **Streak + Milestone tile** — coral gradient (`#E07A5C` → `#C24A1E`) full-width card. Inside: 🔥 emoji (32pt, left), "12-day streak" title + subcopy ("3 more days until your 15-DAY BLAZE badge 🏅"), and on the right a dashed-outline circle (50pt) containing the preview badge icon. Bottom: a white 3pt progress bar at 80% fill.

#### Section 3 — What's Working
- Headline: `Your skin loves avocado.` (italicize "avocado" using `.italic()` and color `Terracotta Coral`)
- **MVP tile** — white card, `cornerRadius: 18, style: .continuous`. Inside, an `HStack`: a 64pt squircle with green gradient containing the 🥑 emoji at 40pt; then name + description stacked vertically. Top-right: a small green "MVP" pill. Below, a hairline divider and a 3-column stat row (`Avg glow lift: +8.8`, `Times eaten: 14`, `Best streak: 6 days`).
- **Ranked list card** — white card with an 10pt caps header ("Next-best foods for you"), then 3 rows: rank circle (`Peach Wash` bg, coral text) + emoji + name/why + score. Thin hairlines between rows.
- **Share preview panel** (same dark-mode pattern as Section 1), green-tinted thumbnail showing "MY GLOW RECIPE". Buttons: Share + Edit.

#### Section 4 — Cycle & Skin
- Header tag uses `Deep Purple (#8B5CF6)` instead of coral (swap the numbered circle + tag text color).
- Headline: `You're in luteal.` (italicize "luteal", purple)
- Subhead: `Day 18 of 28. Your skin usually pushes back now.`
- **Cycle hero row** — `HStack(spacing: 16)`: an 84pt `Canvas`-drawn ring (purple gradient `#CE93D8` → `#8B5CF6`, stroke 7pt, rounded cap) with `18 / of 28` centered inside. On the right: a purple phase chip (`rgba(139,92,246,.12)` bg), a 16pt "Breakout window" title, and a short description.
- **4-column phase strip** — 4 equal tiles in a `LazyVGrid`. Three are light (cream bg, hairline border, taupe labels, ink names); the active one (Luteal) uses solid purple bg with white text.
- **Cycle insight card** — `rgba(139,92,246,.07)` background, 1px purple-tinted border. 💡 emoji icon in a white 30pt squircle on the left, then "Tonight's move" title + body ("**Skip retinol** — your skin's more reactive this phase. Layer hyaluronic acid + a barrier cream instead.") with "Skip retinol" bolded in purple.

### 4. Monthly Wrapped section (new, at the very bottom)
- Full-width dark section (`#1A1510` → `#2A221B` linear gradient), 32pt vertical padding
- Decorative radial-gradient blobs (coral + gold) positioned absolutely behind the content — use `GeometryReader` + `ZStack` with blurred overlays
- Header row: `✨ YOUR APRIL IN GLOWBITE` eyebrow (peach color `#FFD3B8`) on the left, `APR 2026` caption on the right
- 30pt bold headline: `Your glowiest month yet.` (italicize "glowiest" in gold `#E8C878`)
- Subhead in `rgba(255,255,255,.6)`
- 2×2 grid of semi-transparent stat cards (`rgba(255,255,255,.06)` bg, border `rgba(255,255,255,.08)`): Avg glow, Best day, MVP food, Streak
- Bottom CTA: a white full-width card with "📲 Share my April wrap" text + coral arrow →. Tapping opens a full-screen `MonthlyWrapSheet` (placeholder for now).

### 5. Existing tab bar + scan FAB
The screen already renders inside the app's `ContentView` with the shared tab bar and scan button. Don't re-add them — just make sure the last section has 120pt of bottom padding so the Wrapped CTA isn't covered.

## Data + ViewModel

Create `AnalyticsViewModel.swift` as an `@Observable @MainActor final class`. For now, have it expose hardcoded mock data matching what's in the mockup so the view can render without a backend. Fields:

```
let glowUp: GlowUpData  // before/after photos, dates, delta scores
let trend: TrendData    // avg, delta, chart points, today, personalBest
let streak: StreakData  // current count, nextMilestoneDays, nextBadgeName
let metrics: [MetricData]  // hydration/texture/clarity/redness with value + delta
let foods: FoodInsightData  // MVP food + ranked list
let cycle: CycleData    // phase, day, totalDays, tonightTip
let moments: [ShareableMoment]  // the 4 moment cards
let aprilWrap: WrappedData  // avg glow, best day, MVP, streak summary
```

All types should be plain `Codable` structs placed in `Models/AnalyticsModels.swift`. Use `nil` where data might not exist (e.g. `personalBest: PersonalBest?` so the callout only renders when there's an actual PB).

**Conditional rendering is important.** The shareable-moments row, personal-best callout, streak-milestone tile, and monthly-wrap card should each only render when their data is present. Otherwise skip them — don't show empty/placeholder states.

## New files to create

- `Skinmax/Features/Analytics/AnalyticsContainerView.swift` — full rewrite
- `Skinmax/Features/Analytics/AnalyticsViewModel.swift` — new
- `Skinmax/Features/Analytics/Sections/GlowUpSection.swift` — section 1
- `Skinmax/Features/Analytics/Sections/TrendSection.swift` — section 2
- `Skinmax/Features/Analytics/Sections/WhatsWorkingSection.swift` — section 3
- `Skinmax/Features/Analytics/Sections/CycleSection.swift` — section 4
- `Skinmax/Features/Analytics/Sections/MonthlyWrapSection.swift` — section 5
- `Skinmax/Features/Analytics/Components/ShareableMomentsRow.swift` — top carousel
- `Skinmax/Features/Analytics/Components/SharePreviewPanel.swift` — the dark share preview
- `Skinmax/Features/Analytics/Components/PersonalBestCallout.swift` — gold tinted card
- `Skinmax/Features/Analytics/Components/StreakMilestoneTile.swift` — coral gradient tile
- `Skinmax/Features/Analytics/Components/MetricGridCard.swift` — the 2×2 tile
- `Skinmax/Features/Analytics/Components/SectionHeader.swift` — numbered eyebrow + title + subhead
- `Skinmax/Features/Analytics/Components/TimeRangeToggle.swift` — segmented pill
- `Skinmax/Features/Analytics/Sheets/ShareCardSheet.swift` — placeholder full-screen share sheet
- `Skinmax/Features/Analytics/Sheets/MonthlyWrapSheet.swift` — placeholder full-screen wrap sheet
- `Models/AnalyticsModels.swift` — all the data structs

Also add:
- `Color Blush` (`#FFE5D9`), `Color Gold` (`#C9A24E`), `Color Gold Lt` (`#E8C878`), `Color Coral Pink` (`#E07A5C`) to `GlowbiteColors.swift` — these four hexes are new and the design needs them.

## Rules I want you to follow strictly

- **No UIKit unless absolutely necessary** (SwiftUI only for all view code).
- **Every `RoundedRectangle` must use `style: .continuous`** — the squircle rule from `CLAUDE.md`.
- **No `.font(.system(...))`** — always `.gb*` extensions. Use the sizes specified in `Typography.swift`.
- **No `Color.black` shadows** — always `Color(hex: "C24A1E").opacity(...)`. Use the `GlowbiteColors.cardShadowColor` etc. helpers.
- **Haptics on every interactive element** — `.medium` on buttons, `.selection` on segmented-toggle change, `.success` on share-card tap.
- **Every state must render correctly** — loading (show a subtle skeleton), empty (hide the section entirely), error (show a small inline retry card, not a full takeover).
- **Dynamic Type support** — add `.lineLimit` and `.minimumScaleFactor` on any text that could overflow; test at xxxLarge.
- **Accessibility labels** on the share cards, personal-best callout, streak tile, and any chart markers.

## Order of operations

Follow this order so the build stays green:

1. **Add the new colors** (`Blush`, `Gold`, `Gold Lt`, `Coral Pink`) to `GlowbiteColors.swift`. Verify build.
2. **Create `AnalyticsModels.swift`** with all the data types + mock data fixtures.
3. **Create `AnalyticsViewModel.swift`** exposing a `static let mock` instance. Verify build.
4. **Create the small shared components first** (SectionHeader, TimeRangeToggle, MetricGridCard, SharePreviewPanel, PersonalBestCallout, StreakMilestoneTile). Each should have its own `#Preview` with mock data. Verify each preview renders.
5. **Create the 5 sections** one at a time. Each should have a `#Preview`. Verify each renders.
6. **Create the sheets** (ShareCardSheet, MonthlyWrapSheet) as placeholders. Verify.
7. **Create `ShareableMomentsRow`**. Verify preview.
8. **Rewrite `AnalyticsContainerView`** — compose everything, handle time-range state, pull from view model. Make sure it scrolls smoothly and the sticky header + toggle stay at the top.
9. **Run the app.** Navigate to the Progress tab. Scroll through the whole screen. Verify every section renders, every tappable area responds to haptics, no console errors.

Please write the code in small, reviewable increments — each step should compile and be previewable before moving to the next. Show me the diffs as you go so I can follow along.

## What to report when done

- List of every file created/changed
- Screenshots of each section in the preview
- Any deviations from the mockup with the reason
- Anything you couldn't figure out or that needs design input from me
- Estimated remaining work if anything's deferred (e.g. actual share-card generation, real photo crops from scan history)
