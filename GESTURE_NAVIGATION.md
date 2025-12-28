# Gesture-Based Navigation

## Overview

Mobile gesture support has been added to enhance the touch experience on mobile devices. This feature enables natural swipe gestures for navigation and pull-to-refresh functionality.

## Features Implemented

### 1. Swipe Navigation Between Tabs

**How it works:**
- Swipe **left** → Navigate to next tab
- Swipe **right** → Navigate to previous tab
- Tab order: League → Matchups → Standings → Trends → (loops back to League)

**Visual Feedback:**
- Smooth visual drag during swipe
- Toast notification showing destination tab
- Animated transitions

### 2. Pull-to-Refresh

**How it works:**
- Pull down from the top of the page when scrolled to top
- Animated refresh indicator appears
- Release when threshold reached to trigger page reload

**Visual Feedback:**
- Circular refresh indicator slides down
- Rotates based on pull distance
- Spinner animation during refresh

## Technical Details

### Mobile Detection
- Activates only on devices with width ≤ 768px
- Desktop users unaffected
- Progressive enhancement approach

### Performance
- Uses passive event listeners for smooth 60fps scrolling
- No impact on page load or interaction performance
- Minimal JavaScript footprint (~8KB)

### Browser Support
- iOS Safari 10+
- Chrome Mobile 50+
- Firefox Mobile 50+
- All modern mobile browsers with Touch Events API

## Usage

Simply use the app normally on a mobile device:

1. **Navigate tabs:** Swipe left or right anywhere on the page
2. **Refresh:** Pull down from the top of the page
3. **Visual cues:** Watch for the toast messages and refresh indicator

## Files Modified

- `lib/mobile-gestures.js` - New gesture handler class
- `lib/standings.html.erb` - Script integration
- `lib/standings_processor.rb` - Asset deployment

## Future Enhancements

Coming soon:
- Long-press contextual menus
- Swipe actions on individual cards
- Haptic feedback for supported devices
- Customizable gesture sensitivity

## Testing

Test on mobile devices or using browser DevTools:
1. Open DevTools (F12)
2. Toggle device toolbar (Ctrl+Shift+M)
3. Select a mobile device preset
4. Test swipe gestures

Note: Mouse drag doesn't trigger gestures - use touch simulation in DevTools.
