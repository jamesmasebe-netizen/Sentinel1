import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model for a single chat message
// ─────────────────────────────────────────────────────────────────────────────
enum _MessageRole { user, copilot }

class _ChatMessage {
  final _MessageRole role;
  final String text;
  final double? confidence;

  const _ChatMessage({
    required this.role,
    required this.text,
    this.confidence,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CopilotPanel
// ─────────────────────────────────────────────────────────────────────────────

/// A floating, glassmorphic side panel that lets users chat with the
/// Sentinel AI Copilot backed by a Firebase Cloud Function.
class CopilotPanel extends StatefulWidget {
  /// Optional context string describing the current screen / module so the
  /// Copilot can give more relevant answers.
  final String screenContext;

  const CopilotPanel({super.key, this.screenContext = ''});

  @override
  State<CopilotPanel> createState() => _CopilotPanelState();
}

class _CopilotPanelState extends State<CopilotPanel>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // ── Animation (pulsing AI icon) ────────────────────────────────────────────
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // ── Theme colours ──────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFF0A0E1A);
  static const Color _surface = Color(0xFF111827);
  static const Color _neonPurple = Color(0xFFB24BF3);
  static const Color _neonCyan = Color(0xFF00E5FF);
  static const Color _textPrimary = Color(0xFFEEF2FF);
  static const Color _textSecondary = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);

    // Welcome message
    _messages.add(const _ChatMessage(
      role: _MessageRole.copilot,
      text:
          "Hello! I'm Sentinel Copilot. Ask me anything about your enterprise data, KPIs, or workflow.",
      confidence: 1.0,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Firebase Call ──────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final query = _inputController.text.trim();
    if (query.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(role: _MessageRole.user, text: query));
      _isLoading = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('askCopilot');

      final result = await callable.call<Map<dynamic, dynamic>>({
        'query': query,
        'screenContext': widget.screenContext,
      });

      final data = result.data;
      final answer = (data['answer'] as String?) ?? 'No response received.';
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;

      setState(() {
        _messages.add(_ChatMessage(
          role: _MessageRole.copilot,
          text: answer,
          confidence: confidence,
        ));
        _isLoading = false;
      });
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          role: _MessageRole.copilot,
          text: 'Error (${e.code}): ${e.message ?? "Unknown error"}',
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          role: _MessageRole.copilot,
          text: 'Unexpected error: $e',
        ));
        _isLoading = false;
      });
    }

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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 360,
          decoration: BoxDecoration(
            color: _bg.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _neonPurple.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _neonPurple.withOpacity(0.18),
                blurRadius: 32,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: _neonCyan.withOpacity(0.08),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              const Divider(height: 1, color: Color(0xFF1E293B)),
              Expanded(child: _buildChatList()),
              const Divider(height: 1, color: Color(0xFF1E293B)),
              _buildInputRow(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _neonPurple.withOpacity(0.15),
            _neonCyan.withOpacity(0.08),
          ],
        ),
      ),
      child: Row(
        children: [
          // Pulsing AI icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _neonPurple.withOpacity(_pulseAnimation.value * 0.7),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const CircleAvatar(
                backgroundColor: Color(0xFF1E1040),
                child: Icon(Icons.auto_awesome, color: Color(0xFFB24BF3), size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sentinel Copilot',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'AI Online',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Powered by badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  _neonPurple.withOpacity(0.3),
                  _neonCyan.withOpacity(0.2),
                ],
              ),
            ),
            child: Text(
              'Gemini',
              style: TextStyle(
                color: _neonCyan,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chat List ──────────────────────────────────────────────────────────────
  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _buildTypingIndicator();
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.role == _MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          _neonPurple.withOpacity(0.7),
                          _neonCyan.withOpacity(0.5),
                        ],
                      )
                    : null,
                color: isUser ? null : _surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: _neonPurple.withOpacity(0.2),
                        width: 1,
                      ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
            if (!isUser && message.confidence != null)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4),
                child: Text(
                  'Confidence: ${(message.confidence! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _neonPurple.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return _BouncingDot(delay: Duration(milliseconds: i * 150));
          }),
        ),
      ),
    );
  }

  // ── Input Row ──────────────────────────────────────────────────────────────
  Widget _buildInputRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      color: _bg,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _neonPurple.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _inputController,
                style: TextStyle(color: _textPrimary, fontSize: 13),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask Sentinel Copilot…',
                  hintStyle: TextStyle(color: _textSecondary, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [Colors.grey.shade800, Colors.grey.shade700]
                      : [_neonPurple, _neonCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: _neonPurple.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
              ),
              child: Icon(
                _isLoading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bouncing dot for typing indicator
// ─────────────────────────────────────────────────────────────────────────────
class _BouncingDot extends StatefulWidget {
  final Duration delay;
  const _BouncingDot({required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFB24BF3),
          ),
        ),
      ),
    );
  }
}
