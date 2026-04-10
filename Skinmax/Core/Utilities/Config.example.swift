// ──────────────────────────────────────────────
// Config.example.swift — Setup instructions
// ──────────────────────────────────────────────
//
// The app loads the OpenAI API key at runtime from ONE of these sources
// (checked in order):
//
//   1. Environment variable  OPENAI_API_KEY
//      → Set in Xcode: Product ▸ Scheme ▸ Edit Scheme ▸ Run ▸ Environment Variables
//
//   2. Secrets.plist  (bundled in the app target)
//      → Create a file  Skinmax/Resources/Secrets.plist  with:
//
//        <?xml version="1.0" encoding="UTF-8"?>
//        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
//          "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
//        <plist version="1.0">
//        <dict>
//            <key>OPENAI_API_KEY</key>
//            <string>sk-your-openai-api-key-here</string>
//        </dict>
//        </plist>
//
//      Make sure Secrets.plist is added to .gitignore (it already is).
//
// Config.swift reads the key — you do NOT need to edit Config.swift.
// If no key is found, the app will crash in DEBUG with a clear message.
// ──────────────────────────────────────────────
