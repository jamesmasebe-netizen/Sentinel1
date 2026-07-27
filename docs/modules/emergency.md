# emergency — Module Journey Doc

**Path:** `lib/features/emergency/`  |  **Compartment:** Field Service  |  **README.md exists:** no
**Last verified against:** 2026-07-27

## 1. Product Understanding
`emergency` is a single 4-tab screen (`EmergencyResponseScreen`: Drills, Equipment, Contacts, Broadcast) implementing the Field Service & Emergency Responder persona's "Emergency Preparedness" journey. Two tabs are real Firestore CRUD (Drills, Equipment); two are non-functional (Contacts is fully static, Broadcast is a stub — see §5).

**In scope:** logging emergency drills, tracking emergency equipment (extinguishers, first aid kits, AEDs, spill kits), a static emergency-contacts reference list, a broadcast-tab UI shell.
**Out of scope:** actually sending a broadcast (a real Cloud Function + Dart wrapper exist elsewhere in the codebase, unused here — see §5), incident reporting itself (`safety`/`risk`), technician dispatch (`field_service`).
**IA placement:** Field Service compartment (8-compartment taxonomy) per this doc set. Notably, `business_os_launchpad.dart`'s own tile grid groups the "Emergency" tile under a section header labeled **"Customer Engagement"**, alongside CRM/Customer Service/Field Service — a fourth, ad hoc grouping that doesn't match any of the three IA narratives the [shared doc](_shared_personas_and_bpfs.md#ia-taxonomy-note-unresolved-conflict--documented-not-resolved) already flags as unresolved, adding one more concrete data point to that conflict rather than a new one.

## 2. User Journeys
| Persona | Journey | Steps touching `emergency` | Entry screen(s) |
|---|---|---|---|
| [Field Service & Emergency Responder](_shared_personas_and_bpfs.md#persona-field-service-responder) (primary) | Emergency Preparedness: Log Emergency Drill → Inspect Emergency Equipment | `EmergencyDrillsTab` (create + list) → `EmergencyEquipmentTab` (create + list) | `emergency_response_screen.dart` |
| Security/Gate Access Personnel, HR & Safety Officer (secondary, per module assignment) | — | No code hook found, and no journey step in either persona's [shared-doc](_shared_personas_and_bpfs.md) entry names drills/equipment/broadcast specifically — their relevance here is domain-adjacency (site access, safety oversight), not a confirmed journey-text link | — |

Reachability: `/emergency` is a top-level `GoRoute` (`router.dart:209-212`) linked directly from `BusinessOsLaunchpad`'s "Emergency" tile. It is *not* reached via `field_service_hub_screen.dart`'s "Emergency Response" card — that card is a dead `destination: null` placeholder (confirmed in `field_service.md` §4) even though this module's real route exists independently.

## 3. BPF Participation
| BPF | Stage(s) this module implements | Code reference |
|---|---|---|
| [Issue to Resolution](_shared_personas_and_bpfs.md#bpf-issue-to-resolution) | Narrative module-list entry only | Confirmed directly: `issue_to_resolution_bpf.dart`'s 4 stages (`logged`/`investigation`/`capa`/`closure`) are tagged only `expectedRecordType: 'incident'`/`'capa'`; zero references to "emergency" anywhere in `lib/core/bpf/` (repo-wide grep) |
| [Asset Lifecycle](_shared_personas_and_bpfs.md#bpf-asset-lifecycle) | Narrative flow step only — "Emergency Management (if asset fails critically, trigger Emergency Drill/Response protocol)" | Confirmed directly: no code-level hook. `asset_lifecycle_bpf.dart`'s 4 stages (`acquisition`/`deployment`/`maintenance`/`decommissioning`) are tagged only `expectedRecordType: 'equipment'` — none is an "Emergency Management" stage, and this BPF's own "Modules" list in the shared doc (`equipment, property, supply_chain, field_service`) doesn't even name `emergency` explicitly, despite the flow prose naming an emergency step. So this module's participation is narrative-only at two removes: named in flow text but absent from both the BPF's module list and its code |

As predicted going in: **no code-level hook exists for either BPF** — confirmed by direct grep, stated plainly. `BpfRibbonWidget` usage: confirmed **absent** from `lib/features/emergency/`.

## 4. Screens & UI Elements Inventory
| Screen/widget | Route or entry point | Purpose / wiring |
|---|---|---|
| `emergency_response_screen.dart` (`EmergencyResponseScreen`) | `/emergency` (top-level route, `router.dart:209-212`) | 4-tab shell (`TabController`): Drills / Equipment / Contacts / Broadcast |
| `widgets/emergency_drills_tab.dart` | Tab 1 | **Real:** `StreamBuilder<QuerySnapshot>` built directly inside the widget's `build()` method (not a Riverpod provider — see §5/§7) against `tenants/{tenantId}/emergency_drills`, filtered `siteId == tenantId`, ordered `createdAt` desc, limit 50 |
| `widgets/drill_form_card.dart` (`DrillFormCard`) | Inline toggle within Drills tab | **Real:** writes to `emergency_drills` via `firestoreServiceProvider.createDocument`; only `scenarioDescription` is required |
| `widgets/drill_list_item.dart` (`DrillListItem`) | Inline within Drills tab | **Real:** renders one raw `Map<String, dynamic>` drill doc — no Dart model class exists (see §5) |
| `widgets/emergency_equipment_tab.dart` | Tab 2 | Same pattern as Drills tab, targets `emergency_equipment`, limit 100 |
| `widgets/equipment_form_card.dart` (`EquipmentFormCard`) | Inline toggle within Equipment tab | **Real:** writes to `emergency_equipment`; only `location` is required |
| `widgets/equipment_list_item.dart` (`EquipmentListItem`) | Inline within Equipment tab | **Real:** renders raw `Map`; status-driven color chip (Operational/Needs Inspection/Out of Service) |
| `widgets/emergency_contacts_tab.dart` | Tab 3 | **Fully static:** 6 hardcoded `_ContactCard` entries (Fire/Ambulance/Police/Poison/SHE Manager/Environmental Officer) with hardcoded numbers; the phone icon button only shows a `'Dialing $number...'` toast — no real `tel:` intent, despite `url_launcher` already being a dependency used elsewhere in this same app (`billing_service.dart`) |
| `widgets/emergency_broadcast_tab.dart` | Tab 4 | **Stub:** "Initialize Test Broadcast" button only calls `UIUtils.showToast(... 'Broadcast system initialized. Configure in FCM.')` — no Cloud Function call, despite one existing and being ready to use (see §5) |

## 5. Backend & Database

**No `models/`, `services/`, or `providers/` subdirectory exists in this module.** Both live tabs issue their `StreamBuilder<QuerySnapshot>` Firestore queries directly inside the widget `build()` method (against core providers `firestoreProvider`/`currentTenantIdProvider`), and both list items render raw `Map<String, dynamic>` with no `fromFirestore`/`toFirestore` model class anywhere. This is a more thorough AGENTS.md §1 ("Predictable Separation of Concerns") and §2 ("Strict Schema Enforcement") violation than either `field_service.md` or `finance.md` found in their own modules — both of those at least have a models/services/providers layer, even where parts of it are dead code.

**Collections** (both tenant-scoped subcollections, written via `tenantCollection(tenantId, ...)` → `tenants/{tenantId}/...`):
- `emergency_drills` — `drillType` (Fire/Medical/Spill/Security/Evacuation/Other), `dateConducted` (free-text string), `durationMinutes` (int), `evaluatorName`, `scenarioDescription` (required), `areasForImprovement`, `authorId`, `siteId`, `createdAt` (ISO string, not a `Timestamp`)
- `emergency_equipment` — `equipmentType` (Extinguisher/First Aid Kit/Spill Kit/AED/Other), `location` (required), `nextInspectionDate` (free-text string), `status` (Operational/Needs Inspection/Out of Service), `authorId`, `siteId`, `createdAt` (ISO string)

**`siteId` note:** both forms set `'siteId': p.tenantId` — the user's own tenant ID, not a distinct site identifier — and both tabs filter `.where('siteId', isEqualTo: tenantId)`. Since the collection is already scoped to `tenants/{tenantId}/...`, this filter is a redundant no-op (always true), not genuine multi-site discrimination.

**Firestore rules check:** neither `emergency_drills` nor `emergency_equipment` is declared in `firestore.rules` (confirmed — no match for "emergency" anywhere in the file). Both fall through to the tenant-scoped catch-all (`match /{collection}/{docId}` nested inside `match /tenants/{tenantId}`, `firestore.rules:220-223`), which sets `allow write: if false`. Net effect: **`DrillFormCard`'s and `EquipmentFormCard`'s submit methods — this module's only two write paths — would both be rejected by the deployed rules as committed.** Worth stating precisely because `equipment` itself *is* declared in `firestore.rules` (line 75-79, "managers can CRUD") — but that's a different collection, presumably owned by `supply_chain`/`property`, not this module's `emergency_equipment`; naming similarity doesn't extend to rule coverage.

**Cloud Functions:** `sendEmergencyBroadcast` (`firebase/functions/src/index.ts:228-253`, `onCall`, region `europe-west1`) is a real, non-stub implementation — sends an FCM push to topic `site-{siteId}` (high-priority Android/APNs config) and writes an audit doc to `emergency_broadcasts` (`siteId`, `message`, `emergencyType`, `sentBy`, `sentAt`, `recipientTopic`). A matching Dart-side wrapper already exists too: `NotificationService.sendEmergencyBroadcast({siteId, message, emergencyType})` in `lib/core/services/notification_service.dart:144-154` (outside this module), which correctly calls `httpsCallable('sendEmergencyBroadcast')`. **But grep confirms zero call sites for that Dart method anywhere in `lib/`** — including from this module's own `emergency_broadcast_tab.dart`, exactly where it's expected. A fully real, two-sided (Cloud Function + Dart wrapper) capability sits unused. `emergency_broadcasts` is also undeclared in `firestore.rules` and has zero read-side references anywhere in `lib/` — no broadcast-history view exists.

## 6. Cross-Module Links
- `field_service_hub_screen.dart`'s "Emergency Response" card is a dead `destination: null` placeholder (per `field_service.md` §4) even though this module's real `/emergency` route exists and is independently reachable from the launchpad — the two Field-Service-compartment modules don't actually link to each other.
- `NotificationService.sendEmergencyBroadcast()` (`lib/core/services/`, outside this module) is the ready-made integration point described in §5 — a real but currently unused cross-module dependency this module could call into.
- **AppEventBus:** zero usage anywhere in `lib/features/emergency/` (confirmed by grep) — no event fires when a drill is logged or equipment status changes, and this module doesn't listen for anything either.
- No code relationship found with `safety`/`risk` (Issue to Resolution's other narrative modules) — confirmed by the BPF grep in §3.

## 7. Known Gaps

### Rules-vs-code gaps
- `emergency_drills` and `emergency_equipment` are undeclared in `firestore.rules` and fall to the tenant-scoped catch-all's `allow write: if false` — both of this module's create flows would be rejected as deployed (full detail in §5).
- `BaseIncident` (AGENTS.md §5) is not implemented anywhere in the codebase (per the [shared doc](_shared_personas_and_bpfs.md#related-rules-vs-code-gap-applicable-wherever-relevant-below)). Checked directly for this module: `emergency`'s own data (drills, equipment) does **not** conceptually represent an incident — these are preparedness/inventory records, not incident reports — so `BaseIncident`'s absence is not itself a gap for this module's models, unlike `safety`/`health`/`workers_comp`/`field_service`. Stated plainly to close out the check, not left implicit.

### DB-to-UI alignment audit
No Dart model class exists for either collection (see §5), so the standard model-vs-form methodology doesn't directly apply — there's no model to diff a form against. Auditing the two forms' own field choices instead:
| Field | Status | Note |
|---|---|---|
| `dateConducted` (`drill_form_card.dart`) | **Wrong widget** | Free-text `TextEditingController`, no `DatePicker`, no hint text at all |
| `nextInspectionDate` (`equipment_form_card.dart`) | **Wrong widget** | Free-text field with a `YYYY-MM-DD` hint but no `DatePicker` or format validation |
| `createdAt` | Correct (acceptable) | Both forms write `DateTime.now().toIso8601String()` at submit time — consistent, if not a `Timestamp` |

### Other
- No models/services/providers layer for this module at all — direct Firestore `StreamBuilder` queries inside widget `build()` methods, raw `Map` rendering, no serialization layer (see §5).
- `emergency_contacts_tab.dart` is entirely hardcoded static data (AGENTS.md §2 "No Hardcoded Data") and its "call" buttons don't actually dial (AGENTS.md §3 banned-stub pattern).
- `emergency_broadcast_tab.dart`'s single button is a banned-stub in the most literal sense found in either of this session's two modules: a real Cloud Function *and* a real Dart service wrapper both already exist correctly implemented, and the UI simply doesn't call them (see §5).
- `siteId` is populated with the tenant ID rather than a distinct site identifier, making the `.where('siteId', ...)` filter both tabs run a redundant no-op (see §5).

## 8. Open Questions
- Was `emergency_broadcast_tab.dart` ever wired to `NotificationService.sendEmergencyBroadcast()` and later reverted, or was the Cloud Function/Dart wrapper built ahead of the UI and never connected? The identical method name on both sides suggests intent to connect them.
- Should `emergency_drills`/`emergency_equipment` be added to `firestore.rules` explicitly (parallel to the already-declared `equipment`), or does this need the broader rules pass `finance.md`/`field_service.md` both separately call for?
- Is a genuine multi-site concept (distinct from `tenantId`) planned for `siteId`, given the field exists but is currently populated with the tenant ID?
- Should this module gain a models/services/providers layer to match the rest of the app's structure, or is its small size (9 files, 2 simple collections) acceptable as-is?
