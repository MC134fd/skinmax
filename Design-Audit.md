# Glowbite — Design Audit & Improvement Plan

_Date: 2026-04-16 · Reviewer: Claude (PM + iOS + UI Design)_

This is a screen-by-screen teardown of the current build, plus prioritized fixes. I focused on what's actually shipping in code, not the spec — so every issue below is something a tester can reproduce.

---

## 🚨 The 3 Things to Fix Before Anything Else

**1. Brand color drift.** `Core/Design/GlowbiteColors.swift` uses `#C24A1E` for coral. The brand spec (and CLAUDE.md) says `#FF7A5C`. Every screen is shipping with the wrong primary. This is a one-file fix that visually transforms the entire app — it should be the first PR.

**2. Three system-font violations.** `.font(.system(...))` is forbidden by the design system but appears at:
- `AnalyticsContainerView.swift:311`
- `ProgressView_.swift:209`
- `SkinDetailView.swift:69`

Replace each with the appropriate `.gb*` extension. ~15 minutes of work; eliminates a category of regression.

**3. `FoodLogSheet` is mostly missing.** The file is named `FoodCaptureView.swift` and only implements the camera step. The 3-step flow in the spec (text input → photo → analyze CTA) doesn't exist yet. This is the most important screen for the unique value prop ("food → skin score") and currently the weakest experience.

---

## Screen-by-Screen Teardown

I've ranked each screen on a 1–5 scale: **Build** (how much exists) and **Polish** (how close to brand). Anything ≤ 3 is the priority.

### 1. HomeView — Build 4 / Polish 3
The signature screen. Layout is mostly right, but it's where users will live so polish matters most.

What to fix:
- **Hardcoded `.padding(.bottom, 120)`** for floating tab clearance (line 28). Will break on iPad and on devices where tab bar resizes for accessibility text. Use a `@Environment` reader or a layout preference key so the home content always clears the actual tab bar.
- **Empty state for the metric carousel is missing.** When a new user hasn't scanned yet, the carousel just renders empty pages. Add a "✨ Take your first scan to see your glow metrics" card with a CTA to the scan button.
- **Meals empty state (lines 301-330)** uses corner radius 12 — below the spec minimum of 16 for cards. Bump to 20 and add the Cream Peach gradient background spec'd in CLAUDE.md so it feels warm, not blank.
- **Streak badge has no `.accessibilityLabel`** (lines 55-70). VoiceOver users hear nothing. Add `"7 day streak"` (or whatever the count is).
- **Greeting is the same all day.** Add time-of-day variants ("Morning, glow girl 🌅" / "Hey bestie, mid-day check-in ✨" / "Evening glow report 🌙") — costs nothing, hugely on-brand.

### 2. AnalyticsContainerView — Build 4 / Polish 2
The dual-line chart is the differentiator and currently the most off-brand screen.

What to fix:
- **Y-axis bug.** Both skin (0–100) and food (0–10) lines plot on the same 0–100 axis (line 173). Food line will look flat at the bottom. Use a dual-axis chart, or normalize food to 0–100 by multiplying by 10 with a clear label.
- **`.font(.system(size: 16))` on emoji at line 311.** Use `.gbBodyL`.
- **AI Insights section (lines 308-329)** doesn't follow the spec's emoji-circle pattern. Wrap each insight emoji in a 40pt Cream Peach circle, then title (`.gbTitleM`) + body (`.gbBodyM`). This visual hierarchy is what makes insights feel like advice from a friend, not a console log.
- **Time range toggle** lacks haptic feedback on switch. Add `.selection` haptic.
- **Empty chart state** uses `.system(size: 40)` for the emoji and feels barren. Add an illustration + copy: "Once you've got a few scans, your trend lines will show here ✨".

### 3. AccountView — Build 5 / Polish 3
Functionally complete but feels unloved compared to home.

What to fix:
- **Avatar is just an "U" placeholder** (lines 47-50). Even without photo upload, generate a coral gradient circle with the user's first initial in `.gbDisplayM`. Costs nothing and looks branded.
- **Stat cards use `.gbTitleL`** for numbers, but the spec calls for `.gbDisplayM` for important stats. Bigger numbers feel more like an achievement.
- **"About Glowbite" label vs. "About" sheet title** — pick one. Recommend "About Glowbite" everywhere; reinforces the brand.
- **No member-since fallback.** If formatter fails, the user sees nothing. Show `"New member"` as a graceful default.

### 4. ProgressView_ — Build 2 / Polish 2
This is the most under-built screen relative to its promise.

What to fix:
- **No actual before/after photos.** The spec sells "before/after photo comparison" but the screen renders gradient circles where photos should go (lines 54-70). Either ship the photo comparison or rename this screen until photos are wired up — currently it overpromises.
- **`.font(.system(size: 40))` for 📸 emoji** at line 209. Replace with `.gbDisplayM`.
- **Timeline scrubber doesn't support swipe** despite "scrubber" naming. Add a `DragGesture` so users can scrub like a video timeline. This is the kind of micro-delight the audience loves.
- **Active timeline dot jumps from 8pt to 12pt with no animation.** Wrap in `.animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedIndex)`.
- **Key Changes silently hides changes <5%.** A user with subtle improvements sees nothing. Show all changes with "Small lift in hydration ✨" copy for sub-5% items.

### 5. ScanHistoryView — Build 4 / Polish 3
Functional but rows feel like a default `List`, not a Glowbite screen.

What to fix:
- **Haptic timing bug.** `HapticManager.notification(.warning)` fires _before_ delete confirmation closes (line 53). Fire it on confirmation tap instead.
- **No row separators.** `.listRowSeparator(.hidden)` is on but no custom dividers added — rows visually merge during scroll. Add 1pt Soft Tan dividers with 16pt horizontal inset.
- **No tap feedback.** Rows don't scale or highlight when tapped. Wrap in a custom `ButtonStyle` that applies `.scaleEffect(0.97)` on press.
- **Date headers missing.** Group scans by "Today / Yesterday / This Week / Earlier" — adds chronological warmth.

### 6. NotificationSettingsView — Build 5 / Polish 3
Done but plain.

What to fix:
- **iOS native Toggle doesn't match brand.** Build a custom pill toggle: 50pt × 30pt capsule, Hero Coral when on, Soft Tan when off, with a white circular handle that springs across. Code is ~20 lines.
- **Icon emojis at `.system(size: 18)`** (line 60). Use `.gbBodyL`.
- **Times like "9:00 AM" are hardcoded.** Use `DateFormatter` with `.timeStyle = .short` so users in 24h locales see "09:00".
- **Add a "Test notification" button** at the bottom — lets users verify it works before they leave. Tiny feature, big trust signal.

### 7. DataSettingsView — Build 4 / Polish 3
Functional but missing the warm Glowbite voice.

What to fix:
- **Delete button uses `redAlert (#B23A2C)`** which isn't in the brand spec. Use Soft Red `#E57373` with a coral border for emphasis. Destructive but on-brand.
- **No confirmation toast after delete.** `FaceScanResultView` shows "Scan saved! ✨" — same pattern should apply here ("Your data has been cleared 💫").
- **Stats use `.gbBodyM`** but they're the most important info on the screen. Bump to `.gbTitleM` or `.gbDisplayM`.
- **Copy is too clinical.** "Data Retention: 90 days" → "We keep your scans for 90 days, then they vanish ✨ (You can delete anytime.)"

### 8. AboutView — Build 3 / Polish 4
Looks nice but has dead links.

What to fix:
- **Privacy Policy and Terms buttons call empty `{}` actions** (lines 72-90). These are App Store rejection risks — Apple will reject the binary if Privacy Policy doesn't open something. Wire to a hosted URL (or a `Text` sheet with the policy content) before submission.
- **`mailto:` link has no fallback** if Mail isn't installed. Use `UIApplication.shared.canOpenURL` first; if false, show "Email us at hello@glowbite.app" as text.
- **Color contrast issue** — `.lightTaupe` text on cream background may fail WCAG AA. Test with the Accessibility Inspector; bump to `.mediumTaupe` if needed.

### 9. ScanPopupOverlay — Build 4 / Polish 2
This is the most touched interaction in the app and currently feels imbalanced.

What to fix:
- **Dim overlay too light.** Line 478 uses `.opacity(0.3)` of an already semi-transparent color, ending up around 9% practical opacity. Use solid `Color(hex: "2B1F1A").opacity(0.35)` so the bubbles pop.
- **Inconsistent bubble weight.** "Scan Face" uses peach at 70% opacity; "Log Food" uses green at 15% opacity. Food bubble looks like it's disabled. Match opacities (both at 60-70%) and let the icon tint differ instead.
- **No tap scale on bubbles.** Add `.scaleEffect(isPressed ? 0.95 : 1)` with spring animation. Compare to `ActionButton` at line 385 — same treatment.
- **Tab bar scan button rotation** is great. Worth doubling down: also pulse the bubbles on entry with a 0.05s stagger between left and right for a playful reveal.

### 10. FaceScanView — Build 4 / Polish 3
Camera works; UX around it needs warmth.

What to fix:
- **`Color.black.ignoresSafeArea()`** for permission denied state (line 222) feels punishing. Replace with a Cream Base background, friendly illustration, and copy: "We need camera access to read your glow ✨ Tap to grant."
- **Forever-pulsing animation drains battery** (lines 121-135) and never stops, even when app backgrounds. Add `.onDisappear { animationActive = false }`.
- **Dashed oval flickers** during animation (8,6 dash pattern). Switch to solid stroke when face is detected — visual feedback the system is "locked on."
- **Capture button has no haptic.** Add `.medium` impact on tap.
- **Add a 3-2-1 countdown** option for users who want to set the phone down — common with Gen Z mirror selfies.

### 11. FaceScanResultView — Build 4 / Polish 3
The reveal moment. Good bones, missing the wow.

What to fix:
- **Score ring uses Peach Light hardcoded** (lines 94-111) instead of traffic light colors based on score. A 35 score should glow Soft Red, not peach. This breaks the entire scoring language.
- **Same `.padding(.bottom, 40)` tab bar assumption.** Use a layout preference key.
- **No `.accessibilityValue` on the ring.** VoiceOver should read "Glow score 78 out of 100, good".
- **Add confetti animation** on score reveal when score > 80. Tiny moment of celebration that screenshots well for TikTok.
- **Share button is missing.** This is a screenshot-the-result-and-post-it audience. Add a "Share my glow ✨" button that generates a beautiful share card.

### 12. SkinDetailView — Build 3 / Polish 3
Drilled-in metric view; functional but flat.

What to fix:
- **`.font(.system(size: 16))` at line 69** — replace with `.gbBodyL`.
- **Animation timing is 0.6s** but spec says 0.4s for interactive elements. Speed it up — feels sluggish currently.
- **No haptic on view appear.** Add `.selection` haptic on push so it feels weighted.
- **Tip cards need variety.** Currently shows generic "Drink more water" — pull from a curated content library so users see new tips per metric per session.

### 13. FoodLogSheet — Build 1 / Polish 2
**This is the biggest gap in the app.** The spec is a 3-step form; the build is a single camera capture.

What to fix (in order):
- **Rename the file** from `FoodCaptureView.swift` to `FoodLogSheet.swift` to match the spec and the rest of the codebase.
- **Build the 3-step flow:**
  1. Text field at top: "What did you eat?" — required, autofocus on appear.
  2. Two side-by-side option cards: "Take Photo 📸" and "Choose Photo 🖼️".
  3. Bottom CTA: "Analyze with AI ✨" — disabled (40% opacity, no shadow) until both name + photo are present, full coral gradient pill when ready.
- **Loading state.** Default iOS spinner is currently used. Build a custom one — animated sparkle ring in coral. Copy: "Reading your meal… ✨" then "Calculating skin impact… 🌟" then "Almost there 💫".
- **"Meal" fallback name** is unfriendly. If user skips name, prompt: "Wanna name this? (or we'll just call it 'Mystery snack 🤷‍♀️')".
- **Retry on failure.** No graceful error UX exists. Add a "Try again" button with copy: "Hmm, that didn't work. Let's try once more ✨".

### 14. FoodScanResultView — Build 4 / Polish 3
Reveal screen for food impact. Solid skeleton.

What to fix:
- **Hardcoded async stagger delays** (lines 67-78) at 0.3s and 0.6s are fragile. Use `.transition` modifiers with `.delay` modifiers driven by a single `revealedSections` state set, so all timing is in one place.
- **Nutrition grid breaks on small screens.** 4 columns at 375pt is cramped. Use a 2×2 grid on screens <390pt; 4 columns on Pro Max.
- **No partial-data warning.** If GPT-4o returns null protein, the cell shows blank. Show "—" with a subtle "Couldn't read this 🤷‍♀️" in light taupe.
- **Skin effect tags** are great but limited. Add "Why?" expansion — tap a tag to see a 1-line explanation ("Hydration ↑ because cucumber is 96% water").
- **Add a "Log this meal" button** at the bottom. Users may want to view results without committing them to history.

---

## 🎨 Cross-Cutting Improvements (Apply Everywhere)

These aren't tied to one screen but lift the whole app:

**Motion language.** Standardize on three speeds: 250ms ease-out for transitions, spring(0.4, 0.75) for interactive, spring(0.5, 0.7) for reveals. Audit and unify any timing that drifts (I found at least 3 inconsistencies).

**Haptics audit.** Every interactive surface should haptic. Currently inconsistent — buttons yes, toggles no, list rows no, tab switching yes. Build a `HapticManager.standard()` helper used by every interactive element.

**Empty states are missing across the board.** Build a reusable `GlowbiteEmptyState` component: emoji circle (Cream Peach), title (`.gbTitleM`), body (`.gbBodyM`), optional CTA. Use everywhere.

**Loading states are inconsistent.** Some screens use iOS default `ProgressView`, others have custom spinners, others have nothing. Build one canonical loader: a coral gradient sparkle ring at 32pt with brand-voice copy below.

**Dynamic Type support is absent.** Nothing scales for accessibility text size. Audit every `.padding`, `.frame(width:)`, and text container — add `.lineLimit` and `.minimumScaleFactor` defensively.

**Onboarding is missing.** The app has no first-run experience. A 3-screen onboarding (1: "Track your skin's glow", 2: "Connect food → skin", 3: "Notifications setup") would cut Day-1 churn dramatically.

**Streak/gamification.** This audience loves streaks (Duolingo effect). Add a streak badge to the home header that grows fire emojis at 3/7/30/100 day milestones. Hugely sticky for daily usage.

**Share cards.** Build a `ShareCardGenerator` that turns any scan result into a 1080×1920 image with the score ring, the user's name, and the Glowbite watermark. This is your free TikTok marketing engine.

---

## 📋 Suggested Sprint Plan

**Sprint 1 (this week) — Brand correctness.** Fix the coral hex, replace 3 system fonts, ship the proper FoodLogSheet 3-step flow, fix FaceScanResultView traffic-light scoring. This is the bar before any other work.

**Sprint 2 — Polish pass.** Custom toggle, custom loader, empty states component, haptics standardization, accessibility labels, Dynamic Type defensive pass.

**Sprint 3 — Delight + retention.** Onboarding flow, streak system, share cards, confetti on high scores, 3-2-1 capture countdown, time-of-day greetings.

**Sprint 4 — App Store readiness.** Wire Privacy/Terms links, accessibility audit with VoiceOver, color contrast pass, screenshot generation, App Store copy.
