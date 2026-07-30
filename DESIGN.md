---
colors:
  primary: "#1A73E8"
  primaryLight: "#8AB4F8"
  primaryDark: "#174EA6"
  secondary: "#202124"
  secondaryLight: "#5F6368"
  success: "#1E8E3E"
  warning: "#F9AB00"
  error: "#D93025"
  info: "#1A73E8"
  surface: "#F8F9FA"
typography:
  primaryFontFamily: "Outfit"
  secondaryFontFamily: "Roboto"
spacing:
  vXs: "4px"
  vSm: "8px"
  vMd: "16px"
  vLg: "24px"
  vXl: "32px"
  vXxl: "48px"
borderRadius:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "28px"
  full: "1000px"
---

# Sentinel1 Design System

This file serves as the definitive source of truth for the Sentinel1 platform design language. It is intended to be used by AI coding agents and design tools (like Google Stitch) to maintain visual and structural consistency across all generated UI components.

## Core Philosophy

Sentinel1 utilizes an **M3 Expressive** design system. It heavily leans on Google's core brand colors and typography to establish a premium, enterprise-grade aesthetic. The layout is optimized for dense data presentation without feeling cluttered.

- **M3 Expressive**: We use the expressive side of Material 3. This means larger headers, distinctive shapes (such as extra-rounded corners on cards and full-pill shapes for buttons), and vibrant, purposeful semantic colors.
- **Context Preservation (Workspace Pattern)**: The UI is designed to keep users in flow. Navigation follows a "Workspace Pattern" where module details, forms, and deep-dives are opened in **Side Sheets** instead of navigating away from the current context.

## Typography

The typography scale leverages two distinct fonts to balance expressive display with dense data readability:
- **Outfit**: Used for Display, Headline, and Title Large elements. This provides a modern, geometric, and distinct look for primary headers.
- **Roboto**: Used for Title Medium/Small, Body, and Label elements. Roboto guarantees maximum legibility for dense lists, data tables, and application interfaces.

## Colors & Semantic Palette

The color system is rooted in the Google brand palette:
- **Primary**: Authentic Google Blue (`#1A73E8`), driving primary actions and focus states.
- **Secondary**: Google Grey 900 (`#202124`), providing stark, legible contrasts for text and secondary actions.
- **Semantic/Status Colors**:
  - Success/Active: Google Green (`#1E8E3E`)
  - Warning/Minor Severity: Google Yellow (`#F9AB00`)
  - Error/Critical: Google Red (`#D93025`)
  - Info: Google Blue (`#1A73E8`)
- **Surface**: The scaffolding utilizes a light gray (`#F8F9FA`) allowing elevated cards (`surfaceLowest`, `Colors.white`) to stand out naturally.

## Layout & Spacing

Spacing is strictly governed by a 4/8pt grid system. Always use the provided spacing tokens rather than arbitrary values.
- `vXs` (4px): Micro-spacing for tight groupings.
- `vSm` (8px): Gaps between related items within a component.
- `vMd` (16px): Standard padding/gap for layout structure.
- `vLg` (24px): Spacing between major content sections.
- `vXl` (32px) and `vXxl` (48px): Major layout breaks and hero spacing.

## Shapes

Rounding is highly pronounced in the M3 Expressive style:
- **Cards & Dialogs**: `28px` (Extra Large) border radius.
- **Buttons**: `1000px` (Full/Pill) border radius.
- **Inputs & Standard Elements**: `12px` (Medium) border radius.

## Iconography

Use `MaterialIcons` with the `_rounded` or `_outlined` suffix to match the M3 Expressive aesthetic. Legacy sharp icons should be avoided.
