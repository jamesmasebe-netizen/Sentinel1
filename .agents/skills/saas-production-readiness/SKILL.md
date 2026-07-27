---
name: saas-production-readiness
description: Rules for ensuring Sentinel is a production-grade, enterprise SaaS platform. Covers environment management, analytics, error tracking, and strict typing.
---

# SaaS Production Readiness Skill

When developing core infrastructure or finalizing a feature for deployment, you MUST adhere to these enterprise-grade standards. Sentinel must be robust, observable, and strictly typed.

## 1. Environment Flavors
- Never hardcode production database URLs or API keys.
- Ensure the app uses `--dart-define` or `.env` files (via `flutter_dotenv`) for environment variables (e.g., `DEV`, `STAGING`, `PROD`).
- Firestore security rules should be tested against a local Firebase Emulator or a dedicated DEV project before touching PROD.

## 2. Observability & Error Tracking (Crashlytics)
- **Silent Failures are Unacceptable.** Any caught exception in a `try-catch` block (e.g., in a CRUD operation or API call) MUST be logged to Firebase Crashlytics.
- Use `FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: '...')`.
- Ensure `FlutterError.onError` is routed to Crashlytics in `main.dart`.
- Log critical user journeys using Firebase Analytics (e.g., `FirebaseAnalytics.instance.logEvent(name: 'capa_created')`).

## 3. Riverpod Strict Typing & Immutability
- All models MUST be immutable, using `@freezed` or standard `final` fields with a `copyWith` method.
- Never mutate a list inside a Riverpod state directly. Always return a new instance (e.g., `state = [...state, newItem]`).
- Enable strong mode in `analysis_options.yaml` (strict-casts, strict-inference, strict-raw-types) and resolve all warnings.

## 4. Feature Flags
- New, experimental features should be wrapped in Firebase Remote Config feature flags to allow safe rollout and instant kill-switches without App Store updates.

## 5. Offline Support
- For a B2B SaaS, users might be in remote locations (e.g., factory floors). Ensure Firestore offline persistence is enabled.
- Design UIs to gracefully indicate when the user is offline (e.g., an offline banner) while still allowing them to view cached data.
