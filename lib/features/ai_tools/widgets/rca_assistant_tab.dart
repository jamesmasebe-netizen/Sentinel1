import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../config/theme.dart';
import '../providers/gemini_provider.dart';

class RcaAssistantTab extends ConsumerStatefulWidget {
  const RcaAssistantTab({super.key});
  @override
  ConsumerState<RcaAssistantTab> createState() => _RcaState();
}

class _RcaState extends ConsumerState<RcaAssistantTab> {
  final _incCtrl = TextEditingController(),
      _injCtrl = TextEditingController(),
      _locCtrl = TextEditingController();
  String _severity = 'Major', _result = '';
  bool _loading = false;

  @override
  void dispose() {
    _incCtrl.dispose();
    _injCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_incCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final model = ref.read(geminiProvider);
      final prompt =
          '''You are an expert OHS incident investigator. Conduct a Root Cause Analysis (RCA) for the following incident:

Incident: ${_incCtrl.text}
Injuries/Damage: ${_injCtrl.text.isEmpty ? 'None reported' : _injCtrl.text}
Location: ${_locCtrl.text.isEmpty ? 'Not specified' : _locCtrl.text}
Severity: $_severity

Please provide:
1. **Immediate Causes** — direct acts/conditions that caused the incident
2. **Root Causes** — underlying management system failures (use 5-Why methodology)
3. **Contributory Factors** — environmental, human, organizational factors
4. **Corrective Actions** — specific, measurable CAPA recommendations with timelines
5. **Preventive Actions** — systemic changes to prevent recurrence
6. **SHERPA Classification** — classify the human error type if applicable

Format with clear headers and bullet points.''';

      final resp = await model.generateContent([Content.text(prompt)]);
      if (mounted) {
        setState(() => _result = resp.text ?? 'No analysis returned');
      }
    } catch (e) {
      if (mounted) setState(() => _result = 'RCA error: $e');
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  XMTheme.primary.withValues(alpha: 0.08),
                  XMTheme.secondary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: XMTheme.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.psychology, color: XMTheme.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI-Powered Root Cause Analysis',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _incCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Incident Description *',
              hintText: 'Describe what happened in detail…',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _injCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Injuries / Damage',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _locCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _severity,
            decoration: const InputDecoration(labelText: 'Incident Severity'),
            items:
                ['Critical', 'Major', 'Moderate', 'Minor', 'Near Miss']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
            onChanged: (v) => setState(() => _severity = v!),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _analyze,
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
                      : const Icon(Icons.psychology, size: 18),
              label: Text(
                _loading ? 'Generating RCA…' : 'Generate Root Cause Analysis',
              ),
            ),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 20),
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
                    children: [
                      const Icon(
                        Icons.article,
                        size: 16,
                        color: XMTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI RCA Report',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Text(
                    _result,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
