---
name: sentinel-deep-link-enforcer
description: Use this skill to ensure complex cross-module routing (e.g., Incident -> CAPA -> Employee) adheres to Sentinel's deep-linking and side-sheet standards.
---

# Sentinel Deep-Link Enforcer

Sentinel requires deep interconnectedness similar to Safety360. When establishing links between disparate modules, follow these rules:

## 1. Top-Level Screen Parameters
All top-level screens (e.g., `EmployeeProfilesScreen`, `IncidentsRegisterScreen`) MUST accept parameters that allow them to be pre-filtered or pre-opened.
```dart
  final String? initialSearch;
  final String? highlightId;
```

## 2. Auto-Navigation in `initState`
If a `highlightId` is passed, the screen must automatically open the detailed side-sheet for that entity without the user clicking anything. Use `WidgetsBinding.instance.addPostFrameCallback` in `initState` to safely trigger `UIUtils.showSideSheet`.

## 3. Pre-filling Search
If `initialSearch` is passed, set the search `TextEditingController.text` to this value and immediately execute the filtering logic.

## 4. Launching from Other Modules
When Module A (e.g., Action Tracker) needs to link to Module B (e.g., CAPA Details), do NOT build Module B's detail view inside Module A. Instead, launch Module B's top-level screen using `UIUtils.showSideSheet` and pass the specific ID.
```dart
// Inside ActionTrackerScreen
UIUtils.showSideSheet(
  context: context,
  title: 'CAPA Module',
  builder: (ctx) => CapaScreen(highlightId: action.sourceId),
);
```
