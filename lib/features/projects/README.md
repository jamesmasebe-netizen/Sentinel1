# Projects Module Manifest

## Purpose
The Projects module handles the entire lifecycle of capital projects, construction jobs, and operational task forces. It tracks tasks, costs, milestones, and links out to Safety (Permit to Work, Incidents) and Risk (HIRA) elements.

## Architecture
- **State Management:** Riverpod (`project_providers.dart`)
- **Data Model:** `Project`, `ProjectTask`, `ProjectExpense` (`project_models.dart`)
- **Key Screens:**
  - `project_dashboard_screen.dart` (List of projects, high-level metrics)
  - `project_details_screen.dart` (Deep dive into a single project)
    - **Note:** This screen is extremely large. Avoid reading the whole file. Instead, view specific widgets within `lib/features/projects/widgets/` (such as `custom_gantt_chart.dart`).

## Token Optimization Guidelines
- **DO NOT** rewrite entire screens when making small UI tweaks. Use chunk replacements.
- If adding a new tab to `project_details_screen.dart`, create a new widget in `widgets/` and just wire it in.
- Assume global UI components (Cards, Headers, Tags) live in `lib/core/widgets/ds_widgets.dart`. Do not redefine them locally.
