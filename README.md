# Sentinel1 — Enterprise SHEQ Platform

**Sentinel1** is a comprehensive Safety, Health, Environment, and Quality (SHEQ) management platform built with Flutter and Firebase. It provides a unified, Material 3 Expressive interface for managing workplace safety, risk assessment, people & health, and operational assets.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Dart) — Web, iOS, Android |
| **Backend** | Firebase Cloud Functions (TypeScript) |
| **Database** | Cloud Firestore |
| **Auth** | Firebase Authentication |
| **Storage** | Firebase Cloud Storage |
| **AI** | Google Gemini API |
| **Notifications** | Firebase Cloud Messaging (FCM) |

## Architecture

The app follows a **4-Hub Command Center** architecture:

1. **Home** — Executive dashboard with cross-functional KPIs
2. **Safety & Risk** — Incidents, permits, hazards, CAPA, risk registers, BBS
3. **People & Health** — Employee profiles, training, skills matrix, occupational health, worker's comp
4. **Operations & Assets** — Action tracker, property portfolio, environmental, contractors

All module drill-downs use **in-place side-sheets** (Google Workspace pattern) to maintain context while exploring data.

## Getting Started

### Prerequisites
- Flutter SDK (3.x+)
- Firebase CLI
- Node.js 20+ (for Cloud Functions)

### Run Locally
```bash
flutter pub get
flutter run -d chrome   # Web
flutter run              # Mobile
```

### Deploy Cloud Functions
```bash
cd firebase/functions
npm install
npm run deploy
```

## Project Structure
```
lib/
├── config/          # Theme, router, Firebase options
├── core/            # Shared widgets, providers, services, utils
└── features/        # Feature modules (safety, people, operations, etc.)
firebase/
└── functions/       # Cloud Functions (email, FCM, scheduled jobs)
```

## License
Proprietary — All rights reserved.
