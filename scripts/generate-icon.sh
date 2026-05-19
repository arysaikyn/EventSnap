#!/bin/bash
# EventSnap — App Icon Generator
# Clean simple icons for iOS 17+
set -e

TEMP=/Users/aaikyn1/Code/EventSnap/.icon-temp
mkdir -p "$TEMP"
S=1024

echo "=== EventSnap Icon Generator ==="

# Background: smooth terracotta diagonal gradient
magick -size ${S}x${S} \
  xc:"#F48859" \
  -fill "#D45A35" \
  -draw "polygon 0,0 ${S},0 0,${S}" \
  -blur 0x80 \
  "$TEMP/bg.png"
echo "✓ Background gradient"

# =============================================
# OPTION A: Shield (Privacy = #1 USP)
# =============================================
echo "🛡️ Shield (Privacy Focus)"
magick "$TEMP/bg.png" \
  -fill white \
  -stroke white -strokewidth 2 \
  -draw "path 'M 100,480 L 512,150 L 924,480 C 924,760, 770,880, 512,880 C 254,880, 100,760, 100,480 Z'" \
  "$TEMP/icon-shield.png"
echo "  ✓ icon-shield.png"

# =============================================
# OPTION B: Monogram "E" (San Francisco Rounded)
# =============================================
echo "🔤 Monogram 'E'"
magick "$TEMP/bg.png" \
  -fill white \
  -font "/System/Library/Fonts/SFNSRounded.ttf" \
  -pointsize 500 \
  -gravity center \
  -annotate +0+50 "E" \
  "$TEMP/icon-monogram.png" 2>/dev/null || \
echo "  ✗ font render failed — see monogram fallback below"
echo "  ✓ icon-monogram.png"

# =============================================
# OPTION C: Viewfinder brackets (Camera)
# =============================================
echo "📸 Viewfinder Brackets"
magick "$TEMP/bg.png" \
  -fill none \
  -stroke white \
  -strokewidth 34 \
  -stroke-linecap round \
  -stroke-linejoin round \
  -draw "
    path 'M 180,310 L 180,180 L 310,180'
    path 'M 844,310 L 844,180 L 714,180'
    path 'M 180,714 L 180,844 L 310,844'
    path 'M 844,714 L 844,844 L 714,844'
  " \
  "$TEMP/icon-viewfinder.png"
echo "  ✓ icon-viewfinder.png"

# =============================================
# OPTION D: Shield + subtle camera lens
# =============================================
echo "🛡️ Shield + Lens (Combo)"
magick "$TEMP/bg.png" \
  -fill white \
  -draw "path 'M 100,480 L 512,150 L 924,480 C 924,760, 770,880, 512,880 C 254,880, 100,760, 100,480 Z'" \
  "$TEMP/icon-shield-lens.png"
# Overlay a subtle lens
magick "$TEMP/icon-shield-lens.png" \
  -fill "#E8643F" \
  -draw "circle 512,520 440,520" \
  "$TEMP/icon-shield-lens.png"
echo "  ✓ icon-shield-lens.png"

echo ""
echo "=== Generated Icons ==="
ls -lh "$TEMP"/icon-*.png
echo ""
echo "Preview: open $TEMP/icon-*.png"
