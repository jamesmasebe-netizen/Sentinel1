# Global Project Rules: Production-Grade Engineering Only

## 1. Architectural Granularity & Data Modeling (Firestore)
- **Zero Flat Schemes:** Do not compress unrelated datasets into single catch-all Firestore documents. Data models must be granular, highly typed, and strictly normalized. For example, risk assessments, hazard identification logs, and non-conformance reports must be separate subcollections, not flat arrays within a main document.
- **Strict Schema Enforcement:** Every collection must have a corresponding, type-safe Dart model class with clear fromFirestore and toFirestore serialization logic.

## 2. UI Component Architecture (Flutter)
- **Micro-Widget Separation:** Massive layout files are prohibited. Break screens down into small, single-purpose, stateless or stateful widgets.
- **Predictable Separation of Concerns:** Keep UI files strictly visual. Business logic and direct Firestore query streams must reside entirely within the State Management Layer.

## 3. Mandatory Completeness & Execution
- **Banned Stubs:** Never use `// TODO`, unconfigured `onPressed` callbacks, or static text strings representing "coming soon" states.
- **End-to-End Vertical Slices:** Every requested feature must be built fully functional. If a button is added (e.g., submitting an incident report), its complete data routing, state mutations, and backend schema transformations must be written entirely.
- **Resilient States:** Every network call or database query must handle three explicit states: Data/Success, Empty (no items found view), and Error (explicit error message).

## 4. Self-Improving Architecture & Cross-Module Communication
- **Global Event Bus (Riverpod):** Modules must communicate via the central `AppEventBus` rather than direct hardcoded dependencies. When a state change in one module affects another (e.g. Employee Terminated -> Safety Clearances Revoked), broadcast it via the bus.
- **Agentic Refactoring Loops:** Whenever an AI Agent (you) modifies a core data model, provider, or structural pattern, you MUST automatically search the codebase for all dependent modules and update them to match the new schema.
- **Polymorphism for Shared Concepts:** Use base classes for shared entity types (e.g., `BaseIncident` for Safety and Environmental incidents) so that enhancements to the core automatically benefit all domains.
