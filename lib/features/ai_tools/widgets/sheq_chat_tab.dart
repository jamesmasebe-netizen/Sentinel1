import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../config/theme.dart';
import '../providers/gemini_provider.dart';
import 'sheq_chat_widgets.dart';

class SheqChatTab extends ConsumerStatefulWidget {
  const SheqChatTab({super.key});
  @override
  ConsumerState<SheqChatTab> createState() => _SheqChatState();
}

class _SheqChatState extends ConsumerState<SheqChatTab> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
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
    final model = ref.read(geminiProvider);
    _chat = model.startChat(history: [Content.text(_systemPrompt)]);
    _messages.add(
      const ChatMessage(
        text:
            'Hello! I\'m SHEQ-AI powered by Gemini. Ask me anything about safety, health, environment, or quality management.',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _loading = true;
      _ctrl.clear();
    });
    _scrollDown();
    try {
      final resp = await _chat.sendMessage(Content.text(text));
      if (mounted) {
        setState(
          () =>
              _messages.add(ChatMessage(text: resp.text ?? '…', isUser: false)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _messages.add(
            ChatMessage(
              text: 'Error: ${e.toString().substring(0, 120)}',
              isUser: false,
              isError: true,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quick prompts
        QuickPrompts(
          onPromptSelected: (q) {
            _ctrl.text = q;
            _send();
          },
        ),
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (_, i) => ChatBubbleWidget(msg: _messages[i]),
          ),
        ),
        if (_loading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: XMTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: XMTheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SHEQ-AI is thinking…',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        // Input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  maxLines: null,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Ask about safety, compliance, regulations…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loading ? null : _send,
                style: FilledButton.styleFrom(
                  backgroundColor: XMTheme.secondary,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(Icons.send, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
