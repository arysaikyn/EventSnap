# EventSnap — Competitor & Inspiration Repos Research

> Deep research conducted May 14, 2026. Sources: GitHub, App Store, Exa search, grep.app code search.

---

## Table of Contents

1. [Direct Competitors (App Store)](#1-direct-competitors-app-store)
2. [Open Source Repos — Direct Inspiration](#2-open-source-repos--direct-inspiration)
3. [Open Source Repos — OCR & Camera Patterns](#3-open-source-repos--ocr--camera-patterns)
4. [Open Source Repos — NLP & Date Parsing](#4-open-source-repos--nlp--date-parsing)
5. [Open Source Repos — Calendar & EventKit](#5-open-source-repos--calendar--eventkit)
6. [Feature Gap Analysis vs Competitors](#6-feature-gap-analysis-vs-competitors)
7. [Actionable Inspiration for EventSnap](#7-actionable-inspiration-for-eventsnap)

---

## 1. Direct Competitors (App Store)

### CalendarSnap
- **URL:** https://apps.apple.com/us/app/calendarsnap/id6760521317
- **Platform:** iOS 17+
- **Model:** Freemium (3 snaps/day free, Pro $2.99/mo or $14.99/yr)
- **Key Features EventSnap DOESN'T have:**
  - Conflict detection — warns if you already have something at that time
  - Time zone intelligence — auto-converts event times
  - Recurring events — detects "every Tuesday" and creates repeating events
  - Smart reminders — suggests reminder timing based on event type
  - Share events — iMessage/AirDrop calendar links
  - Default calendar selection
- **Privacy claim:** "on-device OCR, your photos never leave your device"
- **Notes:** Closest feature-to-feature competitor. Their paid model funds cloud AI for better extraction.

### Calendarco
- **URL:** https://apps.apple.com/us/app/calendarco-event-scanner/id6504715509
- **Platform:** iOS 18+
- **Key Features EventSnap DOESN'T have:**
  - .ics file generation — universal calendar compatibility
  - QR code sharing — send QR so anyone can add the event
  - Batch add — scan once, add multiple dates
  - Recurrence rules — daily/weekly/monthly/yearly repeats
- **Notes:** More business-oriented. iOS 18 minimum is aggressive.

### EventSnag
- **URL:** https://apps.apple.com/us/app/eventsnag/id6754352053
- **Platform:** iOS
- **Key Features EventSnap DOESN'T have:**
  - Multi-event detection — one flyer with 6 events? Catches them all
  - Recurring events — weekly pub runs, monthly meetups, up to 26 occurrences
  - Share Extension — capture from photos shared in any app
  - Discover Tab — see what others in your city are attending
  - Event Roundups — "This Weekend" / "This Week" filters
  - Weekly reminders — push notifications
- **Model:** Free (20 scans/mo), Pro coming
- **Notes:** Built in Oklahoma by Shimmer Labs. Social/discovery features require backend.

### CalendarOCR
- **URL:** https://apps.apple.com/us/app/calendarocr/id6754291511
- **Platform:** iOS 15+
- **Model:** Freemium (3 scans/mo free, Pro $2.99 one-time)
- **Privacy claim:** "All processing on device. No data collection, no tracking."
- **Notes:** Simple, similar positioning to EventSnap. One-time purchase vs subscription.

### Photo2Calendar
- **URL:** https://apps.apple.com/us/app/photo2calendar-scanner-planner/id6736373394
- **Platform:** iOS 15+, Android (Capacitor/React)
- **GitHub (Android/web):** https://github.com/shadrach16/event-scanner-ocr
- **Key tech:** Google Gemini AI for extraction (cloud-based, not on-device)
- **Key Features:**
  - Batch scan (2-5 photos)
  - Google Calendar sync
  - Discover nearby events
  - Multiple input methods (camera, gallery, files, paste text)
- **Notes:** Cross-platform (Capacitor + React + Vite + Tailwind). Uses cloud AI — privacy disadvantage. 50K+ users, 4.8 rating.

### Lumical
- **URL:** https://apps.apple.com/us/app/lumical-scan-to-calendar/id6753274309
- **Platform:** iOS 18.1+, iPhone only
- **Key Features:**
  - "Roster Mode" — specialized for shift workers, digitizes paper rosters
  - Progressive calendar loading
  - Privacy-first processing
- **Notes:** Interesting niche: shift workers with paper schedules. Good UX differentiation.

### EventScan (App Store — note: changed name from EventSnap due to trademark!)
- **URL:** https://apps.apple.com/us/app/event-scan/id6737088852
- **Notes:** "Changed name as EventSnap is Trademarked" — this is relevant to our naming! May need to verify trademark status.

---

## 2. Open Source Repos — Direct Inspiration

### chail/CalPal ⭐3
- **URL:** https://github.com/chail/CalPal
- **What:** iOS app that uses computer vision to detect event poster details and autopopulate calendar events
- **Tech:** Swift, Google Cloud Vision API (requires API key — NOT on-device)
- **License:** None specified
- **Created:** Penn Apps XIV (Fall 2016 hackathon)
- **Relevance:** **Conceptually identical to EventSnap.** But uses cloud OCR (Google Vision) which destroys privacy. EventSnap's on-device approach is strictly better.
- **Inspiration:** Their core flow (photo → OCR → extract details → calendar event) validates the product concept.

### thevedantjha/smart-calendar ⭐0
- **URL:** https://github.com/thevedantjha/smart-calendar
- **What:** AI-assisted calendar manager with local Gemma LLM for natural language + flyer scanning
- **Tech:** Swift, SwiftUI, Google Gemma 3n (on-device LLM), CocoaPods
- **License:** MIT
- **Relevance:** **Very interesting approach.** Uses a local LLM (Gemma) for both NLP chat and flyer OCR interpretation. This is a potential future direction for EventSnap's NLParser — replacing regex/NSDataDetector with a local LLM for much better extraction accuracy.
- **Inspiration:**
  - Chat-with-calendar interaction model
  - Local LLM for messy text interpretation (flyers are messy!)
  - On-device AI processing maintains privacy
- **Warning:** Requires a large model file (~2GB) bundled in the app. Not practical for v1.

### shadrach16/event-scanner-ocr (Photo2Calendar)
- **URL:** https://github.com/shadrach16/event-scanner-ocr
- **What:** Cross-platform event scanner (Cap + React + Vite + Tailwind)
- **Tech:** TypeScript, Capacitor, React, Tailwind, Google Gemini AI
- **Relevance:** Direct competitor with open source code. Uses cloud AI (Gemini) for extraction.
- **Inspiration:**
  - Multiple input methods (camera, gallery, batch, files, paste text) — EventSnap just added these!
  - Discover nearby events — requires backend, not privacy-compatible
  - Their landing page and marketing copy is worth studying

---

## 3. Open Source Repos — OCR & Camera Patterns

### aheze/OpenFind ⭐1,070
- **URL:** https://github.com/aheze/OpenFind
- **What:** App to find text in real life using camera + OCR + photo library search
- **Tech:** Swift, SwiftUI + UIKit, Vision framework, Realm
- **License:** MIT
- **Relevance:** **Best reference for live camera OCR in Swift.** 1600+ commits of production code.
- **Inspiration:**
  - Real-time camera text finding (similar to EventSnap's live scan)
  - Photo library search — OCR entire library and search across it
  - Allergy list matching — find unwanted ingredients instantly
  - 100% offline, privacy-first
  - Extensive custom UI patterns
  - Figma design file available
- **Key pattern:** They use a different approach to Vision — find specific terms rather than extract all text. But the camera pipeline is directly relevant.

### pencilresearch/OpenScanner ⭐1,093
- **URL:** https://github.com/pencilresearch/OpenScanner
- **What:** Free, open-source document scanner for iPhone
- **Tech:** Swift, SwiftUI, Core Data, CloudKit
- **License:** MIT
- **Relevance:** **Best reference for camera + scanning UI in SwiftUI.** Production app on the App Store.
- **Inspiration:**
  - Document scanning UI/UX patterns
  - CloudKit sync implementation (potential reference for encrypted history sync)
  - Clean SwiftUI architecture
  - Privacy-respecting, auditable, ad-free
  - Free forever business model

### Salmik/OCR-Scanner-app ⭐16
- **URL:** https://github.com/Salmik/OCR-Scanner-app
- **What:** Document scanner with OCR using Apple Vision framework
- **Tech:** Swift, WeScan, Vision framework
- **License:** MIT
- **Inspiration:** WeScan library for document edge detection. Could be useful if EventSnap adds automatic document cropping.

### speedyfriend433/TextExtractorApp-SwiftUI ⭐5
- **URL:** https://github.com/speedyfriend433/TextExtractorApp-SwiftUI
- **What:** SwiftUI app that extracts text from images using Vision framework
- **Tech:** Swift, SwiftUI, Vision, Combine
- **License:** MIT
- **Inspiration:**
  - Camera + photo library OCR integration pattern
  - OCR settings UI (language selection, min text height, auto-detect language)
  - Multi-language OCR support — potential future feature for EventSnap

### WezSieTato/ScanNow ⭐59
- **URL:** https://github.com/WezSieTato/ScanNow
- **What:** Fast, simple document scanner for iOS
- **Tech:** Swift, SwiftUI, VisionKit
- **License:** MIT
- **Inspiration:** Minimal scanner UX. Shows that simplicity wins.

---

## 4. Open Source Repos — NLP & Date Parsing

### quire-io/SwiftyChrono ⭐205 / MacPaw/SwiftyChrono ⭐1
- **URL:** https://github.com/quire-io/SwiftyChrono
- **What:** Natural language date parser in Swift (ported from chrono.js)
- **Tech:** Swift, JavaScriptCore (original), now pure Swift port
- **License:** MIT
- **Relevance:** **Directly relevant to EventSnap's NLParser.** Parses "tomorrow", "next Friday 3-4 PM", "5 days ago", etc.
- **Inspiration:**
  - Their parser handles casual date expressions that NSDataDetector misses
  - Forward date option — ensures parsed dates are in the future
  - Multi-language support (English, Japanese, etc.)
  - Date interval extraction — "March 12 - 15" or "next Monday to Wednesday"
  - **Potential integration:** Could replace or supplement EventSnap's NSDataDetector + regex approach for better casual date parsing
- **Warning:** Originally used JavaScriptCore. The Swift port may have performance implications.

### pakerwreah/Calendr ⭐2,180
- **URL:** https://github.com/pakerwreah/Calendr
- **What:** Menu bar calendar for macOS — MVVM, RxSwift, AppKit + SwiftUI
- **Tech:** Swift, RxSwift, AppKit, SwiftUI, EventKit
- **License:** MIT
- **Relevance:** **Best reference for EventKit integration in Swift.** Production macOS calendar with 2K+ stars.
- **Inspiration:**
  - `DateSearchParser.swift` — uses NSDataDetector for date parsing from text (similar to NLParser)
  - URL scheme for date navigation: `calendr://date/december`
  - MVVM architecture with RxSwift
  - Regex-based location blacklist for map/weather display
  - Comprehensive test suite: `DateSearchParserTests.swift`
  - **Key insight:** Their date parser has the same NSDataDetector limitations as EventSnap's NLParser — "unfortunately, there's no way to mock the current date in NSDataDetector"

### soulverteam/NaturalLanguageDateParsing ⭐15
- **URL:** https://github.com/soulverteam/NaturalLanguageDateParsing
- **What:** Parse dates from strings using SoulverCore framework
- **License:** Commercial (free for personal use)
- **Relevance:** Shows what's possible beyond NSDataDetector
- **Inspiration:**
  - Date interval extraction: "March 12 - 15", "next Monday to Wednesday"
  - Much richer parsing than NSDataDetector
  - **Key comparison table** in their README: SoulverCore vs NSDataDetector — exactly the gap EventSnap faces
- **Warning:** SoulverCore is closed-source and commercially licensed. Can't use directly, but the comparison is valuable for understanding our parser's limitations.

### mayankk2308/MKDataDetector ⭐26
- **URL:** https://github.com/mayankk2308/mkdatadetector
- **What:** Convenience wrapper for NSDataDetector in Swift
- **License:** MIT
- **Relevance:** Clean wrapper around exactly what NLParser does
- **Inspiration:**
  - `generateEvent(fromEventStore:withAnalysisResult:)` — creates EKEvent from detected date
  - Structured result types: `DateAnalysisResult`, `URLAnalysisResult`, etc.
  - Organized extraction: dates, addresses, links, phone numbers
  - **Potential integration:** Could replace NLParser's raw NSDataDetector code with this cleaner wrapper

### melvitax/DateHelper ⭐1,501
- **URL:** https://github.com/melvitax/DateHelper
- **What:** High-performance Swift Date extension for parsing, comparing, and formatting
- **License:** MIT
- **Relevance:** Useful for date formatting/comparison utilities
- **Inspiration:**
  - `Date(detectFromString: "Tomorrow at 5:30 PM")` — uses NSDataDetector
  - Cached, thread-safe date formatters
  - Relative date comparison: `.isToday`, `.isTomorrow`, `.isThisWeek`
  - Date adjustment: `.adjust(for: .startOfDay)`, `.adjust(for: .nearestMinute(minute: 30))`

### rursache/ToDoList / SmartDateParser
- **URL:** https://github.com/rursache/ToDoList (see `Services/SmartDateParser.swift`)
- **What:** Smart date parser combining NSDataDetector with regex pre/post-processing
- **Inspiration:**
  - Dangling connectors: "on", "at", "by", "for" — strips these before parsing
  - Leading connectors: same at the start of text
  - Multi-match support with confidence
  - **Directly applicable pattern for improving EventSnap's NLParser**

### keith/reminders-cli
- **URL:** https://github.com/keith/reminders-cli (see `Sources/RemindersLibrary/NaturalLanguage.swift`)
- **What:** CLI tool for Apple Reminders with natural language date parsing
- **Inspiration:**
  - Uses `NSDataDetector` with `.anchored` option for matching from start of string
  - Checks `timeIsSignificant` — knows if user specified a time or just a date
  - **Key pattern:** `timeIsSignificant` check is something EventSnap's NLParser should implement — if the user says "Friday" without a time, that's different from "Friday at 8pm"

---

## 5. Open Source Repos — Calendar & EventKit

### vinhnx/Clendar ⭐705
- **URL:** https://github.com/vinhnx/Clendar
- **What:** Minimal calendar app in SwiftUI with natural language parsing
- **Tech:** Swift, SwiftUI, EventKit, WidgetKit, WatchKit, SiriKit
- **License:** MIT
- **Relevance:** **Best SwiftUI calendar reference.** Full app with widgets, watch, and natural language event creation.
- **Inspiration:**
  - Natural language parsing for event creation (like Apple's "natural language" in Calendar.app)
  - EventKit wrapper: `Shift` package — Result-based wrapper for EventKit
  - Widget implementation (EventSnap's roadmap has this)
  - Apple Watch complications (potential future)
  - Custom app icons (EventSnap already has this)
  - Fastlane for build automation
  - **Shift package:** https://github.com/vinhnx/Shift — could simplify CalendarService

### claustrofob/Yotei ⭐45
- **URL:** https://github.com/claustrofob/Yotei
- **What:** Modular calendar package for iOS — SwiftUI + UIKit
- **Tech:** Swift 6.2, strict concurrency, `@MainActor`-correct
- **License:** MIT
- **Relevance:** **Modern Swift 6.2 calendar component** with strict concurrency
- **Inspiration:**
  - Protocol-based view factories (highly customizable)
  - UIKit-backed performance for scrolling lists
  - `YoteiEvent` model — similar to ParsedEvent
  - `YoteiDaysSequence` — lazy random-access Collection of Dates
  - **If EventSnap ever adds an in-app calendar view**, Yotei is the best reference

---

## 6. Feature Gap Analysis vs Competitors

### Features EventSnap is MISSING that competitors have:

| Feature | Who Has It | Priority | Privacy-Compatible? |
|---|---|---|---|
| **Recurring events** ("every Tuesday") | CalendarSnap, Calendarco, EventSnag | 🔴 HIGH | ✅ Yes — on-device |
| **Multi-event detection** (2+ events from one flyer) | Calendarco, EventSnag | 🔴 HIGH | ✅ Yes — on-device |
| **Conflict detection** (existing events at same time) | CalendarSnap | 🟡 MEDIUM | ⚠️ Requires read access — privacy tradeoff |
| **.ics file export** | Calendarco | 🟡 MEDIUM | ✅ Yes — no cloud needed |
| **Share Extension** (capture from other apps) | EventSnag | 🟡 MEDIUM | ✅ Yes — on-device |
| **Smart reminders** (suggest timing based on event type) | CalendarSnap | 🟢 LOW | ✅ Yes |
| **Time zone intelligence** | CalendarSnap | 🟢 LOW | ✅ Yes |
| **QR code sharing** | Calendarco | 🟢 LOW | ✅ Yes |
| **Natural language chat** | Smart Calendar | 🟢 LOW | ✅ Yes (with local LLM) |
| **Discover nearby events** | EventSnag, Photo2Calendar | ❌ NO | ❌ Requires backend |

### Features EventSnap has that competitors DON'T:

| Feature | Why It's Unique |
|---|---|
| **Write-only calendar access** | Nobody else does this. The privacy moat. |
| **Zero-cloud processing** | CalendarSnap claims on-device but most use cloud AI for extraction |
| **$0/month operating cost** | No backend, no AI API calls, no database |
| **Live scanning with real-time feedback** | Pulsing border, readiness state — most competitors just take a photo and process |
| **Three input modes in one app** | Camera + Voice + Text. Most competitors are photo-only |
| **PII sanitization** | No other competitor strips emails/phones/SSNs from OCR results |

---

## 7. Actionable Inspiration for EventSnap

### Immediate (v1.1 — close feature gaps)

1. **Recurring events** — CalendarSnap and EventSnag both do this. It's the #1 most-requested feature across all competitors. NLParser should detect "every Tuesday", "weekly", "biweekly" patterns and create `EKRecurrenceRule`.

2. **Multi-event detection** — EventSnag catches 6 events from one flyer. NLParser should return `[ParsedEvent]` instead of `ParsedEvent?` when multiple date/title pairs are found.

3. **.ics export** — Calendarco does this. Simple: create an ICS file string from `ParsedEvent` and share via `UIActivityViewController`. No backend needed.

4. **Share Extension** — EventSnag has this. Add a Share Extension target that receives images/text from Safari, Messages, Photos and routes them through the same OCR → NLParser pipeline.

### Medium-term (v1.2 — improve extraction quality)

5. **Better date parsing** — Study SwiftyChrono's approach for casual date expressions that NSDataDetector misses ("next Friday 3-4 PM", "in 2 days", "the 15th"). Consider integrating SwiftyChrono as a supplement to NSDataDetector.

6. **timeIsSignificant check** — From keith/reminders-cli. NLParser should know if the user specified a time or just a date. If no time, don't default to midnight — either leave time blank or ask the user.

7. **SmartDateParser patterns** — From rursache/ToDoList. Strip dangling/leading connectors ("on", "at", "by", "for") before passing to NSDataDetector. This improves parsing accuracy.

8. **Conflict detection (with consent)** — CalendarSnap warns about conflicts. Could offer this as an opt-in feature: "Check for conflicts (requires calendar read access)" — with a clear explanation that this is the ONLY time the app reads your calendar.

### Long-term (v2.0 — next-level features)

9. **Local LLM integration** — Smart Calendar uses Gemma 3n on-device. If Apple's on-device models (Apple Intelligence) become available via API, NLParser could use them for much better extraction from messy flyer text. Privacy-preserving because it's on-device.

10. **Photo library OCR** — OpenFind indexes your entire photo library with OCR. Could add "Scan your screenshots" mode that OCRs all images in your Photos and finds event-like content.

11. **Widget** — Clendar shows this is achievable. Lock screen widget for quick-scan, or "Upcoming events scanned by EventSnap" widget.

12. **Apple Watch** — Clendar has full watch support. Quick voice-to-event from the wrist.

### Repos to Star & Watch

| Repo | Why |
|---|---|
| [aheze/OpenFind](https://github.com/aheze/OpenFind) | Best live OCR reference, MIT license |
| [pencilresearch/OpenScanner](https://github.com/pencilresearch/OpenScanner) | Best scanner UI reference, MIT license |
| [pakerwreah/Calendr](https://github.com/pakerwreah/Calendr) | Best EventKit reference, 2K stars, MIT license |
| [quire-io/SwiftyChrono](https://github.com/quire-io/SwiftyChrono) | NLP date parsing, MIT license |
| [vinhnx/Clendar](https://github.com/vinhnx/Clendar) | SwiftUI calendar + widgets, MIT license |
| [claustrofob/Yotei](https://github.com/claustrofob/Yotei) | Modern Swift 6.2 calendar components |
| [melvitax/DateHelper](https://github.com/melvitax/DateHelper) | Date formatting/parsing utilities |
| [thevedantjha/smart-calendar](https://github.com/thevedantjha/smart-calendar) | Local LLM + calendar integration concept |

---

## Naming Note

**EventScan** on the App Store changed its name from "EventSnap" because "EventSnap is Trademarked." We should verify our trademark status for the name "EventSnap" before App Store submission.
