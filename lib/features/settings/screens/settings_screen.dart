import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../config/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: XMTheme.primary)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Dark Mode'),
              subtitle: const Text('Toggle between light and dark themes'),
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(isDarkModeProvider.notifier).state = value;
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Security Section
          Text('Security', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: XMTheme.primary)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('Biometric Authentication'),
                  subtitle: const Text('Required to unlock session after 15m of inactivity'),
                  trailing: const Icon(Icons.check_circle, color: XMTheme.success),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.screen_lock_portrait),
                  title: const Text('Screen Capture Protection'),
                  subtitle: const Text('Enabled on sensitive screens (Executive Dashboard, Action Tracker)'),
                  trailing: const Icon(Icons.check_circle, color: XMTheme.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Info Section
          Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: XMTheme.primary)),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('XM System App'),
              subtitle: Text('Version 1.0.0 (Build 1)'),
            ),
          ),
        ],
      ),
    );
  }
}
