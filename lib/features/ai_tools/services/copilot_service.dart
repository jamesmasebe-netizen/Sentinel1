import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../providers/gemini_provider.dart';

class CopilotService {
  final GenerativeModel _model;
  final String tenantId;

  CopilotService({required GenerativeModel model, required this.tenantId})
    : _model = model;

  Future<String> askCopilot(String prompt, String context) async {
    final systemPrompt =
        'You are a Copilot assistant for the $context domain.\n'
        'Tenant ID: $tenantId\n'
        'Provide helpful, accurate, and concise answers focusing on the $context context.';

    final content = [Content.text('$systemPrompt\n\nUser Query: $prompt')];

    try {
      final response = await _model.generateContent(content);
      return response.text ?? 'No response generated.';
    } catch (e) {
      return 'Error: $e';
    }
  }
}

final copilotServiceProvider = Provider.family<CopilotService, String>((
  ref,
  tenantId,
) {
  final model = ref.watch(geminiProvider);
  return CopilotService(model: model, tenantId: tenantId);
});
