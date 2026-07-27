# environment — Module Journey Doc

**Path:** `lib/features/environment/`  |  **Compartment:** Human Resources  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`environment` is Sentinel1's Environmental & ESG module: waste manifest tracking, spill incident logging, ESG metric capture (Scope 1/2/3 emissions, water, waste, diversity, training, ethics), and a live analytics rollup across all three. It is a small module (9 files) but is the **cleanest-behaved of the six modules in this batch** at the code level — see §5/§7; its gaps are architectural (rules, BPF wiring) rather than internal bugs.

**In scope:** waste manifest register, environmental spill incident log, ESG metric capture, cross-collection environmental analytics (spill containment rate, waste-type distribution, ESG scorecard).
**Out of scope:** asset/equipment decommissioning itself (owned by `equipment`/`property` — this module only narratively receives a "waste/spill log if hazardous" handoff, with no code link — see §3), hazardous chemical safety data sheets (owned by `safety`'s hazard register).
**IA placement:** Human Resources compartment (8-compartment taxonomy) — this module's primary persona (Environmental & Sustainability Officer) makes it another clear illustration of the doc set's flagged HR/SHEQ tension. See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 2. User Journeys
| Persona | Journey | Steps touching `environment` | Entry screen(s) |
|---|---|---|---|
| [Environmental & Sustainability Officer](_shared_personas_and_bpfs.md#persona-environmental-officer) | ESG Management | Conduct Waste Disposal Audits, Manage Spill Response, Generate ESG Reporting Data | `waste_manifests_tab.dart` + `waste_form.dart`, `spill_logs_tab.dart` + `spill_form.dart`, `esg_metrics_tab.dart` |
| [Environmental & Sustainability Officer](_shared_personas_and_bpfs.md#persona-environmental-officer) | ESG Management (analytics) | Monitor Carbon Footprint / Emissions Data | `environmental_analytics_tab.dart` |
| [QC & Compliance Manager](_shared_personas_and_bpfs.md#persona-qc-compliance-manager) | Quality Assurance (partial) | Cross-reference environmental compliance with corporate reporting | `esg_metrics_tab.dart` (read-only relevance — no code linking this module to `compliance`) |

## 3. BPF Participation
`environment` is named in the [Asset Lifecycle](_shared_personas_and_bpfs.md#bpf-asset-lifecycle) narrative's final step ("Decommissioning: Waste/Spill Log if hazardous"), but **has no dedicated stage or `expectedRecordType`** anywhere in `lib/core/bpf/asset_lifecycle_bpf.dart` — confirmed by reading the file directly: all 4 stages (`acquisition`/`deployment`/`maintenance`/`decommissioning`) carry `expectedRecordType: 'equipment'` only, with no reference to waste, spills, or this module in any form. This is the **narrative-only, no-code-hook** link the task brief anticipated: unlike `safety`'s Issue-to-Resolution (which at least has a rendered, if inert, `BpfRibbonWidget`), `environment` has neither a stage definition nor any ribbon usage anywhere in `lib/features/environment/` (confirmed by direct search). It is not listed in the shared doc's "zero BPF participation" table either, since the *narrative* does mention it — the accurate characterization is: named in prose, absent from code at every level.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route or side-sheet | Purpose |
|---|---|---|
| `environmental_screen.dart` | `/environment` (also correctly linked from the Launchpad's "Environment" tile — not broken, unlike `training`/`compliance`) | 4-tab shell: Waste / Spills / ESG Metrics / Analytics |
| `waste_manifests_tab.dart` + `waste_form.dart` + `waste_list_item.dart` | tab | Waste manifest list + create form |
| `spill_logs_tab.dart` + `spill_form.dart` + `spill_list_item.dart` | tab | Spill incident list + create form |
| `esg_metrics_tab.dart` | tab | ESG metric list + inline create form (side-sheet) |
| `environmental_analytics_tab.dart` | tab | Live cross-collection KPI rollup (spill containment %, waste-type distribution, ESG scorecard grid) — genuinely real-time, no hardcoded values, computed directly from the same three `StreamBuilder`s the other tabs use |

## 5. Backend & Database

**Models:** none — no `models/` directory, no shared `core/models/` class. All tabs work with raw `Map<String, dynamic>`, consistent with `health.md`/`workers_comp.md`.

**Collections:** `waste_manifests`, `environmental_spills`, `esg_metrics` (all under `tenants/{tenantId}/...`). Unlike `health.md`/`training.md`/`compliance.md`'s findings, this module's write/read collection names and field names are **internally consistent** across every form/tab pairing checked (`waste_form.dart` ↔ `waste_manifests_tab.dart`/`waste_list_item.dart`; `spill_form.dart` ↔ `spill_logs_tab.dart`/`spill_list_item.dart`; `esg_metrics_tab.dart`'s own form ↔ its own list) — no collection-name or field-name drift found.

**Firestore rules cross-check:** none of `waste_manifests`, `environmental_spills`, or `esg_metrics` are declared in `firestore.rules` (confirmed absent from the full 238-line file). All three fall through to the catch-all `allow write: if false` — same pattern as every other module in this batch. Assuming this is the deployed ruleset, all three of this module's create forms would fail with permission-denied in production.

**Cloud Functions:** none found in either Functions codebase that reference `waste_manifests`, `environmental_spills`, or `esg_metrics`.

## 6. Cross-Module Links
- `dashboard/providers/dashboard_providers.dart`'s `dashboardWasteProvider` reads `waste_manifests` directly — confirmed consistent with the reference already made in `dashboard.md` §5 (`dashboardWasteProvider` was documented there as aggregating this collection).
- No `AppEventBus` emit or listen usage found anywhere in this module.
- No code link to `equipment`/`property` (the modules that would own the "Decommissioning" trigger this module's BPF narrative describes) was found — see §3.
- No code link to `compliance` was found despite the conceptual overlap between ESG reporting and regulatory compliance tracking.

## 7. Known Gaps

### Rules-vs-code gaps
- `BaseIncident` — mandated by `.agents/AGENTS.md` §5, does not exist anywhere in the codebase (see [_shared doc](_shared_personas_and_bpfs.md#related-rules-vs-code-gap-applicable-wherever-relevant-below)). `spill_form.dart` records what is, in substance, an environmental incident (substance, volume, location, containment status, whether authorities were notified) — this is the module the AGENTS.md §5 example ("`BaseIncident` for Safety **and Environmental** incidents") names explicitly, and it's the clearest concrete candidate pairing with `safety`'s `Incident` model in the whole batch.
- Catch-all rule denies all writes to `waste_manifests`, `environmental_spills`, `esg_metrics` — see §5.

### DB-to-UI alignment audit
`waste_form.dart` vs `waste_manifests_tab.dart`/`waste_list_item.dart`, and `spill_form.dart` vs `spill_logs_tab.dart`/`spill_list_item.dart`:
| Field | Status | Note |
|---|---|---|
| `wasteType`, `quantity`, `unit`, `transporterName`, `disposalFacility`, `status` | Correct | All written and read under matching names |
| `substance`, `volume`, `location`, `contained`, `reportedToAuthorities` | Correct | All written and read under matching names |
| `category`, `value`, `unit`, `period` (ESG) | Correct | Same |

No "Wrong widget"/"Missing"/"Orphan" findings turned up in this module's primary forms — the one respect in which this doc's audit table is genuinely short because the code is clean, not because the check was skipped.

### Other
- **Positive finding, worth recording explicitly**: `environmental_analytics_tab.dart` computes all of its KPIs (spill containment %, waste-type distribution, ESG scorecard) live from the same three Firestore streams the other tabs read — no hardcoded percentages, no stale pre-computed fields. This is a direct, clean contrast to `health.md`'s hardcoded `OHStatChip` percentages, `workers_comp.md`'s fully-static compliance checklist, and `compliance.md`'s stale `daysUntilExpiry`, all found elsewhere in this same HR/SHEQ batch.
- IA/taxonomy conflict: see [_shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Should `asset_lifecycle_bpf.dart`'s `decommissioning` stage gain a real hook into `waste_manifests`/`environmental_spills` (e.g. an `expectedRecordType` variant, or an orchestrator method), given the narrative explicitly describes this handoff and the collections already exist and work?
- Given `BaseIncident` is explicitly supposed to cover "Safety and Environmental incidents" per AGENTS.md §5, should `spill_form.dart`'s data shape be reconciled with `safety`'s `Incident` model as the first concrete step toward that polymorphic base class?
- Should this module gain a link to `compliance`'s regulatory document register, given ESG reporting and regulatory compliance are closely related in most real SHEQ programs?
