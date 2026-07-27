import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

enum _Sender { customer, agent }

class _ChatMessage {
  _ChatMessage({required this.sender, required this.text, required this.time});
  final _Sender sender;
  final String text;
  final TimeOfDay time;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

final _chatMessagesProvider =
    StateNotifierProvider<_ChatMessagesNotifier, List<_ChatMessage>>((ref) {
  return _ChatMessagesNotifier();
});

class _ChatMessagesNotifier extends StateNotifier<List<_ChatMessage>> {
  _ChatMessagesNotifier()
      : super([
          _ChatMessage(
            sender: _Sender.customer,
            text: 'Hi, I placed an order 3 days ago and it still hasn\'t shipped.',
            time: const TimeOfDay(hour: 9, minute: 12),
          ),
          _ChatMessage(
            sender: _Sender.agent,
            text: 'Hello! I\'m sorry to hear that. Could you please provide your order number?',
            time: const TimeOfDay(hour: 9, minute: 13),
          ),
          _ChatMessage(
            sender: _Sender.customer,
            text: 'Sure, it\'s #ORD-948271.',
            time: const TimeOfDay(hour: 9, minute: 14),
          ),
          _ChatMessage(
            sender: _Sender.agent,
            text: 'Thank you! Let me pull that up for you right now.',
            time: const TimeOfDay(hour: 9, minute: 15),
          ),
          _ChatMessage(
            sender: _Sender.customer,
            text: 'I was expecting it by yesterday. I really need it urgently.',
            time: const TimeOfDay(hour: 9, minute: 16),
          ),
        ]);

  void addMessage(_ChatMessage msg) => state = [...state, msg];
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class OmnichannelChatScreen extends ConsumerStatefulWidget {
  const OmnichannelChatScreen({super.key});

  @override
  ConsumerState<OmnichannelChatScreen> createState() =>
      _OmnichannelChatScreenState();
}

class _OmnichannelChatScreenState
    extends ConsumerState<OmnichannelChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const String _mockAiSuggestion =
      'I sincerely apologize for the inconvenience. I\'ve escalated your order #ORD-948271 '
      'to our dispatch team and you should receive a shipping confirmation within 2 hours. '
      'We\'ll also add a 10% discount on your next order for the trouble.';

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final now = TimeOfDay.now();
    ref.read(_chatMessagesProvider.notifier).addMessage(
          _ChatMessage(sender: _Sender.agent, text: text, time: now),
        );
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _suggestAiReply() {
    _controller.text = _mockAiSuggestion;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6C3FC4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI reply suggestion loaded into text field.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(_chatMessagesProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0D2B), // deep navy
              Color(0xFF1A0938), // dark purple
              Color(0xFF0D0D2B),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildChannelTabs(),
              Expanded(child: _buildMessageList(messages)),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white70, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B5EEA), Color(0xFF9B6FFF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('MJ',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Marcus Johnson',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('Online · Web Chat',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTabs() {
    final channels = ['Chat', 'Email', 'SMS', 'Social'];
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: channels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isActive = i == 0;
          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF7B5EEA), Color(0xFF5C3BC4)])
                    : null,
                color: isActive ? null : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.15),
                ),
              ),
              child: Text(
                channels[i],
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: isActive
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageList(List<_ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _ChatBubble(message: msg);
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI Suggest button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _suggestAiReply,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Suggest AI Reply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C3FC4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Text input row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'Type a reply…',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.attach_file,
                            color: Colors.white38, size: 20),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7B5EEA), Color(0xFF5C3BC4)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat Bubble widget
// ---------------------------------------------------------------------------

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isAgent = message.sender == _Sender.agent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isAgent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isAgent) ...[
            _avatar('MJ', const Color(0xFF3F51B5)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAgent
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isAgent)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text('Customer',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  decoration: BoxDecoration(
                    gradient: isAgent
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF6C3FC4),
                              Color(0xFF5C3BC4),
                            ],
                          )
                        : null,
                    color: isAgent
                        ? null
                        : Colors.white.withOpacity(0.09),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(isAgent ? 16 : 4),
                      bottomRight:
                          Radius.circular(isAgent ? 4 : 16),
                    ),
                    border: isAgent
                        ? null
                        : Border.all(
                            color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13.5, height: 1.4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: Colors.white30, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          if (isAgent) ...[
            const SizedBox(width: 8),
            _avatar('ME', const Color(0xFF6C3FC4)),
          ],
        ],
      ),
    );
  }

  Widget _avatar(String initials, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
