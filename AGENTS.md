# EventSnap — Agent Handoff & Vibe Coding Guide

> **Read this after `CLAUDE.md`.** This file contains full progress history, architecture decisions, session log, and tips for AI-assisted development.

## Project Summary

**EventSnap** is a privacy-first iOS event scanner. Users snap a photo, speak, or type → on-device OCR/NLP extracts event details → save to Apple Calendar. Zero cloud processing. iPhone only, iOS 17+.

---

## Progress Log

### Session 1 — Foundation & Architecture
- Set up Xcode project with MVVM + SwiftData architecture
- Created all core services: OCRService (actor), CalendarService, SpeechService, NLParser, PermissionManager
- Built three input modes: Camera (Vision OCR), Voice (SFSpeechRecognizer), Text (NLParser)
- Implemented EventCreationViewModel state machine: `idle → capturing → processing → preview → confirming → completed`
- CalendarService with write-only access, duplicate detection, `openEventInCalendar(with:)`
- PIISanitizer utility — emails, phones, SSNs, URLs
- Privacy declarations: PrivacyInfo.xcprivacy, Info.plist keys via build settings
- NLParser as `enum` (all-static namespace) — not injectable, not a class
- OCRService as `actor` — thread-safe, not @Observable, not @Environment

### Session 2 — Deep Link & Security Hardening
- Deep link validation: scheme check (`eventsnap`), host whitelist (`capture`, `history`, `event`), URL length ≤2048, path sanitization (`isValidPathComponent` alphanumeric+hyphen+underscore), eventId ≤64 chars
- Input validation in NLParser: 5000 char guard, control character stripping in `normalizeText`

### Session 3 — Premium Design Overhaul
- Created `Design/DesignSystem.swift` — full design token system:
  - **40+ adaptive colors**: brand (primary/secondary/accent), semantic (success/warning/error), surface (base/raised/subtle/overlay), text (primary/secondary/tertiary), border, each with dark mode variant
  - **17 typography styles**: pageTitle (28pt bold) → caption2 (11pt) with line spacing and letter spacing
  - **8-pt spacing grid**: xs(4) → massive(48) + pageMargin(16)
  - **4 radius tiers**: sm(8) → xl(24)
  - **6 animation presets**: tabSwitch, quickFade, springUp, slideUp, progressFill, shimmer
  - **6 haptic patterns**: tap, success, error, heavyTap, selection, notification
  - **8 reusable view modifiers**: cardSurface, eventInput, primaryButton, secondaryButton, badgePill, shimmerEffect, skeletonText, staggerReveal
  - **AdaptiveSurface** enum: automatic light/dark color resolution
- Created `Extensions/Color+Hex.swift` — brand colors with `Color(hex:)` init + UIColor extensions
- Rebuilt ALL 14 views + 6 components with new design tokens
- Removed ALL old color names: `accentPrimary`, `accentTeal`, `privacyGreen` — zero references remain

### Session 4 — Quality Fixes & Bug Hunt
- HistoryView: `.tint(.red)` → `.tint(Color.semanticError)` + `.red` → `Color.semanticError`
- VoiceViewModel: 6 magic numbers extracted to `static let` constants
- SpeechService: `SFSpeechRecognizer()!` → 3-level fallback chain
- EventSnapApp: deep link hardening (URL length ≤2048, eventId ≤64, `isValidPathComponent`)
- NLParser: `guard text.count <= 5000` + control character stripping in `normalizeText`
- EventCreationViewModel: added `retryFromError()` — error→idle transition
- ModelConfiguration simplified to `ModelConfiguration(for: EventHistory.self, isStoredInMemoryOnly: false)`

### Session 5 — Test Suite Expansion
- Added 5 new test files (total 14): DesignSystemTests (43 cases), DateExtensionsTests, InputModeTests, EventHistoryTests, TextInputViewModelTests, HistoryViewModelTests
- Full test suite compiles successfully (build-for-testing succeeded)

### Session 6 — Comprehensive Audit Round
- **Security audit** (@security-engineer): 0 critical, 0 high. All medium findings already mitigated.
- **Architecture audit** (@deep-thinker): 8.5/10. SwiftData migrations not needed for v1.0.
- **Code review** (@code-reviewer): ~9/10. Clean MVVM, consistent design system, no bugs found.
- **Overall quality: 9/10** — production-ready

### Session 7 — Context Files & Handoff
- Created `CLAUDE.md` (concise cheat sheet, read every session)
- Created `AGENTS.md` (this file — full handoff)

### Session 8 — Camera & Voice Polish
**Camera complete overhaul:**
- Replaced fragile `CameraPreview` UIViewRepresentable with proper `layerClass` override for `AVCaptureVideoPreviewLayer`
- Added live scanning via `AVCaptureVideoDataOutput` — runs fast OCR every 0.75s on video frames
- Added `ScanReadiness` state machine: idle → looking → noText → textDetected → needsMoreDetail → eventReady → error
- Pulsing colored border around camera: red (no text), amber (partial), green (event found)
- Status pill: "Point at an event flyer" / "Move closer for date and time" / "Event details found"
- Fixed double-OCR: CameraVM no longer runs OCR on capture; EventCreationVM handles it
- Background session queue for start/stop configuration

**Voice complete overhaul:**
- Removed auto-start on view appear — now shows "Tap to Speak" button
- Removed conflicting `AVAudioRecorder` — waveform now uses `SpeechService.audioLevel`
- Proper authorization flow: microphone → speech → start
- Error states display properly (idle waveform stops on error)
- Cancel recording support

**Preview/Confirmation polish:**
- Removed redundant "Edit Details" button from preview
- Removed stale "Edit" toolbar button
- Toned down confetti: 6 particles, 1.5s duration, subtle
- Uncertain field labels: "Uncertain: Date" → "Needs date"
- Empty location no longer disappears — shows "tap to add location"
- Calendar save lag reduced: removed blocking duplicate detection

**Text input polish:**
- Keyboard "Done" button added to toolbar
- Tap-to-dismiss keyboard on background
- Gray bar at bottom removed

**Tab bar fix:**
- Removed `.symbolEffect(.bounce)` — was causing icons to disappear
- Icons now render reliably

**History improvements:**
- "Try Camera" button now actually switches to capture tab
- Delete confirmation alert added
- Callback-based tab navigation

**CalendarService:**
- Added `.authorized` case for backward compatibility with older iOS
- Removed blocking duplicate detection throw

---

## Architecture Decisions

| Decision | Choice | Rationale |
|---|---|---|
| NLParser type | `enum` (all-static) | Pure namespace, no state, prevents pointless instantiation |
| OCRService isolation | `actor` | Thread-safe OCR processing, no @Observable needed |
| CalendarService isolation | `@MainActor` | EventKit requires main thread |
| SpeechService isolation | `@MainActor` | Manages UI-observable state (isRecording, transcript) |
| ViewModel creation | ContentView creates all VMs | Coordinator pattern, avoids @Environment init-time dependency issues |
| Tab bar | Custom floating, NOT UITabBar | Premium feel, spring animations |
| Calendar access | Write-only only | Privacy-minimal per Apple guidelines |
| Camera preview | `layerClass` UIViewRepresentable | Proper AVFoundation integration, auto-sizing |
| Live scanning | `AVCaptureVideoDataOutput` + fast OCR | Non-blocking, ~0.75s interval |
| Voice flow | Explicit tap-to-speak | No auto-start, user controls when to record |
| Confetti | 6 particles, 1.5s | Subtle celebration, not assault |
| Duplicate detection | Non-blocking | Avoid calendar save lag |
| App icon switching | `CFBundleAlternateIcons` via `setAlternateIconName(_:)` | Uses iOS native alternate icons API — no App Store update needed. 4 alternates registered in Info.plist: Brackets, Monogram, ShieldDot, ShieldLens |
| Alternate icon assets | `.appiconset` directories with `Contents.json` mapping | Each variant has 12 sizes (20px→1024px). Icon filenames in Contents.json must match actual PNG names |
| Tab bar material | Removed `.ultraThinMaterial`, use `.thinMaterial` + controlled shadow | Prevents glass bleed artifact into home indicator area |

---

## What NOT To Do (Gotchas)

| ❌ Don't | ✅ Instead |
|---|---|
| Hardcode colors, fonts, spacing, animation values | Use design tokens from DesignSystem.swift |
| Use old color names (`accentPrimary`, `accentTeal`, `privacyGreen`) | Use `brandPrimary`, `brandSecondary`, `brandAccent` |
| Inject NLParser or OCRService via @Environment | NLParser is `enum` (call static methods); OCRService is `actor` (passed directly) |
| Use UITabBar or standard TabView | Custom floating tab bar in ContentView |
| Request full calendar access | `requestWriteOnlyAccessToEvents()` only |
| Add SwiftData migrations | Not needed until schema changes in v2+ |
| Force unwrap (`!`) | Use `??` with defaults or `guard let` + early return |
| Auto-start camera on view appear | User must grant permission first |
| Auto-start voice recording | User must tap "Tap to Speak" |
| Run OCR twice on camera capture | CameraVM does live scan; EventCreationVM does final OCR |
| Manually edit `project.pbxproj` | Xcode 26 auto-includes via `PBXFileSystemSynchronizedRootGroup` |
| Run `tsc` or `npm` commands | This is a Swift/Xcode project, use `xcodebuild` |
| Run CLI test execution | Xcode beta has Mach -308 issues; test via Xcode UI (Cmd+U) |
| Change icon filenames in Contents.json | Must match exact PNG filenames in the .appiconset directory |

---

## File Map with Responsibilities

```
EventSnap/
├── App/
│   ├── EventSnapApp.swift        → App entry, @State services, modelContainer, deep links, lifecycle
│   └── ContentView.swift         → Coordinator: creates VMs, custom tab bar, onChange navigation, tab callback wiring
├── ViewModels/
│   ├── EventCreationVM.swift     → State machine (idle→capturing→processing→preview→confirming→completed)
│   ├── CameraViewModel.swift     → AVCaptureSession, photo capture, flash/toggle, live scanning, ScanReadiness state
│   ├── VoiceViewModel.swift      → Tap-to-speak, SpeechService monitoring, audio levels, error handling
│   ├── TextInputVM.swift         → Text parsing, clipboard paste, validation
│   ├── HistoryVM.swift           → SwiftData query, search, delete, grouping by date
│   └── SettingsVM.swift          → Calendar selection, permission status, app info
├── Views/
│   ├── Camera/CameraCaptureView.swift    → Full-bleed camera, live scan overlay, readiness card, capture button
│   ├── Voice/VoiceInputView.swift        → Tap-to-speak, waveform, stop button, error states
│   ├── Text/TextInputView.swift          → Auto-expanding editor, paste button, keyboard Done, parse button
│   ├── Preview/EventPreviewView.swift    → Stagger reveal, glass calendar picker, field editing
│   ├── Preview/EventConfirmationView.swift → Subtle confetti, checkmark animation, auto-dismiss
│   ├── History/HistoryView.swift         → Chronological list, search, swipe-delete with confirmation
│   ├── Settings/SettingsView.swift       → Grouped form, permission indicators, app icon picker
│   ├── Onboarding/OnboardingView.swift   → 3-page branded intro
│   └── Components/
│       ├── EventCard.swift       → Full + compact variants, "Needs date" badges
│       ├── InputSelector.swift   → Sliding capsule pill with matchedGeometryEffect
│       ├── OnDeviceBadge.swift   → lock.shield.fill + semanticSuccess capsule
│       ├── PermissionOverlay.swift → Large icon + brandPrimary "Open Settings"
│       ├── PrivacyLine.swift     → lock.shield.fill + footnote
│       ├── ProgressBar.swift     → Deterministic fill + shimmer indeterminate
│       └── IconChangerView.swift   → Grid-based icon selector, uses setAlternateIconName(_:)
├── Services/
│   ├── OCRService.swift          → actor, Vision VNRecognizeTextRequest, two-pass (fast+accurate), PII sanitize
│   ├── CalendarService.swift     → @MainActor, write-only access, non-blocking save, .authorized compat
│   ├── SpeechService.swift       → @MainActor, SFSpeechRecognizer, on-device, audio level publishing
│   ├── NLParser.swift            → enum, NSDataDetector + regex, confidence scoring, span-based title extraction
│   └── PermissionManager.swift   → @MainActor, camera/mic/calendar/speech/photoLibrary auth, legacy calendar compat
├── Models/
│   ├── ParsedEvent.swift         → Struct: title, dates, location, confidence, uncertainFields, makeEKEvent()
│   ├── EventHistory.swift        → @Model: persisted record with UUID, dates, inputTypeRaw, eventIdentifier
│   └── InputMode.swift           → Enum: camera/voice/text with icons, titles, asInputType
├── Design/
│   └── DesignSystem.swift        → ALL tokens: colors, typography, spacing, radius, animations, haptics, modifiers
├── Extensions/
│   ├── Color+Hex.swift           → brandPrimary/Secondary/Accent, Color(hex:), UIColor extensions
│   └── Date+Extensions.swift     → Format helpers, relative dates, Weekday enum
├── Utilities/
│   └── PIISanitizer.swift        → Regex-based email/phone/SSN/URL redaction, nonisolated static methods
└── Resources/
    └── PrivacyInfo.xcprivacy     → Apple privacy manifest (NSPrivacyTracking=false)
```

---

## Test Map

| File | What It Tests | Count |
|---|---|---|
| `DesignSystemTests.swift` | Colors, typography, spacing, animations, AdaptiveSurface | 43 |
| `DateExtensionsTests.swift` | Date format, relative dates, Weekday enum | ~12 |
| `InputModeTests.swift` | CaseIterable, icons, titles, asInputType mapping | ~8 |
| `EventHistoryTests.swift` | Creation, persistence, delete, search, sort | ~10 |
| `TextInputViewModelTests.swift` | Parse, validation, clipboard, clear | ~8 |
| `HistoryViewModelTests.swift` | Load, delete, search, grouping, refresh | ~8 |
| `PIISanitizerTests.swift` | Email, phone, SSN, URL sanitization | ~10 |
| `CoordinatorFlowTests.swift` | State transitions, navigation triggers | ~6 |
| `PermissionManagerTests.swift` | Authorization status tracking | ~6 |
| `EventCreationViewModelTests.swift` | State machine transitions, error handling | ~10 |
| `CalendarServiceTests.swift` | Access, event creation, duplicate detection | ~8 |
| `NLParserTests.swift` | Date/time/location/duration parsing, confidence | ~15 |
| `ParsedEventTests.swift` | isReadyForCalendar, makeEKEvent, confidence | ~8 |
| `MockServices.swift` | Mock OCRService, CalendarService, SpeechService | — |

---

## Session History Summary

| # | Type | Key Changes | Quality Gate |
|---|---|---|---|
| 1 | Foundation | Architecture, services, models, views | Build ✅ |
| 2 | Security | Deep links, input validation | Build ✅ |
| 3 | Design | Premium overhaul, design system, all views | Build ✅ |
| 4 | Quality | 7 bug fixes, magic numbers, force unwraps | Build ✅ |
| 5 | Testing | 5 new test files, 14 total | Build ✅ + Test Build ✅ |
| 6 | Audit | 3-agent review, 9/10 score, 0 critical/high | Build ✅ |
| 7 | Handoff | CLAUDE.md + AGENTS.md context files | Build ✅ |
| 9 | App Store Prep + Council | App icon, privacy policy, submission guide, RN migration analysis (2.6/10) | Build ✅ + Council ✅ |
| 10 | Design System + Research | Image sources (Photos/paste/drop), LubaUI SPM dep, ShipSwift components, glass theme migration, Swift Charts | Build ✅ |
| 11 | Icon Redesign + Changer | Shield primary icon, 4 alternates, IconChangerView, Info.plist CFBundleIcons | Build ✅ (0 errors, 0 warnings) |

---

## Key Code Patterns

### State Machine Transitions
```swift
// EventCreationViewModel
idle → startCapture(.camera/.voice/.text) → capturing
capturing → processInput(.image/.text/.transcription) → processing(0.0)
processing → NLParser success → preview(ParsedEvent)
processing → NLParser failure → error(String)
preview → confirmEvent() → confirming
confirming → calendar save success → completed(EventHistory)
confirming → calendar save failure → error(String)
error → retryFromError() → idle
any → reset() → idle
```

### Camera ScanReadiness
```swift
// CameraViewModel
idle → looking → noText → textDetected → needsMoreDetail → eventReady
eventReady → user taps capture → EventCreationVM.processInput(.image)
error states: "Camera unavailable", "Camera input failed"
```

### Voice Recording Flow
```swift
// VoiceViewModel + VoiceInputView
User sees "Tap to Speak" → taps → mic permission → speech permission → recording
→ live transcription updates → user taps Stop → finishRecording → onTranscriptionComplete callback
Error: shows error message, idle waveform stops
```

### Service Injection Flow
```
EventSnapApp (@State services)
  └→ ContentView (.environment(services))
       └→ setupViewModels() (creates VMs with services injected)
            └→ Views (.environment(VMs))
```

### Icon Switching Flow
```swift
// IconChangerView + SettingsView
if UIApplication.shared.supportsAlternateIcons {
    try await UIApplication.shared.setAlternateIconName("AppIcon-Brackets") // Switch
    try await UIApplication.shared.setAlternateIconName(nil) // Revert to primary
}
// SettingsView displays current via UIApplication.shared.alternateIconName → displayIconName computed property
// Display names: "Default" (nil), "Brackets", "Monogram", "Shield Dot", "Shield Lens"
```

---

## Remaining Work Before App Store

| Task | Status | Notes |
|---|---|---|
| App icon | ✅ Done | Shield (primary) + 4 alternates (Brackets/Monogram/ShieldDot/ShieldLens) with IconChanger in Settings |
| Privacy policy URL | ❌ Needed | Required for App Store submission; host publicly |
| Screenshots | ❌ Needed | 6.5" (iPhone 15 Pro Max) + 5.5" (iPhone SE) sizes |
| App Store Connect | ❌ Needed | Create app entry, upload build, submit for review |
| Full flow testing | ⚠️ Pending | Test on real device: camera → OCR → preview → calendar → confetti |
| Build & sign archive | ⚠️ Pending | Xcode → Product → Archive → Distribute App |
| Commit current work | ⚠️ Pending | 27 modified files on `agent/fix-21-compiler-warnings` |

---

## Recommended Next Steps (Post-Launch)

From competitive landscape analysis:

### Month 1: Close Critical Feature Gaps
- Multi-event detection (extract 2+ events from a single flyer)
- Recurring event creation (detect "every Tuesday" → create repeating EKEvent)
- iOS Share Extension (capture events from Messages, Safari, Photos)
- .ics file export

### Month 2: Expand Market Reach
- Google Calendar sync (via Google Calendar API)
- Conflict detection (check existing events before insertion)
- Smart reminders (suggest reminder timing based on event type)
- Time zone intelligence (auto-convert event times)

### Month 3: Build Privacy Moat
- End-to-end encrypted history sync (iCloud CloudKit)
- Face ID / Touch ID lock for app access
- Privacy audit report (in-app, showing what data the app has accessed)
- App Lock Widget (quick-scan from lock screen)
- Submit for Apple Privacy Spotlight feature

---

## Vibe Coding Tips

### Starting a New Session
1. Read `CLAUDE.md` first (always loaded automatically by opencode)
2. Read `AGENTS.md` for full context (this file)
3. Check `git log --oneline -10` to see recent changes
4. Check `git status --short --branch` before editing
5. Create a feature branch: `git checkout -b agent/<short-description>`

### Making Changes
1. **Check design tokens first** — any UI value must come from `DesignSystem.swift`
2. **Respect the architecture** — NLParser is `enum`, OCRService is `actor`, services go in @Environment from App, VMs are created by ContentView
3. **Follow the state machine** — don't add new states without updating `CreationState` enum and `onChange` handler in ContentView
4. **No force unwraps** — use `??` with sensible defaults or `guard let` + early return
5. **Write-only calendar access** — never use `requestFullAccessToEvents()`

### After Making Changes
1. Build: `xcodebuild -scheme EventSnap -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
2. Check for new warnings — the project should have zero new warnings
3. Run tests in Xcode (Cmd+U)
4. Only commit when explicitly asked; use conventional commits: `feat:`, `fix:`, `refactor:`, `chore:`, `test:`

### Common Pitfalls
- **SourceKit-LSP shows fake errors** — Xcode 26's `PBXFileSystemSynchronizedRootGroup` confuses LSP. If `xcodebuild` succeeds, ignore LSP errors.
- **Don't run `tsc`** — this is a Swift project, not TypeScript
- **Don't run `npm test`** — use `xcodebuild test` or Xcode UI
- **CLI simulator tests fail** — use Xcode → Cmd+U instead
- **Don't manually edit project.pbxproj** — Xcode 26 auto-includes new files
- **iPhone 16 Pro simulator may not exist** — use `iPhone 17 Pro` or check available destinations

### Refactoring Rules
- Treat every 5th session as a cleanup/refactor checkpoint
- Remove dead code, unused imports, stale comments
- Consolidate duplicate logic
- Improve test coverage for changed code

### Project-Specific Overrides
- This is a Swift/Xcode iOS project. Node/pnpm/Docker defaults do not apply.
- Quality gates: `xcodebuild` build/test, Xcode UI tests (Cmd+U), manual privacy/security checks.
