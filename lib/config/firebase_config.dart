/// Firebase configuration for XM System
///
/// Real Firebase initialization does not go through this class — it reads
/// FIREBASE_API_KEY etc. from the git-ignored .env at startup (main.dart),
/// and Gemini reads GEMINI_API_KEY via --dart-define (see F-513 in
/// docs/fixes/FIX_LIST.md). This class previously also held hardcoded
/// Firebase/Gemini API keys that nothing actually read — removed per F-502.
class FirebaseConfig {
  static const String appId = '1:458780078401:web:725f6b7eafdab38f50b1c0';

  // Default site for new users
  static const String defaultSiteId = 'LDN-01';
}
