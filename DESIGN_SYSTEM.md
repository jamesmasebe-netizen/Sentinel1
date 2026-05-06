# Sentinel1 Design System (Material Design 3 Expressive)

This document outlines the core components and layout tokens used to maintain visual and structural consistency across the Sentinel1 platform.

## Core Principles
- **M3 Expressive**: We use the expressive side of Material 3, characterized by larger headers, distinctive shapes (extra-rounded corners), and vibrant but professional color palettes.
- **Context Preservation**: Navigation follows the "Workspace Pattern" where module details are opened in **Side Sheets** instead of navigating away from the current context.
- **Consistency**: Use the standardized widgets in `lib/core/widgets/ds_widgets.dart` for all UI elements.

## Design Tokens (`GSpacing`)
Always use `GSpacing` instead of manual `SizedBox` heights for vertical layout.

| Token | Value | Use Case |
|-------|-------|----------|
| `vXs` | 4.0 | Tiny micro-spacing |
| `vSm` | 8.0 | Small gaps between related items |
| `vMd` | 16.0 | Standard padding/gap |
| `vLg` | 24.0 | Large section spacing |
| `vXl` | 32.0 | Major layout breaks |

## Standard Components (`ds_widgets.dart`)

### 1. `GHeader`
The primary navigation and titling component for all screens and side sheets.
- **Title**: Large, prominent screen title.
- **Subtitle**: Contextual information or description.
- **Actions**: Slot for primary action buttons or menus.

### 2. `GCard`
The base container for all content blocks.
- Uses `surfaceContainerHighest` or `surfaceContainer` colors.
- Features `BorderRadius.circular(24)` or `16` depending on elevation.

### 3. `UIUtils.showSideSheet`
The standard way to present deep-dives or forms.
- **Width**: Responsive (standard side sheet width on desktop/tablet, full width on mobile).
- **Dismissible**: Always includes a top-right close button.

## Iconography
Use `MaterialIcons` with the `_rounded` or `_outlined` suffix to match the M3 aesthetic. Avoid legacy sharp icons.

## Theming
Managed in `lib/config/theme.dart`.
- **Primary**: Indigo/Deep Purple tones for professional trust.
- **Secondary**: Teal/Cyan for operational efficiency.
- **Error**: Vibrant red for critical safety alerts.
- **Surface**: Light gray/white with subtle elevations.
