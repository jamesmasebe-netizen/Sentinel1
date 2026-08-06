# Risk Module Manifest

## Purpose
The Risk module is central to governance and occupational health and safety compliance. It handles Hazard Identification and Risk Assessments (HIRA), strategic enterprise risks, and mitigation strategies.

## Architecture
- **State Management (updated Wave 2b, 2026-08-06):** real Riverpod provider/service layer under `lib/features/risk/services/` — split into 4 focused services per AGENTS.md §2's "Zero Flat Schemes" granularity principle, since a single flat `RiskService` would have mixed 4 unrelated sub-features' CRUD/query surface:
  - `hira_service.dart` — `HiraService` + `hiraServiceProvider`/`hiraAssessmentsProvider`/`hiraAllAssessmentsProvider`.
  - `dra_service.dart` — `DraService` + `draServiceProvider` and 5 `StreamProvider`s (site list, recent-10, unfiltered-for-aggregation, plus 2 derived KPI providers) covering every read site across `dynamic_risk_assessment_screen.dart`, `risk_command_center_screen.dart` (2 sites), and `risk_hub_screen.dart` (2 sites).
  - `bowtie_service.dart` — `BowtieService` + `bowtieServiceProvider`/`bowtieAnalysesProvider`.
  - `strategic_risk_service.dart` — `StrategicRiskService` + `strategicRiskServiceProvider`/`strategicRisksProvider`/`strategicRiskAllProvider`.

  Every form/screen/widget in this module now reads via `ref.watch(xProvider).when(...)` and writes via `ref.read(xServiceProvider).createX(TypedModel(...))` — no more inline `StreamBuilder<QuerySnapshot>` or `firestoreServiceProvider.createDocument()` calls, mirroring the `compliance` module's service/provider shape exactly.
- **Data Model:** typed models per collection, under `lib/features/risk/models/` except HIRA's:
  - HIRA (`risk_assessments`) — reuses `RiskAssessment` in `lib/core/models/safety_models.dart` (was dead/unused code with a field mapping that didn't actually match the real writer; corrected in place rather than replaced).
  - DRA (`dynamic_risk_assessments`) — its own `DynamicRiskAssessment` model (`models/dynamic_risk_assessment.dart`); the field shape diverges too far from HIRA's to share `RiskAssessment` (different collection, different fields entirely — `taskDescription`/`hazardsIdentified`/`isSafeToProceed` vs. HIRA's `hazard`/`controlMeasure`/`residualRiskLevel`). Still dual-writes legacy `activity`/`area` keys alongside the canonical `taskDescription`/`location` per `docs/fixes/FIX_LIST.md` F-306 — preserved intentionally, not cleaned up.
  - Bow-Tie (`bowtie_analyses`) — `BowtieAnalysis` (`models/bowtie_analysis.dart`).
  - Strategic Risk (`strategic_risks`) — `StrategicRisk` (`models/strategic_risk.dart`).
  - `hazards` has no Risk-owned model or service — it's owned by the `safety` module (`lib/features/safety/widgets/hazard_form_sheet.dart`). `risk_hub_screen.dart`'s one read of it is left as a raw, clearly-commented inline query (no existing safety-module provider fits its tenant-wide unfiltered shape).
- **Key Screens:**
  - `risk_hub_screen.dart` (Top-level command center for Risk)
  - `risk_command_center_screen.dart` (KPI grid + risk distribution matrix)
  - `hira_screen.dart` (Hazard Identification & Risk Assessment)
  - `dynamic_risk_assessment_screen.dart` (Dynamic Risk Assessment)
  - `bowtie_screen.dart` (Bow-Tie Analysis)
  - `strategic_risk_register_screen.dart` (Enterprise level risks)

## Token Optimization Guidelines
- **Self-Improvement Subagents:** The Risk module heavily relies on linking components (e.g. EmployeeSelectors and Project IDs). If you update a selector in `features/people`, spawn a subagent to retrofit the Risk screens.
- **Component Reusability:** Do not write custom bottom sheets or dialogs here. Call `UIUtils.showSideSheet()` or `UIUtils.showToast()`.
- **List Items:** Use `GCard` from `lib/core/widgets/ds_widgets.dart` for risk list items instead of building them from scratch.
