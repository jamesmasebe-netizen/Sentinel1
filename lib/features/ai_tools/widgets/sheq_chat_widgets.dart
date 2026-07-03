import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}

class ChatBubbleWidget extends StatelessWidget {
  final ChatMessage msg;
  const ChatBubbleWidget({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color:
              msg.isError
                  ? XMTheme.error.withValues(alpha: 0.1)
                  : msg.isUser
                  ? XMTheme.secondary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 13,
            color: msg.isUser ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}

class QuickPrompts extends StatelessWidget {
  final ValueChanged<String> onPromptSelected;
  const QuickPrompts({super.key, required this.onPromptSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children:
            [
                  'Explain LOTOTO procedure',
                  'Draft a toolbox talk on falls',
                  'What is an LTIFR?',
                  'PPE for chemical handling',
                  'Steps for incident investigation',
                ]
                .map(
                  (q) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(q, style: const TextStyle(fontSize: 11)),
                      onPressed: () => onPromptSelected(q),
                      backgroundColor: XMTheme.secondary.withValues(
                        alpha: 0.08,
                      ),
                      side: BorderSide(
                        color: XMTheme.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}
