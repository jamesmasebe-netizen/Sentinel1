import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final geminiProvider = Provider<GenerativeModel>((ref) {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  return GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
});
