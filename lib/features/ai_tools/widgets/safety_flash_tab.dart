import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../providers/gemini_provider.dart';

class SafetyFlashTab extends ConsumerStatefulWidget {
  const SafetyFlashTab({super.key});
  @override
  ConsumerState<SafetyFlashTab> createState() => _SafetyFlashState();
}

class _SafetyFlashState extends ConsumerState<SafetyFlashTab> {
  String _result = '';
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      final siteId = profile?.tenantId ?? 'this site';
      final model = ref.read(geminiProvider);
      final prompt =
          '''Generate a professional Weekly Safety Flash bulletin for $siteId. Include:

1. **🚨 Safety Reminder of the Week** — one critical safety topic relevant to industrial operations
2. **⚠️ Near Miss Spotlight** — a fictional but realistic near-miss scenario with lessons learned
3. **✅ Safety Hero Recognition** — encourage reporting and safe behaviors
4. **📊 Safety KPI Snapshot** — sample format for LTIFR, near misses, observations
5. **🎯 Action of the Week** — one specific safety action for all employees this week
6. **📚 Did You Know?** — an interesting OHS fact or regulation update (South Africa context)

Make it engaging, professional, and motivating. Use emojis for visual appeal. Keep it concise — suitable for a safety notice board or WhatsApp broadcast.''';

      final resp = await model.generateContent([Content.text(prompt)]);
      if (mounted) setState(() => _result = resp.text ?? 'Generation failed');
    } catch (e) {
      if (mounted) setState(() => _result = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flash_on, color: Colors.amber, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Weekly Safety Flash Generator',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate a professional safety bulletin powered by Gemini AI',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _generate,
                    icon:
                        _loading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(
                      _loading
                          ? 'Generating bulletin…'
                          : 'Generate Safety Flash',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.article, size: 16, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            'Safety Flash Bulletin',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          UIUtils.showToast(context, 'Copied to clipboard');
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Text(
                    _result,
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
          if (_result.isEmpty && !_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.flash_on,
                      size: 64,
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    const Text('Auto-generate your weekly safety bulletin'),
                    Text(
                      'Tap Generate to create an AI-powered safety flash',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
