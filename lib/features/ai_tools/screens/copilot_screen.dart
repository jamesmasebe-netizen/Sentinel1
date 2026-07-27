import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../billing/screens/billing_portal_screen.dart';
import '../widgets/copilot_chat_widget.dart';

class CopilotScreen extends ConsumerWidget {
  final String moduleContext;

  const CopilotScreen({super.key, required this.moduleContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    if (!isPremium) {
      return Scaffold(
        appBar: AppBar(title: Text('$moduleContext Copilot')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.workspace_premium,
                  size: 80,
                  color: XMTheme.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Upgrade to Premium to unlock AI Copilot',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Get real-time insights, intelligent suggestions, and full access to our AI features.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: XMTheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BillingPortalScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Upgrade Now',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tenantId = ref.watch(tenantDocProvider).id;

    return Scaffold(
      appBar: AppBar(title: Text('$moduleContext Copilot')),
      body: CopilotChatWidget(tenantId: tenantId, moduleContext: moduleContext),
    );
  }
}
