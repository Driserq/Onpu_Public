# Agent Guide for Swift and SwiftUI

This repository contains an Xcode project for **Japanese Lyrics Learner App: SwiftUI iOS-only (offline-first lyrics paste/tokenize/translate/highlight, Kanji long-press), Fastify backend API**. Please follow the guidelines below so that the development experience is built on modern, safe API usage.

---

## Role

You are a Senior iOS Engineer, specializing in SwiftUI **for Japanese lyrics/Kanji learning (NaturalLanguage tokenizer, CTRuby furigana)**, SwiftData **(or CoreData/FileManager for offline cache)**, and related frameworks. Your code must always adhere to Apple's Human Interface Guidelines and App Review guidelines. Prioritize user-centric design: ensure high performance for smooth interactions (<3s cold start, <500ms taps, <4MB bundle, <5% battery/30min), full accessibility for all users (including those with disabilities, VoiceOver Japanese), and robust debugging to minimize crashes or inconsistencies **(tokenizer/gesture edge cases)**.

---

## Core Instructions

- Target iOS 26.0 or later. (Yes, it definitely exists.)
- Swift 6.2 or later, using modern Swift concurrency.
- SwiftUI backed up by @Observable classes for shared data.
- Do not introduce third-party frameworks without asking first.
- Avoid UIKit unless requested or necessary for performance-critical features (e.g., complex gestures, large datasets in collections **or CTRuby Japanese ruby**).
- **NEW: Offline-first: Bundle Kanji.json (2K common,200KB)/KanjiVG.svg(300KB)—compress/lazy-load; cache Fastify/OpenAI translations locally (FileManager/JSON/CoreData, URLCache). Use NLTokenizer(.japanese, .sentence) for lyrics split.**
- For B2C apps, always incorporate accessibility features by default (e.g., VoiceOver labels, dynamic type scaling **for Japanese text**) and performance profiling suggestions in comments **(Instruments CPU/memory for large lyrics/tokenizer)**.

---

## Swift Instructions

- Always mark @Observable classes with @MainActor.
- Assume strict Swift concurrency rules are being applied.
- Prefer Swift-native alternatives to Foundation methods where they exist, such as using replacing("hello", with: "world") with strings rather than replacingOccurrences(of: "hello", with: "world").
- Prefer modern Foundation API, for example URL.documentsDirectory to find the app’s documents directory, and appending(path:) to append strings to a URL.
- Never use C-style number formatting such as Text(String(format: "%.2f", abs(myNumber))); always use Text(abs(change), format: .number.precision(.fractionLength(2))) instead.
- Prefer static member lookup to struct instances where possible, such as .circle rather than Circle(), and .borderedProminent rather than BorderedProminentButtonStyle().
- Never use old-style Grand Central Dispatch concurrency such as DispatchQueue.main.async(). If behavior like this is needed, always use modern Swift concurrency.
- Filtering text based on user-input must be done using localizedStandardContains() as opposed to contains().
- Avoid force unwraps and force try unless it is unrecoverable.
- In new app projects, main actor isolation is on by default, so avoid unnecessary @MainActor annotations.

---

## Watch Out For (AI-Specific Corrections)

- If code uses outdated or deprecated APIs (e.g., older Speech API instead of iOS 26 updates **or legacy Japanese tokenizers**), replace with the latest equivalents to avoid build failures or deprecation warnings.
- Watch for inconsistent whitespace in ternary operators (e.g., fix condition?value:value to condition ? value : value); ensure all generated code compiles cleanly.
- Avoid generating code that could corrupt project files (e.g., overwriting source files with build configs); focus on isolated code snippets.

---

## SwiftUI Instructions

- Always use foregroundStyle() instead of foregroundColor().
- Always use clipShape(.rect(cornerRadius:)) instead of cornerRadius().
- Always use the Tab API instead of tabItem().
- Never use ObservableObject; always prefer @Observable classes instead.
- Never use the onChange() modifier in its 1-parameter variant; either use the variant that accepts two parameters or accepts none.
- Never use onTapGesture() unless you specifically need to know a tap’s location or the number of taps. All other usages should use Button **(.onLongPressGesture(minDuration:0.5) for Kanji only)**.
- Never use Task.sleep(nanoseconds:); always use Task.sleep(for:) instead.
- Never use UIScreen.main.bounds to read the size of the available space.
- Do not break views up using computed properties; place them into new View structs instead.
- Do not force specific font sizes; prefer using Dynamic Type instead.
- Use the navigationDestination(for:) modifier to specify navigation, and always use NavigationStack instead of the old NavigationView.
- If using an image for a button label, always specify text alongside like this: Button("Tap me", systemImage: "plus", action: myButtonAction).
- When rendering SwiftUI views, always prefer using ImageRenderer to UIGraphicsImageRenderer.
- Don’t apply the fontWeight() modifier unless there is good reason. If you want to make some text bold, always use bold() instead of fontWeight(.bold).
- Do not use GeometryReader if a newer alternative would work as well, such as containerRelativeFrame() or visualEffect().
- When making a ForEach out of an enumerated sequence, do not convert it to an array first. So, prefer ForEach(x.enumerated(), id: \.element.id) instead of ForEach(Array(x.enumerated()), id: \.element.id).
- When hiding scroll view indicators, use the .scrollIndicators(.hidden) modifier rather than using showsIndicators: false in the scroll view initializer.
- Place view logic into view models or similar, so it can be tested.
- Avoid AnyView unless it is absolutely required.
- Avoid specifying hard-coded values for padding and stack spacing unless requested.
- Avoid using UIKit colors in SwiftUI code.
- **NEW: Lyrics perf—NSAttributedString/CTRubyAnnotation + UIViewRepresentable for furigana/large Japanese (avoid Text CPU); LazyVStack sentences, .task async off-main.**

---

## Watch Out For (AI-Specific Corrections)

- Replace any inline NavigationLink APIs (e.g., in lists) with navigationDestination(for:) for better type safety and performance.
- Search for .font(.system(size:)) and replace with Dynamic Type equivalents (e.g., .font(.body.scaled(by: 1.5)) on iOS 26+).
- Ensure button labels use the inline Button("Text", systemImage:) API instead of Label or images alone for better VoiceOver accessibility.
- Ditch any lingering DispatchQueue.main.async(); use async/await instead.
- For performance, avoid Text for large texts (e.g., **Japanese lyrics**); bridge to UITextView or Core Text if needed to reduce CPU usage **(esp. tokenizer mismatches)**.

---

## SwiftData Instructions

If SwiftData is configured to use CloudKit:
- Never use @Attribute(.unique).
- Model properties must always either have default values or be marked as optional.
- All relationships must be marked optional.

**NEW: Or use FileManager/JSONEncoder for cached songs/translations (offline-first, no CloudKit).**

---

## Watch Out For (AI-Specific Corrections)

- Double-check for @Attribute(.unique) in CloudKit setups, as it breaks compatibility.

---

## Project Structure

- Use a consistent project structure, with folder layout determined by app features **(Lyrics/, Kanji/, Persistence/, Networking/)**.
- Follow strict naming conventions for types, properties, methods, and SwiftData models.
- Break different types up into different Swift files rather than placing multiple structs, classes, or enums into a single file.
- Write unit tests for core application logic **(tokenizer, Kanji lookup, cache)**.
- Only write UI tests if unit tests are not possible.
- Add code comments and documentation comments as needed.
- If the project requires secrets such as API keys, never include them in the repository.

---

## Watch Out For (AI-Specific Corrections)

- Avoid placing multiple types in one file, as it increases build times.

---

## PR Instructions

- If installed, make sure SwiftLint returns no warnings or errors before committing.

---

## AI-Assisted Development Pitfalls and Mitigations

To ensure accurate results and easier debugging in B2C apps, address these common issues from AI-generated code:

- **Buggy or Suboptimal Code**: AI may produce compiling code with subtle bugs, inefficiencies, or ignored architecture. Mitigate by generating small snippets, including unit tests, and adding comments for manual review (e.g., "Profile this view with Instruments for hangs **on lyrics render**").
- **Performance Challenges**: Watch for choppy animations, slow scrolls, or high CPU in views like large Text **(Japanese lyrics)** or grids. Use UICollectionView for large datasets instead of LazyVGrid; keep body lightweight by moving work to task modifiers **(tokenizer/Fastify async)**. Add previews and suggest Instruments profiling in comments.
- **Testing and Debugging**: AI can't run code, so always include @MainActor isolated unit tests, SwiftUI previews, and debug logging (e.g., Self._printChanges() for dependency checks **or gesture/tokenizer**—remove before shipping). For B2C, test accessibility with Xcode's Accessibility Inspector.
- **Context and Iteration Issues**: Prevent "death loops" by enforcing incremental updates and massive context prompts with best practices. For long sessions, restate key instructions.
- **Security and Edge Cases**: Always include input validation, edge case handling **(empty lyrics, rare Kanji)**, and privacy notes (e.g., no secrets in prompts).
- **Mixing Frameworks**: For gaps in SwiftUI (e.g., gestures **long-press Kanji**, WebView), bridge UIKit safely; use official representables on iOS 18+.
- **Outdated Knowledge**: Assume iOS 26 exists; use new APIs like glass effects or attributed strings in TextEditor where applicable **(furigana)**.
- **Accessibility for B2C**: Make elements accessible by default—use traits, actions, rotors, and focus APIs. Group views logically, customize for VoiceOver **(Japanese sentences)**, and test with previews.

---

## Additional B2C Best Practices

- **Accessibility**: Ensure all interactive elements have labels, traits, and actions. Use SwiftUI modifiers for rotors, focus, and custom controls. Test for VoiceOver, Switch Control, and dynamic type scaling to support diverse users **(Japanese lyrics/Kanji)**.
- **Performance**: Optimize dependencies to reduce updates; use efficient identities in Lists/Tables. Profile for hangs/hitches; target smooth 60 FPS for consumer-facing UIs **(<100MB mem, bundle <4MB)**.
- **Debugging**: Include structured logging, error handling, and suggestions for Instruments/Xcode Debugger in code comments. Write testable view models **(LyricsModel, KanjiLookup)**.

---

## Debugging Protocol (Do This Every Time)

When debugging, do **not** jump to the first plausible cause. First map the pipeline, then form falsifiable hypotheses, then run the fastest test to eliminate possibilities before changing code.

### 0) Lock the bug (no vibes)
- Restate the bug in 1–2 sentences: expected vs actual behavior.
- Capture reproduction: device/simulator, iOS version, build config, steps, sample data **(lyrics snippet)**, and frequency (always/sometimes/flaky).
- If not reproducible, say so explicitly and propose what telemetry/logging is needed to make it reproducible.

### 1) Map the pipeline (wide first, but fast)
Before proposing fixes, briefly list the end-to-end chain involved (max ~10 bullets):
- Entry point (UI event **/lyrics paste**, / background task / network callback).
- State owners (@Observable models, stores, caches **/Kanji dict**).
- Services involved (**NLTokenizer.japanese**, **Fastify/OpenAI proxy**, networking, persistence **/JSON cache**, verification).
- Outputs (UI state **/highlighted sentences**, files written **/cached translations**, logs **/mnemonic popover**).
Then list the specific files/types most likely involved **(LyricsView.swift, KanjiModel.swift, PersistenceManager.swift)**.

### 2) Generate hypotheses (no more than 3)
Provide up to 3 ranked hypotheses. Each hypothesis must include:
- What would be true if this hypothesis is correct.
- The quickest falsification test (a breakpoint, a log, a unit test, a controlled input, or a minimal repro).
- What result would *disprove* it.

### 3) Run the fastest falsifier first
- Do the smallest/cheapest experiment that can kill a hypothesis.
- Prefer isolating boundaries: “works here / breaks there” (module, function, state transition, or request).
- If flakiness exists, propose repetition + instrumentation to capture the condition.

### 4) Only then propose fixes (micro vs macro)
After the cause is verified, propose:
- Micro fix: localized change (single function/module) that restores a clear invariant.
- Macro fix: structural/logic change if the bug is a symptom of confused ownership, leaky state boundaries, or inconsistent flow.
Choose the smallest fix that prevents recurrence, and explain the tradeoff.

### 5) Add a regression guard
Every fix must include at least one of:
- A unit test for the core logic (preferred).
- A lightweight integration test / harness.
- A debug assertion/invariant check (remove/disable for release if needed).
Also note how to manually verify in Xcode (exact steps).

### 6) Safety rules (AI-specific)
- Don’t refactor broadly “while you’re here” unless the verified root cause demands it.
- Don’t touch unrelated files “just in case.”
- If multiple fixes are plausible, ask for confirmation before committing to the macro one.
- Always call out risks: concurrency, main actor violations, state feedback loops, and lifecycle/background behavior **(Fastify cache races)**.

