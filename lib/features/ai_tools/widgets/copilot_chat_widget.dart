import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../services/copilot_service.dart';
import 'sheq_chat_widgets.dart';

class CopilotChatWidget extends ConsumerStatefulWidget {
  final String tenantId;
  final String moduleContext;
  final List<String> quickPrompts;

  const CopilotChatWidget({
    super.key,
    required this.tenantId,
    required this.moduleContext,
    this.quickPrompts = const [],
  });

  @override
  ConsumerState<CopilotChatWidget> createState() => _CopilotChatWidgetState();
}

class _CopilotChatWidgetState extends ConsumerState<CopilotChatWidget> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: 'Hello! I am your AI Copilot for the ${widget.moduleContext} module. How can I help you today?',
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

    final copilotService = ref.read(copilotServiceProvider(widget.tenantId));

    try {
      final responseText = await copilotService.askCopilot(text, widget.moduleContext);
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: responseText, isUser: false));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Error: ${e.toString().substring(0, 120)}',
              isUser: false,
              isError: true,
            ),
          );
        });
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
        if (widget.quickPrompts.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: widget.quickPrompts.map(
                (q) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(q, style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      _ctrl.text = q;
                      _send();
                    },
                    backgroundColor: XMTheme.secondary.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: XMTheme.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
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
                  'Copilot is thinking…',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
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
                    hintText: 'Ask Copilot...',
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
