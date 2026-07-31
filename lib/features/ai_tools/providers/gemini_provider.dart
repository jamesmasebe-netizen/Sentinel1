import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Sourced from the git-ignored .env, matching main.dart's existing
// flutter_dotenv pattern for Firebase config — not a --dart-define, which
// nothing in this repo's build/run tooling ever supplied. See F-513 in
// docs/fixes/FIX_LIST.md.
final geminiProvider = Provider<GenerativeModel>((ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  return GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
});
