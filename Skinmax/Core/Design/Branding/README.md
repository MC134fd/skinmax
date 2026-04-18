# Glowbite — Brand Lockup

Everything needed to render the `🍎 Glowbite` brand mark: apple icon, 8
switchable wordmark fonts, and the combined lockup.

```
Skinmax/Core/Design/Branding/
├── GlowbiteIcon.swift       — SwiftUI vector apple (no face, transparent)
├── GlowbiteWordmark.swift   — "Glowbite" text with 8 font variants
├── GlowbiteLockup.swift     — icon + wordmark side-by-side (use this)
└── README.md                — this file
```

All three components are pure SwiftUI → always transparent background, vector
sharp at any size, no asset catalog entries needed.

## Current production variant

`.caveat` (Caveat Bold — handwritten, BFF voice). Live on `HomeView` top bar.

## Switching variants

Change the `variant:` argument wherever `GlowbiteLockup` is used. To swap
everywhere at once, update the default on the lockup or wordmark struct.

Example — swap home header to Fraunces:

```swift
// Skinmax/Features/Home/HomeView.swift
GlowbiteLockup(variant: .fraunces)
```

## Available variants

| # | Case                | Font                               | Vibe |
|---|---------------------|------------------------------------|------|
| 1 | `.nunito`           | Nunito Black                       | Brand-safe · in-house |
| 2 | `.fraunces`         | Fraunces ExtraBold (9pt Black)     | Warm editorial serif · skincare-industry |
| 3 | `.instrumentSerif`  | Instrument Serif Italic            | Thin luxury-magazine |
| 4 | `.dmSerif`          | DM Serif Display                   | Chunky serif · Glossier energy |
| 5 | `.playfair`         | Playfair Display Black Italic      | Classic fashion-editorial |
| 6 | `.spaceGrotesk`     | Space Grotesk Bold                 | Clean modern geometric · Cal AI vibe |
| 7 | `.unbounded`        | Unbounded Black                    | Quirky display · Gen-Z |
| 8 | `.caveat`           | Caveat Bold                        | Handwritten BFF · **current prod** |

All font .ttf files live in `Skinmax/Resources/Fonts/` and are registered in
`Info.plist` under `UIAppFonts`. Seven of the eight are variable fonts; their
weights are set in Swift via `.weight(...)`.

## Previewing all 8 at once

Open `GlowbiteLockup.swift` and run the `"Lockup — all variants"` SwiftUI
preview. Each row shows the icon + wordmark for a variant so you can compare
them against the same cream background used in the app.

## Anatomy — why these files

- **Icon vs mascot**: `GlowbiteIcon` is the *logo* form of the apple (no eyes,
  no mouth, no blemish overlays). The animated character mascot with
  expression + blemishes still lives in
  `Skinmax/Features/FaceScan/AppleMascotView.swift` and is only used on the
  scan result page.
- **Wordmark vs lockup**: `GlowbiteWordmark` is text-only so it can stand
  alone (splash, share cards, OG images). `GlowbiteLockup` pairs it with the
  icon for headers / nav bars.

## Font licensing

All 8 fonts are SIL OFL 1.1 (free for commercial use, embedding in apps is
explicitly allowed). Source: Google Fonts mirror at github.com/google/fonts.
