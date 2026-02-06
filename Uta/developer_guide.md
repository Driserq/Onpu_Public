# Developer Guide: Onpu iOS

## Introduction

Welcome to the **Onpu iOS** project. This is a native Swift/SwiftUI app that uses SwiftData for persistence and a separate Node backend for Gemini processing.

This guide is designed to get any iOS developer up to speed instantly.

---

## 1. Getting Started

### Prerequisites
- **Xcode 15+** (Required for SwiftData and latest SwiftUI features).
- **iOS 17.0+** Target (Uses `Observation` framework and SwiftData).

For local backend development:
- **Node.js** (project uses `npm` scripts)
- **Redis** (BullMQ queue)

### Installation
1.  **Open the Project**: Open `Uta.xcodeproj`.
2.  **Verify Target Membership**: Ensure these files are included in **Build Phases → Copy Bundle Resources**:
    - `kanji-data.json`
    - `App.config` (bundled config JSON; used by `Secrets.swift`)
    - (Legacy / no longer used by default): `AI/GeminiCalls.json`, `AI/GeminiTranslationsBody.json`, `AI/GeminiLyricsDataBody.json`
3.  **Run**: Select a Simulator (e.g., iPhone 15 Pro) and press `Cmd+R`.

### First Run (Backend required)
Gemini calls now run on the backend (repo folder: `backend/`) so the iOS app never contains API keys.

#### Local dev startup order
1. Terminal 1:
   ```bash
   redis-server
   ```
2. Terminal 2:
   ```bash
   cd backend
   npm run worker:dev
   ```
3. Terminal 3:
   ```bash
   cd backend
   npm run dev
   ```
4. Run the iOS app from Xcode.

#### Backend configuration
Local dev typically uses `backend/.env` (loaded by `npm run dev` / `npm run worker:dev`).

Key variables:
- `REDIS_URL` (defaults to `redis://127.0.0.1:6379` if not set)
- `GEMINI_API_KEY` (required)
- `API_JWT_SECRET` (required; 32+ chars)
- `TARUKINGU` (required; must match the iOS app's `Uta/App.config` `tarukingu` value)
- `ALLOW_DEV_BYPASS=true` + `DEV_BYPASS_TOKEN=dev123` for local auth bypass

Important: if you change `.env`, **restart both API and worker** (dotenv-cli does not live-reload env changes).

#### Hosted (DigitalOcean)
Use environment variables in the hosting UI (do not rely on the committed `.env`).

Recommended commands:
- Build: `npm run build`
- Run (API): `npm start`
- Run (worker): `npm run worker:start`

---

## 2. Project Architecture

The project follows a standard **MVVM-like** pattern, though simpler views often interact directly with the **SwiftData** context.

### Data Flow
1.  **User Input**: `AddSongView` takes raw text.
2.  **Processing**: `BackendClient` creates a backend job (`POST /v1/jobs`).
    - Backend worker calls Gemini twice:
      - **translations**: English per line
      - **lyricsData**: tokenized words + furigana + per-kanji furigana + mora pitch data
    - Foreground near-realtime: iOS uses **long-polling** (`GET /v1/jobs/pending/longpoll`).
    - Resume/launch catch-up: iOS queries **recent changes** (`GET /v1/jobs/recent?since=...`).
3.  **Job tracking**: iOS stores a `LyricsJob` row in SwiftData so jobs survive restarts.
4.  **Persistence**: when the job succeeds, a `Song` model is created.
    - Complex data (lyrics structure, translations) is encoded to `Data` (JSON) and stored in `Song.lyricsDataJSON` / `Song.translationsJSON`.
    - Simple data (Title, Artist) is stored as standard attributes.
5.  **Display**: `LyricsView` fetches the `Song`, decodes the JSON blobs into Swift structs (`[LyricsLine]`), and renders the UI.

Notes:
- The Library screen maintains a single long-poll loop while visible and cancels it when leaving the screen.
- Long-poll responses are advisory; correctness is ensured by per-job refresh (`GET /v1/jobs/:id`) and resume catch-up (`/v1/jobs/recent`).

### Why JSON Blobs in SwiftData?
Instead of creating thousands of tiny SwiftData objects for every single *Word* and *Mora* (which would be slow to write/delete and complex to sync), we store the parsed lyrics structure as a single JSON blob per Song. This keeps the database fast and portable.

---

## 3. Key Components Explained

### `PitchAccentLineView.swift`
This is the most complex UI component. It replicates the linguistic visualization.
- **Problem**: We need to wrap text to the next line, but keep words (kanji + furigana) together, and draw drawing lines *across* characters within a word.
- **Solution**: We use a custom `FlowLayout` (found at the bottom of the file) to arrange `WordView`s.
- **Drawing**: Inside each word, `MoraCell` uses `Canvas` to draw the red pitch lines. The coordinate system relies on relative heights (High = top, Low = bottom) to match the standard Japanese pitch accent notation.
- **Furigana rendering (no spacing shift)**: furigana is rendered as an **overlay** above kanji runs so ruby text never participates in sizing (prevents the common "characters move when enabling furigana" bug).

**Recent improvements (Jan 2025)**:
- **Furigana stability**: Furigana now uses overlay positioning with fixed top padding, ensuring characters stay in exact horizontal positions when toggling reading modes. This prevents the common "text reflow" issue.
- **Translation mode**: In Block Mode, tapping any line enters "translation mode" where all translations become visible (dimmed). Arrow navigation then just highlights/dims without layout changes, providing smooth scrolling.
- **Consistent rendering**: English words use the same rendering path in all modes to prevent compression artifacts.

### `OpenAIService.swift`
- Loads the full Gemini call definitions from **plain-text bundle resources**:
  - `AI/GeminiCalls.json` (URL, headers, body file)
  - `AI/GeminiTranslationsBody.json` and `AI/GeminiLyricsDataBody.json` (actual prompt + config)
- If you need to tweak translation style or the strictness/format of linguistic data, edit the **body JSON files**, not Swift.
- Placeholders:
  - `{{INPUT_JSON}}` is substituted with the `{ index: line }` JSON and is **JSON-escaped** because it's embedded inside a JSON string field.
  - `{{LINE_COUNT}}` is substituted for lyrics-data.

**Status**: legacy / not used by default. The main path is `BackendClient` → backend.

### `BackendClient.swift` / `LyricsJob.swift`
- `BackendClient` is the HTTP client for the backend (no SSE).
- In Debug and Release it targets the hosted backend by default (`https://app.onpu.app`). In `#if DEBUG`, you can override the base URL in `AuthDebugView`.
- Every request includes the `tarukingu` header (value loaded from bundled `App.config` via `Secrets.swift`).
- `LyricsJob` stores `jobId`, `statusRaw`, and `errorMessage`.
- The Processing list supports:
  - Remove (custom confirmation popup)
  - Retry (for `failed`/`missing`, custom confirmation popup)

#### Debug: Auth Debug screen
In Debug builds, Home shows a wrench button that opens `AuthDebugView`:
- Shows current base URL
- Allows setting a Debug-only base URL override
- Pings `/v1/auth/me`
- Displays the last HTTP status code recorded by `BackendClient`

### Favorites
- `Song` has `isFavorite: Bool`.
- Library supports leading-swipe Favorite/Unfavorite.

### `ScrollSync.swift`
Parallel mode uses a UIKit-backed scroll sync layer:
- `ScrollSyncGroup`: ratio-based sync using `contentOffset.y / (contentSize.height - bounds.height)`.
- `ScrollViewIntrospector`: a `UIViewRepresentable` that walks up the superview chain to find the underlying `UIScrollView` and observes `contentOffset` via KVO.

### Interactive Onboarding
- **Entry gating**: `RootView` shows `OnboardingCoordinator` until `@AppStorage("isOnboardingComplete")` is true.
- **Flow**:
  1. Intro slides → 2s interlude.
  2. `MainTabView` (Home) with banner prompts: **tap Library**, then **tap Add**.
  3. `AddSongView` sheet opens with **prefilled example** content; banner says “Tap Save to run the example.”
  4. Library locks until job completion; banner is **blank while waiting**, then instructs “Tap your new song to open it.”
  5. Lyrics tutorial: tap to reveal translation → long‑press kanji → dimmed message → signup panel.
- **Banner**: `OnboardingPopupOverlay` renders a full‑width pink stripe positioned above the bottom nav bar; text fades in/out per step.
- **Reset for testing**: delete the app from the simulator/device or clear `isOnboardingComplete` in `UserDefaults`.

---

## 4. Common Tasks

### Modifying the Data Model
If you need to add a new field to `Song`:
1.  Open `Models/Song.swift`.
2.  Add the new variable: `var genre: String = ""`.
3.  **Important**: Since SwiftData is in use, if you have an existing app installation on the simulator/device, the schema change might crash the app on launch. Delete the app from the simulator and reinstall to reset the database (since we haven't implemented lightweight migration versions yet).

Recent schema notes:
- `Song.isFavorite` was added.
- `LyricsJob` SwiftData model was added.

### Updating the Kanji Dictionary
1.  Open `kanji-data.json`.
2.  Add or modify the JSON entries.
3.  The app loads this file on every launch in `KanjiService.init()`.

### Customizing the UI
- **Style tokens**: `Theme/StyleTokens.swift` is the **source of truth** for shared colors, radii, and spacing. Prefer these tokens over hardcoded values.
- **Colors**: Currently hardcoded (e.g., `.pink` for accents). To theme the app, extract these into `Assets.xcassets` and reference them via `Color("AccentColor")`.
- **Fonts**: Uses system fonts. Japanese text rendering relies on the system's Japanese font fallbacks, which work automatically in SwiftUI.

---

## 5. Troubleshooting

**Jobs stuck in Processing / worker not consuming**
- Use backend debug endpoint:
  ```bash
  curl -H "tarukingu: <TARUKINGU>" -H "X-Dev-Token: dev123" http://127.0.0.1:3001/v1/debug/queue
  ```
- Ensure you restarted **both** the worker and API after `.env` changes.

**Can't run on device (Personal Team provisioning error about Sign In with Apple)**
- Remove the Sign In with Apple capability/entitlement from the app target, or enroll in the Apple Developer Program.

**Jobs not updating in the Library**
- Long-polling only runs while the Library screen is visible.
- On resume/launch, the app uses `/v1/jobs/recent?since=...` to catch up on completions that happened while backgrounded.
- If the API is reachable but nothing updates, verify the worker is running and consuming the queue.

**`EADDRINUSE 0.0.0.0:3001`**
- Something else is already listening on 3001 (usually a stray `tsx watch src/server.ts`). Kill the process or change `PORT` in `backend/.env`.

**Gemini failures (503 / timeouts / invalid key)**
- Backend retries transient errors.
- For large payloads, increase `GEMINI_TIMEOUT_MS` in `backend/.env`.
- If jobs fail fast with `API_KEY_INVALID`, verify the worker is reading the correct env (restart worker; dotenv now runs with override).

**"Encoding/Decoding Error" in Console**
- This usually means the AI returned JSON that doesn't match our `Codable` structs.
- Check `OpenAIService.swift` sanitization. The regex replacement logic handles most common AI errors (like returning strings "high"/"low" instead of booleans), but new edge cases might appear.
- If the error includes a coding path (e.g. `Lyrics JSON decode failed at 3.words.2.mora.0.isHigh`), it points at the exact field that didn't match.

**"Missing GeminiCalls.json in app bundle" / "Missing GeminiLyricsDataBody.json"**
- The AI config files must be added to the **Xcode target** and included in **Copy Bundle Resources**.
- Some Xcode setups flatten resources (subdirectory dropped). The runtime loader tries both `subdirectory:"AI"` and the bundle root, but the file still must be present.

**Parallel scrolling doesn't sync**
- The introspector must be a **descendant of the SwiftUI `ScrollView` content**, not attached via `.background` on the `ScrollView` itself.
- If sync fails, confirm both panes registered a `UIScrollView` (i.e., `ScrollSyncGroup.register(...)` is called for `.jp` and `.en`).

**"Kanji Not Found"**
- The bundled dictionary (`kanji-data.json`) only contains a subset of common Kanji (N5/N4). This is expected. If a user taps a complex N1 kanji, nothing will happen unless you add it to the JSON.

---

## 6. Landing Page (`landing/`)

The project includes a static marketing landing page for early access signups.

### Running the Landing Page
```bash
cd landing
npm install
npm run dev      # Development server at http://localhost:3000
npm run build    # Static export to landing/out/
```

### Design Consistency
The landing page uses the exact same colors as the iOS app:
- **Pink accent**: `#ff2d55` (Apple's `Color.pink`)
- **Red pitch lines**: `#ff3b30` (Apple's `Color.red`)
- **Blue translations**: `#007aff` (Apple's `Color.blue`)
- **16px corner radius** for cards (matches iOS)

### Deployment
The `npm run build` command generates a static export in `landing/out/` that can be deployed to any static hosting service.

---

## 7. Future Roadmap (Post-Refactor)

- **CloudKit Sync**: The `Song` model is designed to be CloudKit-compatible (using `@Attribute(.externalStorage)` for blobs). Enabling the "CloudKit" capability in Xcode is the next step.
- **Audio**: Adding TTS (Text-to-Speech) or audio playback.
- **Vocabulary List**: Saving specific words to a vocab list.
