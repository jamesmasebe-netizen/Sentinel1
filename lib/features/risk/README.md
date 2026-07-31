# Risk Module Manifest

## Purpose
The Risk module is central to governance and occupational health and safety compliance. It handles Hazard Identification and Risk Assessments (HIRA), strategic enterprise risks, and mitigation strategies.

## Architecture
- **State Management:** No dedicated provider/service layer exists yet (no `models/`, `providers/`, or `services/` directory under `lib/features/risk/`). Each screen/widget owns its own inline `StreamBuilder<QuerySnapshot>` reads and `firestoreServiceProvider.createDocument()` writes directly in `build()`.
- **Data Model:** No typed model class — all 4 sub-features read/write raw `Map<String, dynamic>` directly against Firestore. The 5 real collections are `risk_assessments` (HIRA), `dynamic_risk_assessments` (DRA), `strategic_risks`, `bowtie_analyses`, and `hazards`.
- **Key Screens:**
  - `risk_hub_screen.dart` (Top-level command center for Risk)
  - `risk_command_center_screen.dart` (KPI grid + risk distribution matrix)
  - `hira_screen.dart` (Hazard Identification & Risk Assessment)
  - `dynamic_risk_assessment_screen.dart` (Dynamic Risk Assessment)
  - `bowtie_screen.dart` (Bow-Tie Analysis)
  - `strategic_risk_register_screen.dart` (Enterprise level risks)

A larger follow-up (not required for this manifest to be accurate) would introduce a real `RiskService`/`risk_providers.dart` layer — possibly built around `core/models/safety_models.dart`'s existing, currently-unused `RiskAssessment` class — and migrate all 4 forms/screens off inline raw-map CRUD.

## Token Optimization Guidelines
- **Self-Improvement Subagents:** The Risk module heavily relies on linking components (e.g. EmployeeSelectors and Project IDs). If you update a selector in `features/people`, spawn a subagent to retrofit the Risk screens.
- **Component Reusability:** Do not write custom bottom sheets or dialogs here. Call `UIUtils.showSideSheet()` or `UIUtils.showToast()`.
- **List Items:** Use `GCard` from `lib/core/widgets/ds_widgets.dart` for risk list items instead of building them from scratch.
