#!/bin/bash
# EventSnap Screenshot Automation Script
# Captures screenshots from iOS Simulator for App Store submission

set -e

OUTPUT_DIR="./screenshots"
mkdir -p "$OUTPUT_DIR"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}EventSnap Screenshot Capture${NC}"
echo "=============================="
echo ""

# Check if simulator is running
DEVICE_ID=$(xcrun simctl list devices booted | grep -o '[A-F0-9-]\{36\}' | head -1)
if [ -z "$DEVICE_ID" ]; then
    echo "No simulator running. Please start a simulator first."
    echo "Run: xcrun simctl boot 'iPhone 17 Pro'"
    exit 1
fi

echo "Using simulator: $DEVICE_ID"
echo ""

capture_screenshot() {
    local name=$1
    local description=$2
    echo -e "${GREEN}Capturing: ${description}${NC}"
    xcrun simctl io "$DEVICE_ID" screenshot "$OUTPUT_DIR/$name.png"
    sleep 1
}

echo "Please navigate to each screen in the simulator and press Enter to capture."
echo ""

read -p "1. Navigate to Camera tab (home screen). Press Enter to capture..."
capture_screenshot "01_camera_home" "Camera home screen with live scan"

read -p "2. Point camera at a flyer/text. Press Enter when scan detects text..."
capture_screenshot "02_camera_scanning" "Camera scanning with text detection"

read -p "3. Navigate to Voice tab. Press Enter to capture..."
capture_screenshot "03_voice_home" "Voice input screen"

read -p "4. Navigate to Text tab. Press Enter to capture..."
capture_screenshot "04_text_home" "Text input screen"

read -p "5. Type an event and tap Parse. Press Enter when preview shows..."
capture_screenshot "05_event_preview" "Event preview with details"

read -p "6. Tap 'Add to Calendar'. Press Enter when confirmation shows..."
capture_screenshot "06_confirmation" "Event added confirmation"

read -p "7. Navigate to History tab. Press Enter to capture..."
capture_screenshot "07_history" "Event history list"

read -p "8. Navigate to Settings tab. Press Enter to capture..."
capture_screenshot "08_settings" "Settings screen"

echo ""
echo -e "${GREEN}Screenshots saved to: $OUTPUT_DIR${NC}"
echo ""
echo "Screenshot requirements for App Store:"
echo "- 6.5\" display (iPhone 15 Pro Max): 1290 x 2796 pixels"
echo "- 5.5\" display (iPhone SE): 1242 x 2208 pixels"
echo "- At least 3 screenshots required"
echo "- Recommended: 6-8 screenshots showing key features"
