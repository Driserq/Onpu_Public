# Codebase Documentation (Onpu iOS)

## Project Overview

This is a **Japanese Lyrics Learning App** implemented as a **native iOS app (SwiftUI + SwiftData)**. The app helps users learn Japanese through song lyrics by providing:

- Furigana readings above kanji characters
- Pitch accent visualization (custom Canvas drawing)
- English translations for each line (generated via Google Gemini)
- A kanji dictionary with meanings, readings, and mnemonics (bundled JSON)

---

## Backend Split (Key Architectural Change)

The project now uses a **separate backend** (in repo at `backend/`) for all Gemini calls and API keys.

- iOS creates an **async lyrics processing job** on the backend and receives results via **foreground-only long-polling** + **resume catch-up**.
- Jobs are ACKed by the client and results are kept only temporarily on the backend (TTL safety net).

### Backend access control
All backend requests must include a shared app header:
- `tarukingu: <value>` (configured on the backend via `TARUKINGU`, and in the iOS app via `Uta/App.config`)

In development/staging, auth can be bypassed with a dev token (`X-Dev-Token: dev123`) when the backend enables `ALLOW_DEV_BYPASS=true`.

### Apple Sign In
The repo contains a complete Sign in with Apple flow (`AuthService`, `OnboardingView`, `/v1/auth/apple`), but it is currently **not enabled by default** because Personal Team provisioning profiles do not support the Sign In with Apple entitlement.
After the auth screen, we will add a **Plan view** to start the free trial.

## User Experience Flow

### 1. Home Screen (`HomeView.swift`)
- **Entry point** (First tab)
- Displays a welcome message and a large "Add New Song" action button.
- Shows a horizontal scroll list of the 5 most recently added songs.
- Navigation: Tapping a song card navigates to the `LyricsView`.

#### Debug tooling
In `#if DEBUG`, Home shows a wrench button that opens `AuthDebugView` (base URL override + `/v1/auth/me` ping + last HTTP status).

### 2. Library Screen (`LibraryView.swift`)
- Displays all saved songs in a list.
- **Search**: Filters by title, artist, or raw lyrics text using `.searchable`.
- **Add Song**: Tapping "+" opens the `AddSongView` sheet.
    - User enters Title, Artist, and pastes Japanese Lyrics.
    - Tapping "Save" creates a **backend lyrics job** via `BackendClient`.
    - A `LyricsJob` is inserted immediately so users can browse while processing runs.
- **Processing section**: While jobs are running/queued/failed, they appear in a "Processing" section.
    - On Library screen load, the app refreshes pending jobs once (covers app restarts).
    - While the Library is visible, the app uses a **single long-poll loop** for near-realtime updates.
    - On app resume/launch, the app uses a **recent-changes catch-up** endpoint to discover completions that happened while backgrounded.
    - There is **no background polling**; network activity is cancelled when leaving the Library screen.
    - Jobs can be **Removed** (custom confirmation popup).
    - Failed/missing jobs can be **Retried** (custom confirmation popup) which resubmits and replaces the jobId in-place.
- **Delete/Favorite**:
    - Songs support swipe-to-delete (custom confirmation popup).
    - Songs support swipe-to-favorite/unfavorite (leading edge).

### 3. Lyrics View (`LyricsView.swift`)
- Uses a **custom top toolbar** (navigation bar hidden) and a bottom **prev/next** line nav bar.
- **Display controls**:
    - **View Mode**: Toggle between Block Mode (List) and Parallel Mode (Split View).
    - **Reading Mode (exclusive)**: `none` (default), `furigana`, `pitch`.
- **Block Mode**: Vertical list of lyrics. Tapping a line expands/collapses the English translation below it.
- **Parallel Mode**: Split screen with Japanese on top and English on bottom.
    - The two panes use **ratio-based scroll sync** (`ScrollSyncGroup` in `ScrollSync.swift`).
- **Kanji Interaction**: Long-pressing a Kanji character opens the `KanjiModalView` with detailed info.

### 4. Dictionary Screen (`DictionaryView.swift`)
- Grid layout of common kanji (loaded from `kanji-data.json`).
- When not searching, kanji are grouped by level (e.g. N5/N4) with collapsible sections.
- Searchable by character, meaning, or reading.
- During search, results are shown as a flat grid (ungrouped).
- Tapping a tile opens the `KanjiModalView`.

### 5. Onboarding Flow (`RootView.swift`, `OnboardingCoordinator.swift`)
- **Entry gating**: `RootView` routes to onboarding until `isOnboardingComplete` is stored in `@AppStorage`.
- **Intro**: swipeable intro slides → 2s interlude screen with a timer bar.
- **Main tutorial**:
  - Starts from `MainTabView` (Home).
  - Banner instructs: **tap Library**, then **tap Add**.
  - `AddSongView` opens as a sheet with **prefilled example** data; banner says “Tap Save to run the example.”
  - Library locks until the job completes; banner is **empty** while waiting, then instructs “Tap your new song to open it.”
  - Lyrics tutorial: tap to reveal translation → tap Next arrow once → long‑press kanji → final dimmed message → signup panel.
- **UI style**: tutorial guidance uses a **full‑width stripe banner** (pink background, white text) positioned above the bottom navigation bar. Text fades between steps.
- **Dictionary step is currently skipped** in onboarding.

---

## Architecture

### Directory Structure (`Uta/`)

```
Uta/
├── App/
│   └── RorkApp.swift        # Main entry point, sets up SwiftData container
├── Models/
│   ├── Song.swift           # SwiftData Model (@Model)
│   ├── CodableModels.swift  # Structs for JSON blobs (LyricsLine, WordData, MoraData)
│   ├── KanjiService.swift   # Loads kanji-data.json into memory
│   ├── LyricsJob.swift      # SwiftData model for backend job tracking
│   ├── BackendModels.swift  # DTOs for backend endpoints (create/get/ack)
│   ├── BackendClient.swift  # HTTP client for backend (tarukingu + auth; long-poll + recent catch-up)
│   ├── AuthService.swift    # Sign in with Apple (present but not enabled by default)
│   ├── OpenAIService.swift  # Legacy Gemini client (no longer used by default)
│   ├── OnboardingState.swift # Onboarding state machine
│   └── OnboardingSampleContent.swift # Bundled onboarding lyrics + translation
├── AI/                      # Legacy prompt/config files (no longer used by default)
├── Secrets.swift            # Loads App.config (tarukingu + optional Gemini key)
├── App.config               # Bundled config JSON (tarukingu + optional Gemini key)
├── Views/
│   ├── MainTabView.swift    # Root TabView
│   ├── HomeView.swift       # Dashboard
│   ├── LibraryView.swift    # Song List
│   ├── AddSongView.swift    # Form + AI Generation logic
│   ├── LyricsView.swift     # Main learning interface (Block/Parallel)
│   ├── DictionaryView.swift # Kanji reference
│   ├── KanjiModalView.swift # Detail sheet
│   ├── AuthDebugView.swift  # DEBUG-only auth/network status + base URL override
│   ├── PitchAccentLineView.swift # Core rendering component
│   ├── OnboardingCoordinator.swift # Orchestrates the onboarding flow
│   ├── OnboardingIntroSlidesView.swift # Intro slides UI
│   ├── OnboardingIntroSlidePageView.swift # Single slide view
│   ├── OnboardingInterludeView.swift # 2s interlude screen
│   ├── OnboardingPopupOverlay.swift # Full-width banner stripe
│   ├── OnboardingSignupPanelView.swift # Signup panel
│   ├── PostKanjiMessageOverlay.swift # Final dimmed message
│   ├── BrandedButtonStyle.swift # Primary/secondary button styles
│   └── ScrollSync.swift      # UIScrollView-based introspection + ratio scroll sync
├── Theme/
│   ├── AppColors.swift       # Color definitions
│   ├── BrandedButtonStyle.swift # Primary/secondary button styles
│   └── StyleTokens.swift     # Source of truth for shared colors, radii, spacing
├── ViewModels/
│   └── (Currently simple enough that Logic is mostly in Views/Services)
└── Assets/                  # Colors, Icons (Assets.xcassets)
```

### Style tokens
`Theme/StyleTokens.swift` is the **source of truth** for shared colors, radii, and spacing. Use these tokens instead of hardcoded values when styling UI.

---

## Data Layer (SwiftData)

### `Song` Model (`Models/Song.swift`)
We use **SwiftData** for local persistence. To handle the complex nested structure of lyrics and translations efficiently (and keep the schema flat for potential CloudKit sync), we store complex data as JSON `Data` blobs.

```swift
@Model
final class Song {
    var id: UUID
    var title: String
    var artist: String
    var lyricsRaw: String      // For search predicates
    var createdAt: Date
    var isFavorite: Bool
    
    // Stored as JSON Blobs
    @Attribute(.externalStorage) var translationsJSON: Data? 
    @Attribute(.externalStorage) var lyricsDataJSON: Data?
}
```

*   **Rationale**: Avoiding thousands of tiny `WordData`/`MoraData` SwiftData objects improves performance and simplifies sync.
*   **Decoding**: The `LyricsView` decodes these blobs into `[LyricsLine]` structs when the screen loads.

---

## Core Components

### `PitchAccentLineView`
Renders a line of Japanese text with linguistic annotations.
- **Implementation**: Uses `FlowLayout` (custom) to wrap words.
- **Visuals**:
    - **Furigana**: Displayed above Kanji if enabled.
        - Implemented as an **overlay with fixed top padding** so ruby text never changes surface spacing or causes horizontal reflow.
        - Characters maintain exact horizontal positions when toggling between default and furigana modes.
        - Behavior: center ruby above a single kanji, or above a multi-kanji run (concatenated readings).
    - **Pitch Lines**: Drawn using SwiftUI `Canvas` and `Path`.
    - **Logic**: Replicates the React Native logic (High/Low pitch relative Y coordinates) to draw the red "roof" and "wall" lines connecting moras.
- **Translation Mode (Block Mode)**: Once a line is tapped, all translations become visible (selected one bright, others dimmed at 30% opacity). Arrow navigation changes highlighting without layout shifts for smooth scrolling.
- **Rendering consistency**: All text (Japanese and English) uses consistent rendering paths across modes to prevent compression or spacing artifacts.

### `OpenAIService`
Handles all interaction with the Google Gemini API.
- **Gemini call configuration**: `Uta/AI/GeminiCalls.json` defines URL/headers/body files for:
    - `translations`: `{ index -> English line }`
    - `lyricsData`: `{ index -> LyricsLine(words:[WordData...]) }`
- **Model**: currently uses `gemini-3-flash-preview` (see `GeminiCalls.json`).
- **Dynamic substitutions**:
    - `{{INPUT_JSON}}` is JSON-escaped (because it is embedded inside a JSON string field in the request body).
    - `{{LINE_COUNT}}` is substituted for the lyrics-data prompt.
- **Sanitization**: Fixes common AI JSON errors (e.g., converting `"isHigh": "low"`/`low` into boolean `false`) before decoding/saving.
- **Security**: API Key can be read from `UserDefaults` (for local developer testing) and/or from bundled `Uta/App.config` via `Secrets.swift`.

**Status**: This is now a **legacy** client. The production path is:
- iOS → `BackendClient` → backend (Gemini calls + keys) → iOS.

### `BackendClient` + `LyricsJob`
- `BackendClient` implements:
  - `POST /v1/jobs` (create)
  - `GET /v1/jobs/:id` (status/result)
  - `GET /v1/jobs/pending/longpoll?timeout&since&limit` (foreground near-realtime)
  - `GET /v1/jobs/recent?since&limit` (resume catch-up)
  - `POST /v1/jobs/:id/ack` (client delivery confirmation)
- All requests include `tarukingu` header. In `#if DEBUG`, requests authenticate via `X-Dev-Token` when no Bearer access token is present.
- `LyricsJob` persists in SwiftData so jobs survive app restarts.
- `LibraryView` long-polls while visible and finalizes jobs into `Song` records when results arrive.

### `KanjiService`
- **Source**: `kanji-data.json` (bundled in the app).
- **Behavior**: Loads JSON into memory on app launch. Provides fast lookup `getKanji(char)` for the lyrics view.

---

## Key Refactoring Changes (RN vs iOS)

| Feature | React Native (Old) | iOS Native (New) |
| :--- | :--- | :--- |
| **UI Framework** | React Native / Expo | SwiftUI |
| **Persistence** | AsyncStorage (JSON strings) | SwiftData (SQLite wrapper) |
| **Navigation** | Expo Router | SwiftUI `NavigationStack` |
| **Pitch Drawing** | React Native View/SVG | SwiftUI `Canvas` & `Path` |
| **State** | React Context (`useSongs`) | SwiftData `@Query` / `@ModelContext` |
| **Layout** | Flexbox (`flexDirection`) | `HStack`, `VStack`, `LazyVGrid` |

---

## External Dependencies

- **None** (no SPM/CocoaPods). The only non-SwiftUI piece is a small UIKit bridge for scroll sync (`ScrollSync.swift`).

Note: the backend (`backend/`) is a separate Node/TypeScript project (Fastify + BullMQ + Redis). Next.js is not used in the deployed backend build.

---

## Landing Page (`landing/`)

A static marketing landing page built with **Next.js 15** (App Router) for the Uta app waitlist.

### Tech Stack
- Next.js 15 with App Router
- TypeScript
- CSS Modules
- Static export (`output: "export"`)

### Design System
The landing page mirrors the iOS app's visual language:
- **Accent color**: Apple System Pink (`#ff2d55` — matches SwiftUI `Color.pink`)
- **Pitch accent red**: `#ff3b30` (Apple's `Color.red`)
- **Translation blue**: `#007aff` (Apple's `Color.blue`)
- **Corner radius**: 16px for cards, 8px for smaller elements
- **Shadows**: Subtle (`rgba(0,0,0,0.05)`)
- **Backgrounds**: Apple system grays (`#f2f2f7`, `#e5e5ea`)

### Structure
```
landing/
├── app/
│   ├── layout.tsx       # Root layout with metadata
│   ├── page.tsx         # Main landing page component
│   ├── page.module.css  # Component styles
│   └── globals.css      # CSS variables and base styles
├── next.config.ts       # Static export config
├── package.json
└── tsconfig.json
```

### Features
- Hero section with interactive phone mockup showing app UI
- "How It Works" 3-step flow
- Feature cards explaining key benefits
- FAQ accordion
- Early access CTA

### Development
```bash
cd landing
npm install
npm run dev    # Development server
npm run build  # Static export to landing/out/
```

### Hosting
The static export in `landing/out/` can be deployed to any static hosting (Vercel, Netlify, S3, etc.).
