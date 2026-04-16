# Claude Code Prompt — Implement Food Scan Option A (Camera-First)

You are working in the Skinmax iOS app codebase (SwiftUI, iOS 17+, MVVM).

## Goal
Implement **Option A: camera-first Food Scan flow**.

When user taps **Log Food**, the app should go **straight to camera capture UI** (no intermediate “Log a Meal” sheet and no manual name-entry step before analysis).

## Important Scope
- Do this **frontend/flow refactor only**.
- **Do NOT** modify AI backend prompt or food-analysis request format yet.
- **Do NOT** add new backend fields yet.
- Keep existing analysis pipeline working with current services.

## Current Problem to Remove
Right now flow includes manual logging UI:
- `FoodLogSheet` asks for food name via text field
- user chooses/takes image
- analyze button

We want to remove this old entry behavior from the main scan entry path.

## New Desired Flow (Option A)
1. User taps floating scan button -> scan popup appears (existing behavior).
2. User taps **Log Food**.
3. App immediately opens camera-first food capture screen.
4. User captures photo.
5. App proceeds to existing food analysis pipeline (using current backend behavior).
6. If food name is required by existing API shape, use a temporary internal fallback (e.g. `"Meal"`) without showing manual name UI.
7. Show existing analysis progress/result flow as today.

## Hard Requirements
- Remove old manual name-entry logic from active flow:
  - no required text field before capture
  - no “Analyze with AI” gate tied to typed food name
- Keep app compiling and behavior stable.
- Preserve existing `AnalysisCoordinator.startFoodScan(...)` usage pattern.
- Keep existing image processing constraints.
- Maintain current navigation style (`fullScreenCover`-based flow is okay).

## Implementation Notes
- You can either:
  - refactor existing `FoodLogSheet` into camera-first capture, or
  - introduce a new `FoodScanCameraView` and route `onLogFood` to it.
- Update any stale naming that implies manual logging if it hurts clarity.
- Remove dead/manual-logging state and view model fields that are no longer used in this flow.
- Keep changes focused; avoid unrelated refactors.

## Suggested Files to Inspect/Update
- `Skinmax/App/ContentView.swift`
- `Skinmax/Features/FoodScan/FoodLogSheet.swift`
- `Skinmax/Features/FoodScan/FoodLogSheetViewModel.swift`
- `Skinmax/Features/FoodScan/ImagePicker.swift`
- `Skinmax/Core/Utilities/AnalysisCoordinator.swift` (only if minimally needed)

## UX Expectations (Option A)
- Camera appears immediately after tapping Log Food.
- Capture controls are clear and minimal.
- Cancel/back works.
- On capture, user quickly enters analysis flow.
- No manual meal-name entry screen in this path.

## Engineering Principles
- MVVM: keep business logic out of SwiftUI view bodies.
- Keep state explicit and minimal.
- Delete unused code after refactor.
- Prefer small, readable functions and clear naming.

## Verification Checklist
- Build passes.
- No lint/type errors in changed files.
- Tapping Log Food opens camera directly.
- Capturing image still produces analysis + result screen.
- No manual name prompt appears in this path.

## Output Format
After implementation, provide:
1. short change summary
2. list of files changed
3. verification steps run
4. any known follow-up items for next prompt (backend prompt update + naming extraction)
