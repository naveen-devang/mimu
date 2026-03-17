# Dynamic Island Positioning Guide

## Overview
The Dynamic Island position varies slightly across iPhone models, but follows a consistent pattern relative to the safe area inset.

## Device Specifications

### iPhone 14 Pro / 14 Pro Max
- Safe area top: 59pt
- Dynamic Island center: ~37pt from physical top
- Ratio: 37 / 59 ≈ 0.627

### iPhone 15 Pro / 15 Pro Max
- Safe area top: 59pt
- Dynamic Island center: ~37pt from physical top
- Ratio: 37 / 59 ≈ 0.627

### iPhone 16 Pro / 16 Pro Max
- Safe area top: 59pt
- Dynamic Island center: ~37pt from physical top
- Ratio: 37 / 59 ≈ 0.627

## Implementation

```swift
private var dynamicIslandY: CGFloat {
    let safeArea = safeTop
    // Dynamic Island center is at approximately 62.7% of the safe area from top
    return safeArea * 0.627
}
```

## Why This Works

1. **Consistent Ratio**: Apple maintains a consistent ratio across all Dynamic Island devices
2. **Safe Area Based**: Using safe area inset ensures compatibility with future devices
3. **Adaptive**: Automatically adjusts for different screen sizes and orientations
4. **Fallback**: Defaults to 59pt safe area if detection fails (standard for DI devices)

## Testing

Test on multiple devices to ensure proper alignment:
- iPhone 14 Pro
- iPhone 15 Pro / Pro Max
- iPhone 16 Pro / Pro Max

The beam should perfectly align with the Dynamic Island center on all devices.
