# Design System Update Instructions

## Overview
This document contains the design system specifications from Figma that need to be implemented in the SwiftUI codebase. The typography system needs to be updated to match the Figma design tokens.

## Current Implementation Location
- **Typography File**: `eyespeak/Sources/Core/Typography.swift`
- **Font Family**: Montserrat (Regular, Medium, SemiBold, Bold variants available)

## Figma Design Tokens

### Typography Tokens

Based on the Figma design system, the following typography styles are defined:

1. **BoldHeader** (Bold/18)
   - Font: Montserrat Bold
   - Size: 18pt
   - Weight: 700
   - Line Height: 100%
   - Usage: Headers

2. **RegularHeader** (Regular/18)
   - Font: Montserrat Regular
   - Size: 18pt
   - Weight: 400
   - Line Height: 100%
   - Usage: Regular headers

3. **BoldTitle** (Bold/14)
   - Font: Montserrat Bold
   - Size: 14pt
   - Weight: 700
   - Line Height: 100%
   - Usage: Titles

4. **RegularTitle** (Regular/14)
   - Font: Montserrat Regular
   - Size: 14pt
   - Weight: 400
   - Line Height: 100%
   - Usage: Regular titles

5. **BoldBody** (Bold/9)
   - Font: Montserrat Bold
   - Size: 9pt
   - Weight: 700
   - Line Height: 100%
   - Usage: Body text (bold)

6. **RegularBody** (Regular/9)
   - Font: Montserrat Regular
   - Size: 9pt
   - Weight: 400
   - Line Height: 100%
   - Usage: Regular body text

### Color Tokens
- **Bone White**: #F2F2F2

## Required Updates to Typography.swift

### Current State
The current `Typography` enum exposes the Figma typography tokens:
- `boldHeader`: Montserrat Bold 18pt
- `regularHeader`: Montserrat Regular 18pt
- `boldTitle`: Montserrat Bold 14pt
- `regularTitle`: Montserrat Regular 14pt
- `boldBody`: Montserrat Bold 9pt
- `regularBody`: Montserrat Regular 9pt

### Required Changes

Ensure new UI work references these tokens so typography stays consistent. Legacy system fonts are no longer part of the design system.

## Implementation Notes

1. **Font Weights**: The Figma design uses:
   - Bold = 700 (use `AppFont.Montserrat.bold()`)
   - Regular = 400 (use `AppFont.Montserrat.regular()`)

2. **Line Height**: Figma specifies 100% line height. In SwiftUI, this is typically the default behavior when using custom fonts.

3. **SwiftUI TextStyle Mapping**: 
   - 18pt → `.title3` (closest to 18pt)
   - 14pt → `.body` (closest to 14pt)
   - 9pt → `.caption2` (closest to 9pt)

4. **Migration**: Legacy convenience aliases were removed; update any remaining call sites to use the new tokens when you encounter them.

## Figma Design System Structure

The Figma design shows a Typography section with 6 text style variants:
- Bold/18 (Bold Header)
- Regular/18 (Regular Header)
- Bold/14 (Bold Title)
- Regular/14 (Regular Title)
- Bold/9 (Bold Body)
- Regular/9 (Regular Body)

## Next Steps for Codex

1. **Update Typography.swift** with the new design system tokens
2. **Review existing codebase** to identify where old typography styles are used
3. **Optionally migrate** old typography usages to new design system tokens
4. **Test** that all typography renders correctly with the new sizes and weights

## Color Token Reference

If colors need to be added:
- **Bone White** (#F2F2F2) - Add to `eyespeak/Sources/Core/Color/Color.swift` if needed

---

**Last Updated**: Based on Figma design system selection
**Figma Node IDs**: Typography section (35:1009) containing 6 typography variants
