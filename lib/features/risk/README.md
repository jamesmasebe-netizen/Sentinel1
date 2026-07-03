# Risk Module Manifest

## Purpose
The Risk module is central to governance and occupational health and safety compliance. It handles Hazard Identification and Risk Assessments (HIRA), strategic enterprise risks, and mitigation strategies.

## Architecture
- **State Management:** Riverpod (`risk_providers.dart`)
- **Data Model:** `RiskEntry` (used for both HIRA and strategic risks)
- **Key Screens:**
  - `risk_hub_screen.dart` (Top-level command center for Risk)
  - `hira_screen.dart` (Hazard Identification & Risk Assessment)
  - `strategic_risk_register_screen.dart` (Enterprise level risks)

## Token Optimization Guidelines
- **Self-Improvement Subagents:** The Risk module heavily relies on linking components (e.g. EmployeeSelectors and Project IDs). If you update a selector in `features/people`, spawn a subagent to retrofit the Risk screens.
- **Component Reusability:** Do not write custom bottom sheets or dialogs here. Call `UIUtils.showSideSheet()` or `UIUtils.showToast()`.
- **List Items:** Use `GCard` from `lib/core/widgets/ds_widgets.dart` for risk list items instead of building them from scratch.
