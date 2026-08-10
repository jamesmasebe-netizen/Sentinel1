# Needs Your Input

A live tracker — not a snapshot — for the one category of thing that keeps getting lost inside dated changelog entries: items where an agent genuinely cannot make the call, because it requires your account access, your money, or your product judgment. Everything else (engineering backlog an agent can pick up and decide unilaterally) lives in `docs/OUTSTANDING_WORK.md` instead — if you're wondering "why isn't X here," it's probably because X doesn't actually need you specifically.

**Maintenance contract, for whoever (human or agent) touches this repo next:**
- Check an item off (`- [x]`) the moment it's resolved — don't leave it lingering because "the doc will get updated later." Move a one-line note of how it was resolved into the item itself rather than deleting the line outright, so there's a record.
- If you find a new item that requires the user specifically (not just careful reading of code), add it here immediately, in the right section, with the date and a pointer to more detail. Don't let it live only in a chat response or a `TEST_BACKLOG.md` paragraph — those get buried.
- Re-scan this file at the start of any new work session in this repo if it's been more than a few days — items above may have been resolved outside a coding session (e.g. a console setting toggled) without the file being updated to match. Verify before assuming stale entries are still open.
- Keep this file short enough to scan in under a minute. If a section grows past ~10 items, that's a signal to actually go resolve some, not to keep appending.

---

## Account & billing actions (nobody but you can do these)

- [ ] **Upgrade the Firebase project off the Spark (free) plan to Blaze.** Blocks every Cloud Functions deploy, including `syncUserClaims` — the trigger that assigns real role/tenant custom claims, which is why the only working login today is the anonymous dev-bypass account. Console: Firebase Console → your project → Usage and billing. *Raised: 2026-07-31, still open as of 2026-08-10.* Detail: `docs/testing/TEST_BACKLOG.md`'s deploy-blocker notes.
- [ ] **Add a `FIREBASE_SERVICE_ACCOUNT` GitHub Actions secret.** The manual-trigger CD pipeline (`.github/workflows/deploy.yml`, built 2026-08-10) can't run at all without it — this blocks even the Hosting/Firestore-rules-only steps, not just the Functions deploy. Generate via Firebase Console → Project Settings → Service Accounts → Generate new private key, then add it as a repo secret. *Raised: 2026-08-10.*
- [ ] **Enable Google as a Firebase Auth sign-in provider.** Firebase Console → Authentication → Sign-in method. Until this is on, there's no way to get a real, permanent, email-tied admin account — only the anonymous bypass. Once enabled, sign in once with your real Google account, then re-run `firebase/functions/scripts/grant_admin_claims.ts --apply` against the new UID. *Raised: 2026-07-31, still open as of 2026-08-10.*
- [ ] **Supply a real `GEMINI_API_KEY`.** The code path to read it from `.env` is fixed and correct, but no real key exists anywhere in the repo (only a placeholder in `.env.example`) — every AI Tools/Copilot feature currently fails or returns nothing. *Raised: 2026-08-10 (re-confirmed still empty during this pass).*

## Drafts awaiting your review

- [ ] **`docs/D365_PIVOT_ROADMAP.md`** — a from-scratch cross-reference of the two aspirational D365-pivot documents against what's actually built today, replacing their "15-agent rebuild everything" framing with a much smaller build-on-what-exists list. This is explicitly a draft — no prioritization, timeline, or starting pillar has been chosen. Needs you to pick a direction (or reject it) before any of it becomes real work. *Raised: 2026-08-10.*

## Product & naming decisions

These came out of re-reading all 28 per-module audit docs' own "Open Questions" sections (`docs/modules/*.md` §8) — a lot of them have been silently resolved by two weeks of engineering work since, but these genuinely haven't, and none of them are things an agent should just decide on your behalf.

- [ ] **Is the `dashboard`/`executive` split intentional, or should they be one module?** Partially pre-empted already — `DashboardScreen` now embeds `ControlTowerScreen` behind an Operational/Executive toggle (2026-08-10) — but that's UI-level, not a real module merge. Worth deciding whether that's the final shape or a half-step. *Raised: 2026-07-28 (`dashboard.md`/`executive.md`), partially addressed 2026-08-10.*
- [ ] **Is the 3-way split across `courses`/`enrollments`/`training_enrollments`/`training_records` intentional design (LMS content vs. manager assignment vs. compliance record, each meaningfully different) or accidental drift?** `TrainingService.getComprehensiveEmployeeRecord()` now queries all 3 and combines them at the service layer (2026-08-10), but each UI tab still surfaces only its own slice — the module doc's own text calls this "an open design question, not a bug." *Raised: 2026-07-28 (`training.md`), service-layer partial fix 2026-08-10.*
- [ ] **Should `health`'s `medical_records` and `training`'s `training_records` (with `type: 'medical_certificate'`) be unified, or are "fitness-for-duty exam" and "medical certificate on file" meant to be genuinely different records?** As it stands neither `safety` nor the Hire-to-Retire flow has visibility into whichever one isn't theirs. *Raised: 2026-07-28 (`health.md`).*
- [ ] **Should `supply_chain`'s `Asset`/`assets` (EAM) be merged with `equipment`'s `EquipmentModel`/`equipment`?** Both conceptually serve the `asset_lifecycle` BPF's `expectedRecordType: 'equipment'`, and neither is a clean fit alone. Directly relevant now that `AssetLifecycleScreen` (built 2026-08-10) gives the BPF a real fleet-wide UI for the first time. *Raised: 2026-07-28 (`supply_chain.md`), more relevant as of 2026-08-10.*
- [ ] **Is `isPremiumProvider`'s `'premium'` tier check a typo for `'pro'`, or was a third pricing tier once planned and never built?** This gates real feature access, not just copy — worth a definitive answer rather than leaving it ambiguous. *Raised: 2026-07-28 (`billing.md`).*
- [ ] **Should `compliance` (regulatory-document register) and `contractors`' AI compliance-prescreening feature be renamed to stop colliding on the word "compliance"?** They share no code, data, or screens — purely a naming/wayfinding question for anyone using the app. *Raised: 2026-07-28 (`compliance.md`).*
- [ ] **Is a genuine multi-site concept (distinct from `tenantId`) planned for `emergency`'s `siteId` field**, given it exists but is currently just populated with the tenant ID? Small now, but a real scoping decision if multi-site support is ever wanted. *Raised: 2026-07-28 (`emergency.md`).*

---

*Companion document: `docs/OUTSTANDING_WORK.md` for everything else still open that doesn't need you specifically.*
