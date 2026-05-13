# EventSnap — App Store Submission Guide

This document contains everything needed to submit EventSnap to the App Store.

---

## 1. Prerequisites

### Apple Developer Account
- Enroll at [developer.apple.com/programs](https://developer.apple.com/programs/)
- Cost: $99/year
- Required for App Store distribution

### Xcode Configuration
- Open `EventSnap.xcodeproj` in Xcode
- Select the EventSnap target
- Go to **Signing & Capabilities**
- Select your Team (Apple Developer account)
- Ensure **Automatically manage signing** is checked
- Bundle Identifier: `com.yourname.eventsnap` (must be unique)

---

## 2. App Icon

✅ **Completed** — App icon generated and placed in:
```
EventSnap/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

The icon features:
- Terracotta gradient background (#E85D3A → #C04A2D)
- White camera/viewfinder symbol
- iOS squircle shape

---

## 3. Privacy Policy

✅ **Completed** — Privacy policy HTML page created at:
```
docs/privacy/index.html
```

### Hosting Options

**Option A: GitHub Pages (Free)**
1. Push repository to GitHub
2. Go to repository Settings → Pages
3. Source: Deploy from a branch
4. Branch: `main` (or `master`), folder: `/docs`
5. Save → Wait 2-3 minutes
6. URL: `https://arysaikyn.github.io/EventSnap/privacy/`

**Option B: Custom Domain**
1. Purchase domain (e.g., `eventsnap.app`)
2. Host `index.html` on any web server
3. URL: `https://eventsnap.app/privacy`

**Option C: Apple's Privacy Policy URL**
- If you don't have a website, you can use a free hosting service:
  - GitHub Pages (recommended)
  - Netlify Drop (drag and drop HTML)
  - Vercel

---

## 4. Screenshots

### Required Sizes
| Device | Size | Resolution |
|--------|------|------------|
| iPhone 15 Pro Max (6.5") | Required | 1290 × 2796 px |
| iPhone SE (5.5") | Required | 1242 × 2208 px |
| iPhone 15 Pro (6.1") | Optional | 1179 × 2556 px |
| iPad Pro 12.9" | Optional | 2048 × 2732 px |

### Capture Method

**Using Simulator:**
1. Run app in Xcode simulator
2. Use the capture script:
   ```bash
   ./scripts/capture-screenshots.sh
   ```
3. Or manually: `xcrun simctl io booted screenshot screenshot.png`

**Using Real Device:**
1. Connect iPhone to Mac
2. Open QuickTime Player
3. File → New Movie Recording
4. Select your iPhone as camera
5. Navigate through app and take screenshots

### Recommended Screenshots (8 total)
1. **Camera home** — Live scan viewfinder with readiness indicator
2. **Camera scanning** — Text detected, showing "Event details found"
3. **Voice input** — "Tap to Speak" screen with waveform
4. **Text input** — Text editor with placeholder
5. **Event preview** — Parsed event with calendar picker
6. **Confirmation** — "Added to Calendar" with subtle confetti
7. **History** — Event list with search
8. **Settings** — Privacy section showing on-device badge

---

## 5. App Store Connect Setup

### Create App Entry
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - **Name:** EventSnap
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select your registered bundle ID
   - **SKU:** `eventsnap-ios-2026`
   - **User Access:** Full Access

### App Information
| Field | Value |
|-------|-------|
| Name | EventSnap |
| Subtitle | Privacy-first event scanner |
| Category | Productivity (Primary), Utilities (Secondary) |
| Content Rights | Does not contain third-party content |
| Age Rating | 4+ |

### Pricing and Availability
- **Price:** Free (or set price)
- **Availability:** All countries/regions
- **Pre-order:** No

---

## 6. App Metadata

### Description
```
Tired of important event details getting lost in your photos?

EventSnap turns flyers, voice notes, and text into calendar events — completely on your device. No cloud processing. No data collection. No accounts required.

Three ways to capture events:
📷 Camera Scanner — Point at any flyer or invitation
🎤 Voice Input — Just say your event details
⌨️ Text Input — Type or paste from anywhere

Privacy is our superpower:
✅ On-device processing — nothing leaves your iPhone
✅ Write-only calendar access — we can't read your events
✅ PII sanitization — emails and phones automatically removed
✅ No tracking, no analytics, no third-party SDKs

Perfect for students, professionals, parents, and anyone who wants to capture events quickly without sacrificing privacy.
```

### Keywords (100 characters max)
```
event scanner,calendar,flyer,OCR,privacy,on-device,voice,text,schedule,photo
```

### Promotional Text (170 characters max)
```
The only event scanner that never sees your data. On-device OCR, write-only calendar access, and automatic PII redaction. Zero cloud. Zero tracking.
```

---

## 7. Build and Archive

### Create Archive
1. In Xcode, select **Any iOS Device** (not simulator)
2. Product → Archive
3. Wait for build to complete
4. Window → Organizer → Select archive
5. Click **Distribute App**
6. Select **App Store Connect**
7. Upload

### Build Settings
- **Deployment Target:** iOS 17.0
- **Supported Platforms:** iPhone
- **Signing:** Automatic (your Team)
- **Configuration:** Release

---

## 8. App Review Information

### Review Notes
```
EventSnap is a privacy-first event scanner that processes all data on-device.

Key technical details:
- Uses Apple Vision framework for OCR (on-device)
- Uses Apple Speech framework with requiresOnDeviceProcessing = true
- Calendar access is write-only (cannot read existing events)
- PII sanitization removes emails, phones, SSNs before calendar insertion
- No network requests, no cloud processing, no analytics

Test instructions:
1. Camera: Point at any event flyer, tap capture
2. Voice: Tap microphone, say "Meeting tomorrow at 3pm at coffee shop"
3. Text: Type "Lunch with Sarah next Tuesday at 1pm"
4. Verify: Events appear in calendar with proper formatting

The app works completely offline.
```

### Contact Information
- **First Name:** [Your name]
- **Last Name:** [Your name]
- **Phone:** [Your phone]
- **Email:** [Your email]

---

## 9. Privacy Declarations

### App Privacy Details (App Store Connect)
Since EventSnap collects **no data**, select:
- **Data Not Collected** for all categories

### Privacy Nutrition Labels
| Category | Data Type | Purpose | Linked to Identity | Used for Tracking |
|----------|-----------|---------|-------------------|-------------------|
| Contact Info | None | — | No | No |
| Health & Fitness | None | — | No | No |
| Financial Info | None | — | No | No |
| Location | None | — | No | No |
| Sensitive Info | None | — | No | No |
| Contacts | None | — | No | No |
| User Content | None | — | No | No |
| Browsing History | None | — | No | No |
| Search History | None | — | No | No |
| Identifiers | None | — | No | No |
| Usage Data | None | — | No | No |
| Diagnostics | None | — | No | No |
| Other | None | — | No | No |

---

## 10. Submission Checklist

- [ ] Apple Developer account enrolled
- [ ] Bundle ID registered
- [ ] App icon (1024x1024) ✅
- [ ] Privacy policy URL ✅
- [ ] Screenshots (6.5" + 5.5")
- [ ] App description
- [ ] Keywords
- [ ] Age rating (4+)
- [ ] Build archived and uploaded
- [ ] Privacy declarations completed
- [ ] Review notes added
- [ ] Submit for review

---

## 11. Post-Submission

### Review Timeline
- **Typical:** 24-48 hours
- **First submission:** May take longer (up to 7 days)
- **Rejection:** Address feedback and resubmit

### Common Rejection Reasons
1. **Missing privacy policy** — Ensure URL is accessible
2. **Incomplete metadata** — Fill all required fields
3. **Crashes on launch** — Test on real device before submitting
4. **Guideline violations** — Review Apple's App Store Review Guidelines

### After Approval
1. App appears in App Store within 24 hours
2. Monitor App Store Connect for crash reports
3. Respond to user reviews
4. Plan v1.1 features (see roadmap in AGENTS.md)

---

## Quick Reference

| Item | Value |
|------|-------|
| App Name | EventSnap |
| Bundle ID | `com.yourname.eventsnap` |
| Version | 1.0.0 |
| Build | 1 |
| Min iOS | 17.0 |
| Category | Productivity |
| Price | Free |
| Privacy Policy | `https://arysaikyn.github.io/EventSnap/privacy/` |
| Support URL | `https://github.com/arysaikyn/EventSnap` |
