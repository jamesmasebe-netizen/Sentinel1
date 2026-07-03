# People & HR Module Manifest

## Purpose
The People module manages human capital for the enterprise. It tracks employee profiles, certifications, job roles, and acts as the central truth for user identities. Other modules (Risk, Projects, Operations) deeply link into this module when assigning tasks or identifying personnel.

## Architecture
- **State Management:** Riverpod (`employee_providers.dart`)
- **Data Model:** `Employee`, `JobRole` (`employee.dart`)
- **Key Widgets:**
  - `EmployeeSelector` (`widgets/employee_selector.dart`) - **CRITICAL:** Use this type-ahead widget anywhere an employee name/ID is required. Never use a basic `TextFormField` for people.
- **Key Screens:**
  - `people_hub_screen.dart` (HR Dashboard)
  - `employee_profiles_screen.dart` (List of all personnel)
  - `employee_360_profile_screen.dart` (Deep dive into a single employee)

## Token Optimization Guidelines
- When adding fields to an Employee profile, ensure you update `employee.dart`'s `fromMap` and `toMap` methods.
- If you refactor `EmployeeSelector` to support a new parameter, use the `auto-sync-refactor` skill to spawn a subagent that updates all occurrences of `EmployeeSelector` across the codebase (e.g., in the Training module).
- Maintain files under 300 lines. If a screen gets too complex, extract tabs into `widgets/`.
