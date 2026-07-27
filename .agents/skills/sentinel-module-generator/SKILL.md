---
name: sentinel-module-generator
description: Use this skill to rapidly scaffold new features or "Hubs" in the Sentinel application (e.g., Asset Management Hub, Environmental Compliance Hub) perfectly adhering to the established Riverpod and deep-linking architecture.
---

# Sentinel Module Generator Skill

When instructed to create a new module or feature hub for Sentinel, use this skill to generate the codebase efficiently and precisely. Do NOT guess the architecture; follow these exact specifications.

## 0. Design & Planning
Before generating any code, you MUST use the `write_to_file` tool to create a `module_design.md` artifact detailing the feature. 
Set `RequestFeedback: true` in the ArtifactMetadata to ensure the user reviews the data layer, UI components, and Riverpod structure before the heavy scaffolding begins.

*Optional but Recommended:* Use the `sentinel-swarm-orchestrator` skill to delegate the coding phase to specialized subagents (e.g., UI vs. Data) once the design is approved by the user.

## 1. Directory Structure
Create a new folder in `lib/features/<module_name>/`.
Inside it, create:
- `models/`
- `providers/`
- `screens/`
- `widgets/`

## 2. Real-Time Providers
Create a `<module_name>_providers.dart` file.
1. Define a `StreamProvider` that listens to the relevant Firestore collection.
2. Define derived state providers (e.g., counters, filtered lists) that `.watch` the main `StreamProvider`.
**DO NOT use FutureProviders or one-off fetches for list views or dashboards.**

## 3. Hub Screen Template
Create a `<module_name>_hub_screen.dart` file.
- Use a `Scaffold` with an `AppBar` (matching the app's aesthetic).
- Use `ref.watch(mainStreamProvider)` to build the body.
- Handle loading and error states explicitly using the `.when()` pattern.
- Include a dashboard section (KPI cards) derived from the real-time data at the top.
- Include a `ListView` or `GridView` below the dashboard.

## 4. Deep-Linking Constructor
Every Hub Screen and detailed feature screen MUST accept an optional parameter for deep-linking.
```dart
class MyNewHubScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? highlightId;

  const MyNewHubScreen({super.key, this.initialSearch, this.highlightId});
  // ...
}
```
In `initState`, use these parameters to pre-fill search bars or automatically open specific details using `UIUtils.showSideSheet`.

## 5. Navigation Rule
- Do NOT use `Navigator.push`.
- Use `UIUtils.showSideSheet(context: context, title: 'Details', builder: (ctx) => DetailScreen());` when tapping list items.
