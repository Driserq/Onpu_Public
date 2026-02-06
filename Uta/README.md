# RorkiOS - SwiftData Smoke Test

This directory contains the initial native iOS implementation for the Rork Japanese Lyrics Learner.

## contents

- **App/**: Contains the main `RorkApp` entry point.
- **Models/**: Contains the SwiftData `Song` model and Codable structs for JSON persistence.
- **Views/**: Contains `SmokeTestView` for verifying the data layer.

## How to Run

1. Open Xcode.
2. Select **File > New > Project**.
3. Choose **iOS > App**.
4. Settings:
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData** (Optional, as we set up the container manually in `RorkApp.swift`, but selecting it sets up entitlements if needed).
5. Create the project.
6. **Delete** the default `ContentView.swift`, `App.swift` (or whatever the main entry is), and `Item.swift`.
7. **Drag and drop** the `App`, `Models`, and `Views` folders from this `RorkiOS` directory into your new Xcode project group.
8. Ensure `RorkApp.swift` is selected as the main entry point (it has `@main`).
9. Run on **iPhone Simulator**.

## Smoke Test Steps

1. Launch the app. You should see "SwiftData Smoke Test".
2. Tap **"1. Create & Save Song"**. 
   - Check the log for "✅ Saved to SwiftData successfully."
3. Tap **"2. Load & Decode"**.
   - Check the log for "✅ Translations decoded" and "✅ LyricsData decoded".
   - Verify the "Visual Verification" section shows "The tears I left behind in Tokyo".
