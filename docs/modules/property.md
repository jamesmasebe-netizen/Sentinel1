# property — Module Journey Doc

**Path:** `lib/features/property/`  |  **Compartment:** Supply Chain Management  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`property` is Sentinel1's real-estate/facilities register: a `Property` master record (site/building) with five read-only sub-views (Operations, Facility Mgmt/Projects, Assets, Leases, ESG/Utilities) surfaced as tabs on a detail screen, plus a portfolio hub with a live Google Map. Unlike `supply_chain`, this module's screens are genuinely wired end-to-end to real Firestore streams and are reachable from real navigation — its main weakness is elsewhere (rules coverage and hardcoded sub-panels, §5/§7).

**In scope:** property/site master data (address, geo-coordinates, floors, occupancy/capacity, construction date, manager), and read-only display of per-property facility projects, legal appointments, linked assets, leases, and utility/ESG usage.
**Out of scope:** the equipment/maintenance domain itself (owned by `equipment`), the supply-chain EAM `Asset`/`assets` concept (owned by `supply_chain`, a structurally separate model from this module's own `AssetInfo`/`property_assets`, see §6), incident/permit records themselves (owned by `safety`, only referenced decoratively here — §4).
**IA placement:** Supply Chain Management compartment (8-compartment taxonomy). See [_shared_personas_and_bpfs.md — IA Taxonomy Note](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved). `docs/schema_scm.md`'s EAM section (`assets` collection, `category: FACILITY`) is thematically adjacent but not the schema this module actually reads/writes — this module doesn't correspond to any specific section of that schema doc.

## 2. User Journeys
| Persona | Journey | Steps touching `property` | Entry screen(s) |
|---|---|---|---|
| [Supply Chain & Facilities Manager](_shared_personas_and_bpfs.md#persona-scm-facilities-manager) (primary) | Asset Lifecycle / Procure to Pay (narrative — see §3) | `PropertyHubScreen` (`/properties`) → "Add Property" → `PropertyFormSheet`; `PropertyCard` → `PropertyDetailsScreen` (`/property/:id`) tabs | `property_hub_screen.dart`, `property_details_screen.dart` |
| Security/Gate Access Personnel (secondary, per module assignment) | "Scan Employee/Contractor QR Code... Grant/Deny Site Access" per [shared doc](_shared_personas_and_bpfs.md#persona-security-gate-access) | **No code hook found.** The actual QR-passport screens (`EmployeeQrPassportScreen`, `ContractorQrPassportScreen`) live entirely under `lib/features/safety/`, not here — confirmed by grep, zero references either direction between `property` and those screens or any "gate access" concept | — |

Reachability, confirmed via router: `/properties` → `PropertyHubScreen`, `/property/:id` → `PropertyDetailsScreen` (`router.dart:245-255`), both real `GoRoute`s. `PropertyCard.onTap` and `PropertyMapCard`'s map-marker `onTap` both correctly use `context.push('/property/${property.id}')`. This module's screens are properly linked to each other and to the router — a meaningfully different reachability picture than `supply_chain`'s (§4 of that doc).

## 3. BPF Participation
| BPF | Stage(s) this module implements (narrative) | Code reference |
|---|---|---|
| [Asset Lifecycle](_shared_personas_and_bpfs.md#bpf-asset-lifecycle) | Named in the BPF's "Modules" list (`equipment, property, supply_chain, field_service`) | `asset_lifecycle_bpf.dart`'s 4 stages are all `expectedRecordType: 'equipment'` — none references `property`, `properties`, or any field on the `Property` model |
| [Procure to Pay](_shared_personas_and_bpfs.md#bpf-procure-to-pay) | Named in the BPF's "Modules" list (`supply_chain, finance, contractors, property`) | `procure_to_pay_bpf.dart`'s 5 stages are `expectedRecordType: 'purchase_order'`/`'invoice'` — none references `property` |

Confirmed directly, per this doc's brief: `property` is named in both BPFs' module lists in the [shared doc](_shared_personas_and_bpfs.md#business-process-flows-bpfs), but **neither BPF's actual stage definitions reference this module, its collections, or its model in any way** — grepped `lib/core/bpf/` for "property"/"Property", zero matches outside the two module-list mentions already covered by the shared doc's own text. `BpfRibbonWidget` usage: confirmed **absent** from `lib/features/property/` (no import, no instantiation). `BpfOrchestrator`: confirmed absent — no method touches `Property` or any `property_*` collection. This is narrative participation in the fullest sense — named twice, wired nowhere.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route or entry point | Purpose / wiring |
|---|---|---|
| `property_hub_screen.dart` (`PropertyHubScreen`) | `/properties` | Portfolio hub: live stats row (computed from `propertiesProvider`), `PropertyMapCard`, grid of `PropertyCard`s. "Add Property" opens `PropertyFormSheet` via raw `showModalBottomSheet` (not `UIUtils.showSideSheet` — AGENTS.md §1 violation, confirmed against `ui_utils.dart`'s actual `showSideSheet` implementation, which adds responsive wide-screen side-sheet behavior this bypasses). "View All" button is a `UIUtils.showToast(...)`-only no-op |
| `property_details_screen.dart` (`PropertyDetailsScreen`) | `/property/:id` | 5-tab detail shell; edit icon opens `PropertyFormSheet` via the same raw `showModalBottomSheet`; share icon is a `UIUtils.showToast`-only no-op |
| `widgets/property_form_sheet.dart` (`PropertyFormSheet`) | Modal bottom sheet from both screens above | **Real**, reachable create/edit form — see DB-to-UI audit, §7 |
| `widgets/property_card.dart` (`PropertyCard`) | Grid item | Real; correct `context.push` navigation; decorative thumbnail is a hardcoded Unsplash stock-photo URL identical for every property (not a business-data violation, just non-representative imagery) |
| `widgets/property_map_card.dart` (`PropertyMapCard`) | Hub screen | Real `GoogleMap` with live markers built from `propertiesAsync`, correct navigation on tap |
| `widgets/property_hero_header.dart` (`PropertyHeroHeader`) | Details screen header | Real data display; same hardcoded stock photo as `PropertyCard` |
| `widgets/property_operations_tab.dart` (`PropertyOperationsTab`) | Tab 1 | Real live `occupancy`/`capacity` card; **"Linked Incidents"/"Active Permits" sections are fully fake** — hardcoded `'3 items linked to "$location"'` text regardless of actual data, no query against `incidents`/`permits` at all; "View Details" only shows a toast |
| `widgets/property_facility_tab.dart` (`PropertyFacilityTab`) | Tab 2 | Real streams: `propertyProjectsProvider`, `propertyAppointmentsProvider`. Read-only — no create action for either `PropertyProject` or `LegalAppointment` anywhere in the module |
| `widgets/property_assets_tab.dart` (`PropertyAssetsTab`) | Tab 3 | Real stream: `propertyAssetsProvider`. Read-only — no create action for `AssetInfo` anywhere in the module |
| `widgets/property_leases_tab.dart` (`PropertyLeasesTab`) | Tab 4 | Real stream: `propertyLeasesProvider`. Read-only — no create action for `LeaseInfo` anywhere |
| `widgets/property_esg_tab.dart` (`PropertyEsgTab`) | Tab 5 | Real stream: `propertyUtilitiesProvider`, rendered as `fl_chart` line charts. Read-only — no create action for `UtilityUsage` anywhere |

Net effect: `Property` itself has full, reachable create/edit CRUD. Its five child concepts (`PropertyProject`, `LegalAppointment`, `AssetInfo`, `LeaseInfo`, `UtilityUsage`) are all real live Firestore reads with **zero write paths anywhere in the app** — these sub-collections can only ever be populated out-of-band (seed data / console), never through the UI that displays them.

## 5. Backend & Database

**Models — `lib/features/property/models/property_models.dart`:**
| Model | Key fields | Collection |
|---|---|---|
| `Property` | name, type, address, lat, lng, totalArea, floors, occupancy, capacity, status, constructionDate, managerId, complianceScore, totalAssets | `properties` |
| `PropertyProject` | propertyId, title, type, description, status, assigneeId, dueDate, progress | `property_projects` |
| `UtilityUsage` | propertyId, month, electricity, water, waste, carbon | `property_utilities` |
| `LegalAppointment` | propertyId, role, personId, status, expiry? | `legal_appointments` |
| `LeaseInfo` | propertyId, tenantId, monthlyRent, startDate, endDate, status | `property_leases` |
| `AssetInfo` | propertyId, name, category, condition, lastInspected | `property_assets` |

All 6 collections live at `tenants/{tenantId}/{collection}` via the shared `TenantFirestore.tenantCollection()` extension (`lib/core/utils/tenant_firestore_extension.dart`), consistent with `firestore.rules`' `tenants/{tenantId}/...` structure.

**`siteId` filter note, same pattern `emergency.md` flagged:** `propertiesProvider` queries `.tenantCollection(tenantId, 'properties').where('siteId', isEqualTo: siteId)` where `siteId` is itself `currentTenantIdProvider` — and `PropertyFormSheet._submit()` writes `'siteId': tenantId`. Since the collection is already tenant-scoped by path, this where-clause is a redundant always-true filter, not genuine multi-site discrimination — identical in shape to `emergency.md`'s finding for `emergency_drills`/`emergency_equipment`.

**Firestore rules check — none of this module's 6 collections are declared in `firestore.rules`** (confirmed by grep: no match for `properties`, `property_projects`, `property_utilities`, `legal_appointments`, `property_leases`, or `property_assets`). All fall to the tenant-scoped catch-all (`allow write: if false`). **Unlike `supply_chain`'s equivalent finding, this one is a live, practical blocker**: `PropertyFormSheet` — a fully reachable, correctly-wired "Add Property"/"Edit Property" form (§4) — would have every write rejected by the deployed rules as committed. A user clicking "Add Property" in the shipped app would hit a permission-denied error.

**Providers — `lib/features/property/providers/property_providers.dart`:** `propertiesProvider` (full-collection stream) plus 5 `.family<T, propertyId>` streams, one per sub-tab (`propertyProjectsProvider`, `propertyUtilitiesProvider`, `propertyAppointmentsProvider`, `propertyLeasesProvider`, `propertyAssetsProvider`) — all real-time `snapshots()`-backed, consistent with AGENTS.md §2's real-time-first rule. No `StateProvider`/one-shot-fetch anti-pattern found here, unlike `crm.md`'s findings.

**Services:** none — no dedicated service class; `PropertyFormSheet` writes directly via `firestore.tenantCollection(...)` inline, and all providers query directly rather than going through a service layer. A lighter-weight pattern than `people`/`supply_chain`'s dedicated `*_service.dart` files, though still schema-typed via `fromFirestore` factories.

**Cloud Functions:** none found relevant — grepped both Functions codebases for "property"/"Property", no matches tied to this module's collections.

## 6. Cross-Module Links
- **Zero inbound references from other modules**: grepped the entire `lib/` tree for `features/property` imports outside the module itself — only `lib/config/router.dart` (standard route registration) references it. No other module (`equipment`, `contractors`, `supply_chain`, `safety`) imports anything from `property`, despite the narrative BPF module-list co-membership with `supply_chain`/`equipment`/`contractors` (§3).
- **`AssetInfo`/`property_assets` vs. `supply_chain`'s `Asset`/`assets` vs. `equipment`'s `EquipmentModel`/`equipment`**: three structurally separate "asset" concepts exist across three of this doc's four modules, none sharing a model class or collection. This module's `AssetInfo` is the simplest of the three (name/category/condition/lastInspected only) and is scoped per-property, read-only, and never populated by any write path (§4/§5).
- **AppEventBus:** zero usage anywhere in `lib/features/property/` (confirmed by grep).
- No relationship found with `safety`'s `incidents`/`permits` beyond the fake hardcoded text in `PropertyOperationsTab` (§4) — that tab names both collections but queries neither.

## 7. Known Gaps

### Rules-vs-code gaps
- All 6 of this module's collections (`properties`, `property_projects`, `property_utilities`, `legal_appointments`, `property_leases`, `property_assets`) are undeclared in `firestore.rules`, falling to the catch-all's `allow write: if false` — and unlike several of this session's other findings, this one **does** block a real, reachable, correctly-built form (`PropertyFormSheet`) — see §5.
- `BaseIncident` — not applicable, no incident concept in this module (the "Linked Incidents" panel is decorative/fake, not a real incident reference — §4).

### DB-to-UI alignment audit
`property_form_sheet.dart` vs `Property` (the module's only create/edit form, per this doc's brief):
| Field | Status | Note |
|---|---|---|
| `constructionDate` | **Missing** | Tracked in form state (`_constructionDate`, initialized to the existing value or `DateTime.now()`) but **no UI control renders it anywhere in the form** — no `ListTile`/`showDatePicker` exists for it, unlike the properly-implemented date pickers in `supply_chain`'s own forms. A new property silently gets today's date with no way to set anything else; an edited property can never have this field changed |
| `managerId` | Correct | Uses `EmployeeSelector`, a proper lookup |
| `status` | **Wrong widget** | Plain `TextFormField` despite downstream code (`PropertyCard`, `PropertyHeroHeader`) treating it as a closed set of known values (`'Optimal'`, strings `.contains('Critical')`) for status-color logic — free text risks values the rest of the UI can't classify |
| `complianceScore` / `totalAssets` | **Wrong widget (architectural)** | Both are plain free-text numeric fields a human types in directly, despite the model's own inline comment marking them `// Added for traceability` — i.e., they read as values meant to be derived (e.g. `totalAssets` from a live count of `property_assets` docs, which the same app already streams via `propertyAssetsProvider` in `PropertyAssetsTab`) rather than manually entered. As built, nothing keeps a manually-typed `totalAssets` in sync with the actual linked-assets count shown one tab over |

### Other
- **Five child sub-collections have real read UIs but zero write UIs anywhere** (`PropertyProject`, `LegalAppointment`, `AssetInfo`, `LeaseInfo`, `UtilityUsage`) — see §4. All five tabs will show an empty state for any tenant that hasn't had this data seeded out-of-band.
- **`PropertyOperationsTab`'s "Linked Incidents"/"Active Permits" panels are hardcoded fake data** (`'3 items linked...'` regardless of reality) — AGENTS.md §2 violation, and its "View Details" button is a `UIUtils.showToast`-only no-op rather than a real deep link into `safety`.
- **`showModalBottomSheet` used directly instead of `UIUtils.showSideSheet`** for both Add and Edit — AGENTS.md §1 violation, confirmed against the actual `showSideSheet` implementation (§4).
- Two `UIUtils.showToast`-only no-op buttons ("View All," share icon) — at least correctly using the mandated toast utility (unlike several of this session's other modules), but still non-functional actions.
- **IA/taxonomy conflict**: see [shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved).

## 8. Open Questions
- Should `properties` and its 5 child collections be added to `firestore.rules` explicitly, given `PropertyFormSheet` is a real, reachable form whose writes are currently rejected as deployed?
- Is the missing `constructionDate` date-picker an oversight, or was this field intentionally frozen to creation-time only (in which case it shouldn't be a form-state variable at all)?
- Should `totalAssets`/`complianceScore` become computed values (e.g. a Cloud Function trigger recalculating from `property_assets`) rather than free-text manual entry, given the model's own "Added for traceability" comment implies derivation?
- Is there a planned write path (bulk import, a future admin screen, a Cloud Function) for `PropertyProject`/`LegalAppointment`/`AssetInfo`/`LeaseInfo`/`UtilityUsage`, or are these five tabs aspirational display-only scaffolding ahead of their own CRUD?
- Should `PropertyOperationsTab`'s incident/permit panels be wired to real `safety` queries, given the collections it names (`incidents`, `permits`) already exist and are declared in `firestore.rules`?
