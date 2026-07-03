import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../widgets/sheq_chat_tab.dart';
import '../widgets/hazard_photo_tab.dart';
import '../widgets/rca_assistant_tab.dart';
import '../widgets/safety_flash_tab.dart';

/// Full SHEQ AI Hub — Chat, Photo Hazard, RCA Assistant, Safety Flash
class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});
  @override
  ConsumerState<AIChatScreen> createState() => _AIChatState();
}

class _AIChatState extends ConsumerState<AIChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [XMTheme.secondary, XMTheme.primary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('SHEQ AI Intelligence'),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.chat, size: 16), text: 'SHEQ Chat'),
            Tab(icon: Icon(Icons.camera_alt, size: 16), text: 'Hazard Photo'),
            Tab(icon: Icon(Icons.psychology, size: 16), text: 'RCA Assistant'),
            Tab(icon: Icon(Icons.flash_on, size: 16), text: 'Safety Flash'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          SheqChatTab(),
          HazardPhotoTab(),
          RcaAssistantTab(),
          SafetyFlashTab(),
        ],
      ),
    );
  }
}
