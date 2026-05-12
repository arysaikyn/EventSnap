# EventSnap App Store Submission Metadata

## 1. App Name
EventSnap

## 2. Subtitle (30 chars max)
Privacy-first event scanner

## 3. Promotional Text (170 chars max)
The only event scanner that never sees your data. On-device OCR, write-only calendar access, and automatic PII redaction. Zero cloud. Zero tracking.

## 4. Description (4000 chars max)

**Tired of important event details getting lost in your photos?**

We've all been there—you snap a picture of a flyer, jot down a voice note, or copy event details from a message, only to have them disappear into your camera roll or notes app. EventSnap solves this forever by turning your scattered event information into calendar events that actually work.

**Three ways to capture events, zero data collection:**

📷 **Camera Scanner** - Point your camera at any flyer, poster, or invitation. EventSnap uses on-device OCR to extract event details without ever sending your photos to the cloud.

🎤 **Voice Input** - Just say it out loud! "Meeting tomorrow at 3pm at the coffee shop" becomes a properly formatted calendar event. Your voice is processed entirely on your device.

⌨️ **Text Input** - Type or paste event details from anywhere. Perfect for copying information from messages, emails, or websites.

**Privacy is our superpower:**

✅ **On-device processing** - All OCR, speech recognition, and event parsing happens locally on your iPhone. Your data never leaves your device.

✅ **Write-only calendar access** - EventSnap can only create new events. It cannot read your existing calendar, keeping your schedule completely private.

✅ **PII sanitization** - Automatically removes emails, phone numbers, and social security numbers from event details before adding them to your calendar.

✅ **No account required** - No sign-ups, no cloud storage, no analytics. Just download and start using.

✅ **No tracking** - No user analytics, no crash reporting, no third-party SDKs. Just pure privacy.

**Perfect for:**

🎓 **Students** - Capture lecture schedules, club meetings, and exam dates from campus flyers

💼 **Professionals** - Turn business cards, conference schedules, and meeting notes into calendar events

👨‍👩‍👧‍👦 **Parents** - Quickly add school events, sports schedules, and appointments from paper notices

🎪 **Event-goers** - Never miss concerts, festivals, or social events again

**How it works:**

1. **Choose your input method** - Camera, voice, or text
2. **Let EventSnap process** - On-device AI extracts event details
3. **Review and confirm** - See exactly what will be added to your calendar
4. **One-tap save** - Event instantly appears in your calendar with proper formatting

**What makes EventSnap different:**

Unlike other event scanners that send your data to cloud AI services (OpenAI, Gemini, etc.), EventSnap keeps everything local. Your photos and voice notes never leave your phone, and your calendar data remains completely private.

**EventSnap respects your privacy by design:**

- No servers, no cloud storage, no data centers
- No analytics, no tracking, no user profiling  
- No third-party dependencies or SDKs
- No login required, no accounts to create
- Zero data collection of any kind

Stop letting important events fall through the cracks. Download EventSnap and experience true privacy-first event management.

---

**Note:** EventSnap requires camera access for scanning, microphone access for voice input, and calendar write-only access for creating events. All permissions are used strictly for their intended purpose and no data is transmitted externally.

## 5. Keywords (100 chars max, comma-separated)
event scanner,calendar,flyer,OCR,privacy,on-device,voice,text,schedule,photo

## 6. Privacy Policy Text

# Privacy Policy for EventSnap

**Last Updated:** May 2026

## What We Don't Collect

EventSnap is designed with privacy as our core principle. We collect **zero data** about you or your usage. This means:

- **No servers, no cloud storage** - All processing happens on your device
- **No analytics** - We don't track how you use the app
- **No crash reporting** - No data is sent when the app encounters issues
- **No user profiles** - No accounts, no logins, no personal information required
- **No third-party SDKs** - No Facebook SDK, Google Analytics, or other tracking libraries

## On-Device Processing

EventSnap uses your iPhone's built-in capabilities to process information locally:

### On-Device OCR
- Camera photos are processed using Apple's Vision framework
- Text extraction happens entirely on your device
- No images are sent to any server or cloud service
- Photos are deleted immediately after processing

### On-Device Speech Recognition  
- Voice input uses Apple's Speech framework with `requiresOnDeviceProcessing = true`
- Audio is never transmitted to Apple or any third party
- All speech recognition happens locally on your device
- Audio files are deleted immediately after processing

### On-Device NLP
- Natural language parsing happens locally using custom algorithms
- No text is sent to external AI services like OpenAI or Gemini
- Event extraction and formatting occurs on your device

## Calendar Integration

EventSnap uses **write-only calendar access** for maximum privacy:

- Can only create new events in your calendar
- Cannot read your existing calendar events
- Cannot modify or delete existing events
- Cannot access event details from other apps
- Calendar access is requested on a per-event basis

## PII Sanitization

EventSnap automatically removes personally identifiable information:

- Email addresses are replaced with `[EMAIL]`
- Phone numbers are replaced with `[PHONE]`  
- Social Security numbers are replaced with `[SSN]`
- URLs are replaced with `[URL]`

This ensures your private information doesn't end up in your calendar notes.

## Data Storage

- **Event History** - Your created events are stored locally using SwiftData
- **No cloud backup** - Event history is not synced to iCloud or any cloud service
- **No external access** - Local data cannot be accessed by us or any third party
- **User control** - You can clear your history at any time in Settings

## Permissions and Why We Need Them

### Camera Access
- **Purpose:** To scan event flyers, posters, and invitations
- **Usage:** Only for capturing images that are immediately processed on-device
- **Privacy:** Photos are never stored, sent to cloud, or shared

### Microphone Access  
- **Purpose:** For voice input when describing events
- **Usage:** Audio is processed immediately on-device for speech recognition
- **Privacy:** Audio files are never stored or transmitted externally

### Speech Recognition Access
- **Purpose:** To convert your voice to text for event creation
- **Usage:** Uses on-device speech recognition with `requiresOnDeviceProcessing = true`
- **Privacy:** No audio is sent to Apple's servers or any third party

### Calendar Write-Only Access
- **Purpose:** To create new events in your calendar
- **Usage:** Can only add new events, cannot read existing ones
- **Privacy:** Your existing calendar events remain completely private

## Contact

If you have privacy questions or concerns, please contact us at:
**privacy@eventsnap.app**

## Changes to This Policy

We may update this privacy policy from time to time. When we do, we'll post the new version here with an updated "Last Updated" date.

---

EventSnap is committed to protecting your privacy. We believe you should be able to manage your events without sacrificing your personal data security.

## 7. What's New (first release)

### Version 1.0.0

**Introducing EventSnap - The Privacy-First Event Scanner**

**Core Features:**
- 📷 **Camera Scanner** - On-device OCR scanning of event flyers and posters
- 🎤 **Voice Input** - Speech-to-text for describing events naturally  
- ⌨️ **Text Input** - Direct text input from any source
- 📅 **Calendar Integration** - Write-only access to create events
- 🔒 **Privacy by Design** - No cloud processing, no data collection, no analytics

**Privacy Features:**
- On-device OCR using Apple Vision framework
- On-device speech recognition with no cloud transmission
- PII sanitization (emails, phones, SSNs automatically redacted)
- No account required, no sign-ups
- No tracking, no analytics, no third-party SDKs

**Event Processing:**
- Smart parsing of dates, times, locations, and event titles
- Confidence scoring for reliable event creation
- Duplicate event detection to prevent calendar clutter
- Multi-page scanning support for long flyers

**User Experience:**
- Clean, intuitive interface with three input modes
- Real-time preview of extracted event details
- Event history with SwiftData local storage
- Easy event editing and calendar management

**Technical Excellence:**
- Built with SwiftUI for modern iOS interface
- SwiftData for efficient local data persistence
- Comprehensive error handling and user feedback
- Full accessibility support

EventSnap makes event management simple while keeping your data completely private. Never worry about your photos or voice notes leaving your phone again!

## 8. App Store Category

**Primary:** Productivity  
**Secondary:** Utilities

## 9. Age Rating

4+ (no violence, no gambling, no user-generated content visible to others, no profanity)

## 10. App Store Review Information

### Review Instructions

**App Overview:**
EventSnap is a privacy-first event scanner that uses on-device AI to turn flyers, voice notes, and text into calendar events. The app processes all data locally without any cloud transmission.

**Key Technical Details:**
- Uses on-device OCR (Vision framework) for camera scanning
- Uses on-device speech recognition with `requiresOnDeviceProcessing = true` for voice input
- Requests write-only calendar access (cannot read existing events)
- Implements PII sanitization to remove emails, phone numbers, and SSNs
- No cloud processing, no analytics, no third-party SDKs
- Built with SwiftUI and SwiftData for local storage

**Required Permissions:**
- **Camera:** Needed for scanning event flyers and posters
- **Microphone:** Needed for voice input functionality  
- **Speech Recognition:** Needed for converting voice to text
- **Calendar Write-Only:** Needed for creating events in calendar

**Test Instructions:**
1. **Camera Test:** Point camera at any event flyer, poster, or invitation with text, then tap capture button
2. **Voice Test:** Tap voice input and say "Meeting tomorrow at 3pm at the coffee shop"
3. **Text Test:** Tap text input and type "Conference next Monday at 10am in Conference Room B"
4. **Verify:** Check that events are created in calendar with proper formatting and no PII

**Privacy Verification:**
- Confirm no network requests are made during operation (use Network Link Conditioner)
- Verify calendar access is write-only (cannot read existing events)
- Check that extracted text is processed locally without cloud transmission

**Expected Behavior:**
- Camera scan should extract event details from images
- Voice input should convert speech to text and parse event information
- Text input should parse directly entered event details
- All processed events should appear in calendar with sanitized PII
- App should work completely offline

## 11. Screenshot Captions

### 6.5" iPhone Screenshot Captions

**1. Camera scan screen**
"Point your camera at any flyer"
*Shows camera viewfinder with scanning overlay and capture button*

**2. Voice input screen**  
"Or just say it out loud"
*Shows voice recording interface with waveform and live transcription*

**3. Text input screen**
"Type or paste event details"
*Shows text input field with examples and formatting options*

**4. Event preview screen**
"Review and edit before saving"
*Shows parsed event details with confidence scores and editable fields*

**5. Calendar confirmation**
"Added to your calendar instantly"
*Shows success confirmation with calendar app integration*

**6. On-device badge**
"Everything stays on your device"
*Shows privacy indicator emphasizing on-device processing and data security*