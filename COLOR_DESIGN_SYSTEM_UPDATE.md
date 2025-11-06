# Color Design System Update Instructions

## Overview

This document contains the color design system specifications from Figma that need to be implemented in the SwiftUI codebase. The color system in `Color.swift` needs to be updated to match the Figma design tokens.

## Current Implementation Location

- **Color File**: `eyespeak/Sources/Core/Color/Color.swift`
- **Gradient File**: `eyespeak/Sources/Core/LinearGradient.swift`

## Figma Design Tokens

### Gradient Colors

1. **Orange Gradient**

   - Start Color: `#F6924F`
   - End Color: `#E21E1E`
   - Usage: Gradient backgrounds

### Primary Colors

1. **Energetic Orange**

   - Hex: `#FE773C`
   - Usage: Primary accent color

2. **Old Hulk Green**

   - Hex: `#2FA553`
   - Usage: Success states, positive actions

3. **Mellow Blue**

   - Hex: `#586C9D`
   - Usage: Primary blue color (currently used as `customBlue`)

4. **Widow Purple**

   - Hex: `#AD6AE3`
   - Usage: Secondary accent color

5. **Charming Yellow**

   - Hex: `#F6CA33`
   - Usage: Warning states, highlights

### Black, White, and Shades

1. **White White**

   - Hex: `#FFFFFF`
   - Usage: Pure white backgrounds and text

2. **Bone White**

   - Hex: `#F2F2F2`
   - Usage: Off-white backgrounds, subtle separators

3. **Placeholder**

   - Hex: `#ACACAC`
   - Usage: Placeholder text, disabled states

4. **Blueack**

   - Hex: `#363636`
   - Usage: Dark text, primary dark color

## Current State

The current `Color.swift` file has:

- `customBlue` extension property (matches Mellow Blue #586C9D)
- `init?(hex:)` initializer for hex color support
- `CustomColor` enum with some colors (incomplete, missing `#` prefix on some values)

The current `LinearGradient.swift` has:

- `redOrange` gradient (similar to Orange Gradient but with slightly different values)

## Required Changes

### Update Color.swift

Replace the current implementation with the complete Figma design system:

```swift
//
//  Color.swift
//  eyespeak
//
//  Created by Dwiki on 03/11/25.
//

import SwiftUI

extension Color {
    // MARK: - Primary Colors
    
    /// Energetic Orange - #FE773C
    static let energeticOrange = Color(hex: "#FE773C")!
    
    /// Old Hulk Green - #2FA553
    static let oldHulkGreen = Color(hex: "#2FA553")!
    
    /// Mellow Blue - #586C9D
    static let mellowBlue = Color(hex: "#586C9D")!
    
    /// Widow Purple - #AD6AE3
    static let widowPurple = Color(hex: "#AD6AE3")!
    
    /// Charming Yellow - #F6CA33
    static let charmingYellow = Color(hex: "#F6CA33")!
    
    // MARK: - Black, White, and Shades
    
    /// White White - #FFFFFF
    static let whiteWhite = Color(hex: "#FFFFFF")!
    
    /// Bone White - #F2F2F2
    static let boneWhite = Color(hex: "#F2F2F2")!
    
    /// Placeholder - #ACACAC
    static let placeholder = Color(hex: "#ACACAC")!
    
    /// Blueack - #363636
    static let blueack = Color(hex: "#363636")!
    
    // MARK: - Legacy Support
    
    /// Legacy alias for mellowBlue (backward compatibility)
    static let customBlue = Color.mellowBlue
    
    // Initialize from hex string like "#RRGGBB" or "RRGGBB"
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - CustomColor Enum (Optional - for programmatic access)

public enum CustomColor: String {
    case energeticOrange = "#FE773C"
    case oldHulkGreen = "#2FA553"
    case mellowBlue = "#586C9D"
    case widowPurple = "#AD6AE3"
    case charmingYellow = "#F6CA33"
    case whiteWhite = "#FFFFFF"
    case boneWhite = "#F2F2F2"
    case placeholder = "#ACACAC"
    case blueack = "#363636"
    
    var color: Color {
        Color(hex: self.rawValue) ?? Color.clear
    }
}
```

### Update LinearGradient.swift

Update the gradient to match the Figma Orange Gradient specification:

```swift
//
//  LinearGradient.swift
//  eyespeak
//
//  Created by Dwiki on 30/10/25.
//

import Foundation
import SwiftUI

extension LinearGradient {
    /// Orange Gradient - From #F6924F to #E21E1E
    static let orangeGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#F6924F")!,
            Color(hex: "#E21E1E")!
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Legacy alias for backward compatibility
    static let redOrange = LinearGradient.orangeGradient
}
```

## Implementation Notes

1. **Color Naming**: Use descriptive names from Figma:
   - `energeticOrange` instead of generic `orange`
   - `mellowBlue` instead of `customBlue` (keep `customBlue` as alias for backward compatibility)
   - `oldHulkGreen` instead of generic `green`

2. **Hex Initializer**: The existing `init?(hex:)` initializer is correct and should be kept. All colors should use this initializer for consistency.

3. **Backward Compatibility**:
   - Keep `customBlue` as an alias to `mellowBlue` to avoid breaking existing code
   - Keep `redOrange` as an alias to `orangeGradient` if it's used in the codebase

4. **Color Usage Guidelines**:
   - **Energetic Orange**: Primary actions, CTAs, highlights
   - **Old Hulk Green**: Success states, confirmations
   - **Mellow Blue**: Primary brand color, navigation
   - **Widow Purple**: Secondary actions, accents
   - **Charming Yellow**: Warnings, attention states
   - **Bone White**: Subtle backgrounds, cards
   - **Placeholder**: Disabled states, placeholder text
   - **Blueack**: Primary text, dark elements

5. **Gradient Usage**:
   - The Orange Gradient should be used for hero sections, buttons, or backgrounds that need visual interest

## Migration Notes

1. **Existing Code References**:
   - `Color.customBlue` → Will continue to work (aliased to `mellowBlue`)
   - `Color(hex: "#586C9D")` → Can now use `Color.mellowBlue`
   - `CustomColor.blue` → Should be updated to `CustomColor.mellowBlue` or `Color.mellowBlue`

2. **Search and Replace Recommendations**:
   - Search for `Color.customBlue` usage and document where it's used
   - Search for `CustomColor.blue` and update to `CustomColor.mellowBlue`
   - Search for hardcoded hex values that match design system colors

3. **Testing**:
   - Verify all color usages render correctly
   - Check that gradients display properly
   - Ensure accessibility contrast ratios are met

## Figma Design System Structure

The Figma design shows a Color section with:

- **Gradient Section**: 1 gradient (Orange Gradient)
- **Primary Color Section**: 5 primary colors (Energetic Orange, Old Hulk Green, Mellow Blue, Widow Purple, Charming Yellow)
- **Black White and Shades Section**: 4 neutral colors (White White, Bone White, Placeholder, Blueack)

## Next Steps for Codex

1. **Update Color.swift** with all Figma color tokens
2. **Update LinearGradient.swift** with the Orange Gradient specification
3. **Search codebase** for hardcoded color values that should use design system colors
4. **Update references** from old color names to new design system names
5. **Test** that all colors render correctly and maintain visual consistency
6. **Document** any color usage patterns for future reference

---

**Last Updated**: Based on Figma design system selection
**Figma Node IDs**: Color section (35:958) containing gradient, primary colors, and neutral colors

