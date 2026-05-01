import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';

// ─── Gemini model provider ───
final _geminiProvider = Provider<GenerativeModel>((ref) {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  return GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
});

/// Full SHEQ AI Hub — Chat, Photo Hazard, RCA Assistant, Safety Flash
class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});
  @override
  ConsumerState<AIChatScreen> createState() => _AIChatState();
}

class _AIChatState extends ConsumerState<AIChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() { super.initState(); _tab = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(
            gradient: LinearGradient(colors: [XMTheme.secondary, XMTheme.primary]),
            borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.white)),
          const SizedBox(width: 10),
          const Text('SHEQ AI Intelligence'),
        ]),
        bottom: TabBar(controller: _tab, isScrollable: true, tabAlignment: TabAlignment.start, tabs: const [
          Tab(icon: Icon(Icons.chat, size: 16), text: 'SHEQ Chat'),
          Tab(icon: Icon(Icons.camera_alt, size: 16), text: 'Hazard Photo'),
          Tab(icon: Icon(Icons.psychology, size: 16), text: 'RCA Assistant'),
          Tab(icon: Icon(Icons.flash_on, size: 16), text: 'Safety Flash'),
        ]),
      ),
      body: TabBarView(controller: _tab, children: const [
        _SheqChatTab(),
        _HazardPhotoTab(),
        _RcaAssistantTab(),
        _SafetyFlashTab(),
      ]),
    );
  }
}

// ─── 1. SHEQ Chat ───────────────────────────────────────────────────────────

class _SheqChatTab extends ConsumerStatefulWidget {
  const _SheqChatTab();
  @override
  ConsumerState<_SheqChatTab> createState() => _SheqChatState();
}

class _SheqChatState extends ConsumerState<_SheqChatTab> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _loading = false;
  late ChatSession _chat;

  static const _systemPrompt =
    'You are SHEQ-AI, an expert Safety, Health, Environment and Quality assistant. '
    'You help with OHS Act compliance (South Africa), incident investigation, risk management, '
    'PPE selection, permit systems, and CAPA management. '
    'Be concise, practical, and always prioritise worker safety.';

  @override
  void initState() {
    super.initState();
    final model = ref.read(_geminiProvider);
    _chat = model.startChat(history: [Content.text(_systemPrompt)]);
    _messages.add(const _Msg(text: 'Hello! I\'m SHEQ-AI powered by Gemini. Ask me anything about safety, health, environment, or quality management.', isUser: false));
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() { _messages.add(_Msg(text: text, isUser: true)); _loading = true; _ctrl.clear(); });
    _scrollDown();
    try {
      final resp = await _chat.sendMessage(Content.text(text));
      if (mounted) setState(() => _messages.add(_Msg(text: resp.text ?? '…', isUser: false)));
    } catch (e) {
      if (mounted) setState(() => _messages.add(_Msg(text: 'Error: ${e.toString().substring(0, 120)}', isUser: false, isError: true)));
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollDown();
    }
  }

  void _scrollDown() { WidgetsBinding.instance.addPostFrameCallback((_) { if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Quick prompts
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          'Explain LOTOTO procedure', 'Draft a toolbox talk on falls', 'What is an LTIFR?', 'PPE for chemical handling', 'Steps for incident investigation',
        ].map((q) => Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(
          label: Text(q, style: const TextStyle(fontSize: 11)), onPressed: () { _ctrl.text = q; _send(); },
          backgroundColor: XMTheme.secondary.withValues(alpha: 0.08), side: BorderSide(color: XMTheme.secondary.withValues(alpha: 0.3)),
        ))).toList()),
      ),
      // Messages
      Expanded(child: ListView.builder(controller: _scroll, padding: const EdgeInsets.all(12), itemCount: _messages.length, itemBuilder: (_, i) => _BubbleWidget(msg: _messages[i]))),
      if (_loading) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: XMTheme.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: XMTheme.secondary))),
        const SizedBox(width: 8), Text('SHEQ-AI is thinking…', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ])),
      // Input
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: Row(children: [
          Expanded(child: TextField(controller: _ctrl, maxLines: null, onSubmitted: (_) => _send(),
            decoration: InputDecoration(hintText: 'Ask about safety, compliance, regulations…', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), isDense: true))),
          const SizedBox(width: 8),
          FilledButton(onPressed: _loading ? null : _send, style: FilledButton.styleFrom(backgroundColor: XMTheme.secondary, shape: const CircleBorder(), padding: const EdgeInsets.all(12)),
            child: const Icon(Icons.send, size: 18)),
        ])),
    ]);
  }
}

class _Msg { final String text; final bool isUser; final bool isError;
  const _Msg({required this.text, required this.isUser, this.isError = false}); }

class _BubbleWidget extends StatelessWidget {
  final _Msg msg;
  const _BubbleWidget({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Align(alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: msg.isError ? XMTheme.error.withValues(alpha: 0.1) : msg.isUser ? XMTheme.secondary : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4), bottomRight: Radius.circular(msg.isUser ? 4 : 16))),
        child: Text(msg.text, style: TextStyle(fontSize: 13, color: msg.isUser ? Colors.white : null))));
  }
}

// ─── 2. Photo Hazard Analysis ────────────────────────────────────────────────

class _HazardPhotoTab extends ConsumerStatefulWidget {
  const _HazardPhotoTab();
  @override
  ConsumerState<_HazardPhotoTab> createState() => _HazardPhotoState();
}

class _HazardPhotoState extends ConsumerState<_HazardPhotoTab> {
  File? _image;
  String _result = '';
  bool _loading = false;

  Future<void> _pick(ImageSource src) async {
    final picked = await ImagePicker().pickImage(source: src, imageQuality: 80);
    if (picked != null) setState(() { _image = File(picked.path); _result = ''; });
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() => _loading = true);
    try {
      final model = ref.read(_geminiProvider);
      final bytes = await _image!.readAsBytes();
      final resp = await model.generateContent([
        Content.multi([
          TextPart('You are a workplace safety inspector. Analyze this image and identify: 1) All visible hazards (classify each as Critical/High/Medium/Low risk), 2) Non-compliances with OHS standards, 3) Recommended immediate corrective actions, 4) PPE requirements for this area. Format your response clearly with headers.'),
          DataPart('image/jpeg', bytes),
        ])
      ]);
      if (mounted) setState(() => _result = resp.text ?? 'No analysis returned');
    } catch (e) {
      if (mounted) setState(() => _result = 'Analysis error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header card
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
        gradient: LinearGradient(colors: [XMTheme.warning.withValues(alpha: 0.1), XMTheme.error.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(12), border: Border.all(color: XMTheme.warning.withValues(alpha: 0.2))),
        child: Row(children: [
          const Icon(Icons.camera_alt, color: XMTheme.warning, size: 24), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AI Hazard Photo Analysis', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text('Powered by Gemini Vision — identifies hazards, non-compliances & corrective actions', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
        ])),
      const SizedBox(height: 16),
      // Image picker
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.camera_alt, size: 18), label: const Text('Take Photo'))),
        const SizedBox(width: 12),
        Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library, size: 18), label: const Text('From Gallery'))),
      ]),
      const SizedBox(height: 12),
      if (_image != null) ...[
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_image!, width: double.infinity, height: 220, fit: BoxFit.cover)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: _loading ? null : _analyze,
          icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search, size: 18),
          label: Text(_loading ? 'Analyzing hazards…' : 'Analyze for Hazards'),
          style: FilledButton.styleFrom(backgroundColor: XMTheme.warning),
        )),
      ],
      if (_result.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.analytics, size: 16, color: XMTheme.secondary), const SizedBox(width: 8), const Text('AI Hazard Report', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))]),
            const Divider(height: 16), Text(_result, style: const TextStyle(fontSize: 13, height: 1.5)),
          ])),
      ],
      if (_image == null) Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [
        Icon(Icons.add_a_photo, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
        const SizedBox(height: 12), const Text('Take or upload a photo of your work area'),
        Text('Gemini will identify hazards automatically', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]))),
    ]));
  }
}

// ─── 3. RCA Assistant ────────────────────────────────────────────────────────

class _RcaAssistantTab extends ConsumerStatefulWidget {
  const _RcaAssistantTab();
  @override
  ConsumerState<_RcaAssistantTab> createState() => _RcaState();
}

class _RcaState extends ConsumerState<_RcaAssistantTab> {
  final _incCtrl = TextEditingController(), _injCtrl = TextEditingController(), _locCtrl = TextEditingController();
  String _severity = 'Major', _result = '';
  bool _loading = false;

  @override
  void dispose() { _incCtrl.dispose(); _injCtrl.dispose(); _locCtrl.dispose(); super.dispose(); }

  Future<void> _analyze() async {
    if (_incCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final model = ref.read(_geminiProvider);
      final prompt = '''You are an expert OHS incident investigator. Conduct a Root Cause Analysis (RCA) for the following incident:

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
      if (mounted) setState(() => _result = resp.text ?? 'No analysis returned');
    } catch (e) {
      if (mounted) setState(() => _result = 'RCA error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
        gradient: LinearGradient(colors: [XMTheme.primary.withValues(alpha: 0.08), XMTheme.secondary.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(12), border: Border.all(color: XMTheme.primary.withValues(alpha: 0.2))),
        child: const Row(children: [Icon(Icons.psychology, color: XMTheme.primary, size: 20), SizedBox(width: 10),
          Expanded(child: Text('AI-Powered Root Cause Analysis', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)))])),
      const SizedBox(height: 16),
      TextFormField(controller: _incCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Incident Description *', hintText: 'Describe what happened in detail…')),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextFormField(controller: _injCtrl, decoration: const InputDecoration(labelText: 'Injuries / Damage'))),
        const SizedBox(width: 12),
        Expanded(child: TextFormField(controller: _locCtrl, decoration: const InputDecoration(labelText: 'Location'))),
      ]),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _severity, decoration: const InputDecoration(labelText: 'Incident Severity'),
        items: ['Critical', 'Major', 'Moderate', 'Minor', 'Near Miss'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => _severity = v!)),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: _loading ? null : _analyze,
        icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.psychology, size: 18),
        label: Text(_loading ? 'Generating RCA…' : 'Generate Root Cause Analysis'),
      )),
      if (_result.isNotEmpty) ...[
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.article, size: 16, color: XMTheme.primary), const SizedBox(width: 8), const Text('AI RCA Report', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))]),
            const Divider(height: 16), Text(_result, style: const TextStyle(fontSize: 13, height: 1.5)),
          ])),
      ],
    ]));
  }
}

// ─── 4. Weekly Safety Flash Generator ───────────────────────────────────────

class _SafetyFlashTab extends ConsumerStatefulWidget {
  const _SafetyFlashTab();
  @override
  ConsumerState<_SafetyFlashTab> createState() => _SafetyFlashState();
}

class _SafetyFlashState extends ConsumerState<_SafetyFlashTab> {
  String _result = '';
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      final siteId = profile?.siteId ?? 'this site';
      final model = ref.read(_geminiProvider);
      final prompt = '''Generate a professional Weekly Safety Flash bulletin for $siteId. Include:

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
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
        borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.flash_on, color: Colors.amber, size: 24), SizedBox(width: 10),
            Text('Weekly Safety Flash Generator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))]),
          const SizedBox(height: 8),
          Text('Generate a professional safety bulletin powered by Gemini AI', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _loading ? null : _generate,
            icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome, size: 18),
            label: Text(_loading ? 'Generating bulletin…' : 'Generate Safety Flash'),
            style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
          )),
        ])),
      if (_result.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Row(children: [Icon(Icons.article, size: 16, color: Colors.amber), SizedBox(width: 8), Text('Safety Flash Bulletin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))]),
              IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'))); }),
            ]),
            const Divider(height: 16), Text(_result, style: const TextStyle(fontSize: 13, height: 1.6)),
          ])),
      ],
      if (_result.isEmpty && !_loading) Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [
        Icon(Icons.flash_on, size: 64, color: Colors.amber.withValues(alpha: 0.3)), const SizedBox(height: 12),
        const Text('Auto-generate your weekly safety bulletin'), Text('Tap Generate to create an AI-powered safety flash', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]))),
    ]));
  }
}
