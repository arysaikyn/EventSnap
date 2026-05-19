# Share Extension Setup Guide

## EventSnap Share Extension (EventSnapShareExtension)

This guide walks you through adding the Share Extension target to EventSnap in Xcode.

**Time Required:** 10-15 minutes

**Prerequisites:**
- Xcode 26 with the EventSnap project open
- Apple ID (free is fine — no $99/year needed for local testing)
- iPhone or iPad connected to your Mac (for testing)

> **Free Apple ID limitations:** You can build, test, and use the Share Extension on your personal device.
> The only thing you can't do is submit to the App Store — that requires the $99/year Developer Program.

---

## Step 1: App Group (Free Apple ID — No $99 Account Needed)

> **Good news:** You don't need a paid Developer Program membership for this.
> With a free Apple ID, App Groups still work for local development and testing on your own device.
> You only need the $99/year account to **submit to the App Store**.

1. Open EventSnap.xcodeproj in Xcode
2. Select **EventSnap** target → **Signing & Capabilities**
3. Click **+ Capability** → Select **App Groups**
4. Click **+** under App Groups → Enter: `group.com.arys.EventSnap`
5. Do the same for the **EventSnapShareExtension** target (add the same group)

### App Store Restriction (Free Account)
- ✅ Build and test on personal device
- ✅ Share Extension works locally
- ✅ App Groups work
- ❌ Cannot submit to App Store (requires $99/year Developer Program)

---

## Step 2: Add Share Extension Target in Xcode

1. Open EventSnap.xcodeproj in Xcode
2. **File → New → Target**
3. Select **Share Extension** template
4. Configure:
   - **Product Name:** `EventSnapShareExtension`
   - **Team:** Your personal team (your Apple ID email)
   - **Bundle Identifier:** Xcode will auto-generate one with your personal team prefix
   - **Language:** Swift
5. Click **Finish**
6. If Xcode prompts to activate the scheme, click **Activate**

---

## Step 3: Configure App Group Entitlements

1. Select the **EventSnapShareExtension** target in the project navigator
2. Go to **Signing & Capabilities**
3. Click **+ Capability** → Select **App Groups**
4. Check `group.com.arys.EventSnap`
5. Do the same for the main **EventSnap** target

---

## Step 4: Replace Default Extension Files

Xcode generates default Share Extension files. Delete them and add our custom files:

1. **Delete these auto-generated files:**
   - `ShareViewController.swift`
   - `ShareExtension.entitlements` (auto-generated one)
   - `Info.plist` (auto-generated one)

2. **Add our custom files from `EventSnapShareExtension/` directory:**
   - `ShareExtensionApp.swift` — Main SwiftUI entry point
   - `ShareExtensionViewModel.swift` — Extension logic
   - `ShareExtensionViewController.swift` — UIViewController wrapper for iOS 17
   - `Info.plist` — Proper extension configuration
   - `Entitlements` — App group and privacy entitlements

3. In Xcode: Right-click the `EventSnapShareExtension` group → **Add Files to "EventSnap"**
   - Select all files from `EventSnapShareExtension/`
   - Check: **Copy items if needed**
   - Check: **Add to target: EventSnapShareExtension**

---

## Step 5: Add Shared Code to Extension Target

The extension needs access to:
- `NLParser.swift` (text parsing)
- `ParsedEvent.swift` (event model)
- `CalendarService.swift` (calendar saves)
- `EventHistory.swift` (history model)
- `DesignSystem.swift` (UI components and colors)
- All files in `Models/`, `Services/NLParser.swift`, `Services/CalendarService.swift`
- `Extensions/` files (Color+Hex, Date+Extensions)

**For each file:**
1. Select the file in the Project Navigator
2. In the **File Inspector** (right panel) → **Target Membership**
3. Check **EventSnapShareExtension**

**Files to share:**
```
✅ Models/ParsedEvent.swift
✅ Models/EventHistory.swift
✅ Models/InputMode.swift
✅ Services/NLParser.swift
✅ Services/CalendarService.swift
✅ Services/PermissionManager.swift
✅ Extensions/Color+Hex.swift
✅ Extensions/Date+Extensions.swift
✅ Design/DesignSystem.swift
✅ Utilities/PIISanitizer.swift
```

---

## Step 6: Extension Configuration

### Extension configuration:
Verify these in the copied `Info.plist`:
- `NSExtensionActivationRule` supports:
  - `NSExtensionActivationSupportsText` = YES
  - `NSExtensionActivationSupportsImageWithMaxCount` = 1
  - `NSExtensionActivationSupportsWebURLWithMaxCount` = 1
- `NSExtensionPrincipalClass` = `$(PRODUCT_MODULE_NAME).ShareExtensionViewController`
- `NSExtensionPointIdentifier` = `com.apple.share-services`

### Entitlements (free accounts use Xcode auto-managed):
The App Group capability you added in Step 1 handles entitlements automatically. Don't edit files manually.

### Build Settings:
- **iOS Deployment Target:** 17.0 (same as main app)
- **Swift Version:** 5.9
- **Strict Concurrency Checking:** Complete

---

## Step 7: Test the Extension

1. Build the main app first: `Cmd + B`
2. Build the extension: Select **EventSnapShareExtension** scheme → `Cmd + B`
3. **Run on your iPhone** (not simulator — share extensions work best on device):
   - Connect iPhone via USB → Select your device as destination → `Cmd + R`
   - Xcode will sign with your free Apple ID (needs to re-sign every 7 days)
   - If prompted, go to iPhone Settings → General → VPN & Device Management → Trust your profile

4. In Safari, open any webpage with event text
5. Tap **Share** → Find **EventSnap**
   - If not visible: Scroll down → Tap **More** → Toggle EventSnap on
6. The extension should appear with EventSnap branding
7. Share some event text → Extension processes and shows preview
8. Tap **Add to Calendar** → Event saves → Success screen appears

> **Every 7 days:** Free Apple ID provisioning expires. Re-run from Xcode to re-sign both app and extension.

---

## Troubleshooting

### Extension not appearing in share sheet?
- Check `NSExtensionActivationRule` in Info.plist
- Ensure the extension is built and installed
- Try resetting simulator: Device → Erase All Content and Settings

### Crash on extension launch?
- Check console logs in Xcode: Debug → System Console
- Verify all shared files have correct target membership
- Ensure App Group identifier matches between main app and extension

### Calendar save fails?
- Extension needs its own Calendar permission (prompted on first use)
- Verify EventKit usage description in extension's Info.plist:
  ```xml
  <key>NSCalendarsUsageDescription</key>
  <string>EventSnap saves events to your calendar.</string>
  ```

### Build errors about missing modules?
- Make sure shared files are included in **both** targets
- Check that file inspector target membership has EventSnapShareExtension checked

---

## File Map

```
EventSnapShareExtension/
├── ShareExtensionApp.swift          → @main SwiftUI entry point
├── ShareExtensionViewModel.swift    → Extension logic and state machine
├── ShareExtensionViewController.swift → UIViewController wrapper for iOS 17
├── Info.plist                       → Extension configuration and activation rules
├── EventSnapShareExtension.entitlements → App group entitlements
└── SETUP.md                        ← You are here
```

---

## Privacy Considerations

The Share Extension maintains EventSnap's zero-cloud privacy promise:
- All processing happens on-device
- No analytics, no crash reporting, no cloud sync
- Text/images are processed locally through NLParser/OCRService
- Calendar saves use write-only EventKit access (same as main app)
- No data is shared back to the main app via App Group (extension is self-contained)