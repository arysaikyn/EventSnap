# EventSnap — AI Context

> **One-page cheat sheet.** Read this first in every new session. Full details in `AGENTS.md`.

## What Is This

Privacy-first iOS event scanner. Snap a photo, speak, or type → on-device OCR/NLP extracts event details → save to calendar. Zero cloud. iPhone only, iOS 17+.

## Build & Test

```bash
# Build (from project root)
xcodebuild -scheme EventSnap -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Test build (compile check only — CLI simulator has Mach -308 issues, use Xcode UI)
xcodebuild -scheme EventSnap -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build-for-testing

# Actual test execution: open Xcode → Cmd+U
```

**Note:** iPhone 16 Pro simulator may not exist. Use `iPhone 17 Pro` or run `xcodebuild -showdestinations` to find available simulators.

## Architecture

```
MVVM + SwiftData + Services
├── App/          → EventSnapApp (entry, DI, deep links), ContentView (coordinator, tab bar)
├── ViewModels/   → EventCreationVM (state machine), CameraVM (live scan), VoiceVM (tap-to-speak), TextInputVM, HistoryVM, SettingsVM
├── Views/        → Camera, Voice, Text, Preview, Confirmation, History, Settings, Onboarding, Components
├── Services/     → OCRService (actor), CalendarService (@MainActor), SpeechService (@MainActor), NLParser (enum), PermissionManager
├── Models/       → ParsedEvent, EventHistory (@Model), InputMode
├── Design/       → DesignSystem.swift (ALL tokens — colors, typography, spacing, animations, haptics)
├── Extensions/   → Color+Hex (brand colors), Date+Extensions
├── Utilities/    → PIISanitizer
└── Resources/    → PrivacyInfo.xcprivacy
```

## Key Rules

1. **Use design tokens from `Design/DesignSystem.swift`** — NEVER hardcode colors, fonts, spacing, or animation values.

2. **ContentView is the coordinator** — It creates all VMs and handles navigation via `onChange(of: eventCreationVM?.state)`.

3. **NLParser is an `enum`** (all-static namespace) — do not make it a class/struct or inject it.

4. **OCRService is an `actor`** — not @Observable, not in @Environment. Created as `@State` in ContentView, passed directly to VMs.

5. **State machine**: `idle → capturing → processing → preview → confirming → completed → idle`. Error at any stage goes to `.error`, `retryFromError()` returns to `.idle`.

6. **Brand colors**: `brandPrimary` (#E85D3A terracotta), `brandSecondary` (#3A8F8F teal), `brandAccent` (#F5A623 amber). Semantic: `semanticSuccess`, `semanticWarning`, `semanticError`.

7. **Write-only calendar access** — `requestWriteOnlyAccessToEvents()`, not full access.

8. **No force unwraps** — use `??` with sensible defaults or `guard let` + early return.

9. **Xcode 26 beta** with `PBXFileSystemSynchronizedRootGroup` — new files auto-included in build. Don't manually edit `project.pbxproj`.

10. **No SwiftData migrations yet** — v1.0 schema is final.

11. **LubaUI (SPM dep)** — use `LubaButton`, `LubaCard`, `LubaToast`, `LubaBadge` for standard UI. See LubaConfig in EventSnapApp for brand config.

12. **ShipSwift (source files)** — use `SWShimmer`, `SWScanningOverlay`, `SWAnimatedMeshGradient`, `SWBarChart` for animations/charts. MCP server at api.shipswift.app/mcp.

13. **Three design engines**: LubaUI (generic UI) + ShipSwift (animations/charts) + custom DesignSystem.swift (EventSnap brand tokens).

14. **Image sources**: use `ImageSourceGallery` for Photos/Paste/Drop, `PhotoPickerView` for PHPicker, `validateAndPrepareImage()` for 25MP cap.

## Current Status

- **BUILD SUCCEEDED** (0 errors, 0 warnings)
- **Branch:** `agent/image-source-alternatives` (uncommitted)
- **LubaUI v0.1.0** installed as SPM dependency — 35+ components available
- **ShipSwift** 3 source components in `Design/ShipSwift/` — MIT license
- **ShipSwift MCP** configured in opencode.json for AI recipe access
- **DesignSystem.swift** upgraded from 335→651 lines with 6 new enterprise features
- **14 views migrated** to glass theme + LubaUI components
- **Security audit passed** (0 critical, 0 high)
- **Architecture audit passed** (8.5/10)
- **Overall quality: 9/10**
- **App Store prep:** app icon ✅, privacy policy ✅, submission guide ✅, screenshots ❌, Connect entry ❌
- **Cross-platform migration: 2.6/10** — 5-council-member unanimous verdict. Do NOT migrate to React Native/Expo. If Android needed later, use KMM.

## What NOT To Do

- Don't add old color names (`accentPrimary`, `accentTeal`, `privacyGreen`)
- Don't inject NLParser or OCRService via @Environment
- Don't use UITabBar — we have a custom floating tab bar
- Don't request full calendar access — write-only only
- Don't add SwiftData migrations yet
- Don't commit `.env`, secrets, or API keys
- Don't auto-start camera/voice on view appear — both require explicit user action
- Don't run OCR twice on camera capture — CameraVM does live scan, EventCreationVM does final OCR
- Don't migrate to React Native/Expo — 5-council-member analysis rated this 2.6/10 (fatal: privacy moat destruction, native API gaps, cost regression, Android can't do write-only calendar)
- Don't add cloud backend services (Supabase, PostHog, analytics) — Zero-cloud is the #1 USP
- Don't use `requestFullAccessToEvents()` — write-only only is the privacy moat
- Don't use LubaUI for EventSnap-branded features — use `EventGlass`, `EventMeshGradient`, custom DesignSystem tokens
- Don't use ShipSwift components for generic UI — use LubaUI for buttons/cards/toasts/badges
- Don't remove LubaUI or ShipSwift dependencies — they are the approved dual-engine design system
- Don't manually edit project.pbxproj for SPM deps — use Xcode UI or verified pbxproj edits
