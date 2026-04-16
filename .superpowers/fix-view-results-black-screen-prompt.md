Fix the black screen bug when tapping "View Results" after a face scan completes.

## Problem

In `Skinmax/App/ContentView.swift`, the face scan result and food scan result full screen covers use `fullScreenCover(isPresented:)` with a conditional `if let` inside the content closure (lines 68-77). This causes a black screen because SwiftUI presents the cover immediately when the Bool becomes true, but the optional scan value can still be nil due to state propagation timing — so the `if let` fails and an EmptyView (black screen) is rendered.

## Root Cause

There are two redundant pieces of state that can desync:
- `showFaceResult: Bool` (line 8) + `faceResultScan: SkinScan?` (line 10)
- `showFoodResult: Bool` (line 9) + `foodResultScan: FoodScan?` (line 11)

The Bool can become `true` before the optional is populated on the same render pass, causing the cover to present with no content.

## Fix — ContentView.swift

1. **Delete** the two redundant Bool state variables on lines 8-9:
   ```swift
   @State private var showFaceResult = false    // DELETE
   @State private var showFoodResult = false     // DELETE
   ```

2. **Replace** the two `fullScreenCover(isPresented:)` modifiers (lines 68-77) with `fullScreenCover(item:)`. This variant only presents when the binding becomes non-nil, and passes the unwrapped value directly — no timing issue possible.

   Replace this:
   ```swift
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
   ```

   With this:
   ```swift
   .fullScreenCover(item: $faceResultScan) { scan in
       FaceScanResultView(scan: scan)
   }
   .fullScreenCover(item: $foodResultScan) { scan in
       FoodScanResultView(scan: scan)
   }
   ```

3. **Update** the `onViewFaceResult` and `onViewFoodResult` callbacks (lines 24-31) to only set the optional — no Bool needed:

   Replace:
   ```swift
   HomeView(
       onViewFaceResult: { scan in
           faceResultScan = scan
           showFaceResult = true
       },
       onViewFoodResult: { scan in
           foodResultScan = scan
           showFoodResult = true
       },
   ```

   With:
   ```swift
   HomeView(
       onViewFaceResult: { scan in
           faceResultScan = scan
       },
       onViewFoodResult: { scan in
           foodResultScan = scan
       },
   ```

Both `SkinScan` and `FoodScan` already conform to `Identifiable` (in `Skinmax/Models/SkinModels.swift`), so `fullScreenCover(item:)` works out of the box. When the user dismisses the result view, SwiftUI automatically sets the binding back to `nil`.

## Fix — HomeView.swift (cleanup dead code)

In `Skinmax/Features/Home/HomeView.swift`:

1. **Delete** `@State private var selectedScanResult: SkinScan?` on line 7 — nothing in the view ever sets this variable.

2. **Delete** the orphaned full screen cover on lines 33-36 that uses it:
   ```swift
   .fullScreenCover(item: $selectedScanResult) { scan in
       FaceScanResultView(scan: scan)
           .environment(dataStore)
   }
   ```
   This is dead code — face scan results are routed through `onViewFaceResult` up to `ContentView`, not through this local binding.

## Verification

After making changes, build the project and confirm:
- Scan your face → analysis completes → tap "View Results" → FaceScanResultView appears (not a black screen)
- Dismiss the result view → the optional resets to nil automatically
- Food scan "View Results" also works the same way
- No compiler errors or warnings about unused variables
