import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../config/theme.dart';
import '../../people/services/hr_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          Text(
            'Appearance',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: XMTheme.primary),
          ),
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
                  Hive.box<bool>('preferences').put('isDarkMode', value);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Security Section
          Text(
            'Security',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: XMTheme.primary),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('Biometric Authentication'),
                  subtitle: const Text(
                    'Required to unlock session after 30m of inactivity',
                  ),
                  trailing: const Icon(
                    Icons.check_circle,
                    color: XMTheme.success,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.screen_lock_portrait),
                  title: const Text('Screen Capture Protection'),
                  subtitle: const Text(
                    'Enabled app-wide on mobile and desktop platforms',
                  ),
                  trailing: const Icon(
                    Icons.check_circle,
                    color: XMTheme.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Public Careers Page Section (admin-only)
          if (ref.watch(userProfileProvider).valueOrNull?.isAdmin ?? false) ...[
            Text(
              'Public Careers Page',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: XMTheme.primary),
            ),
            const SizedBox(height: 8),
            const _PublicCareersPageSection(),
            const SizedBox(height: 24),
          ],

          // App Info Section
          Text(
            'About',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: XMTheme.primary),
          ),
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

/// Lets an admin claim a public careers URL slug for their tenant — see
/// `HRService.claimTenantSlug`/`getClaimedSlugForTenant` and `PublicCareersService.resolveTenantId`
/// (the reader this feeds). Without a claimed slug, `/careers/:slug` can never resolve a tenant for
/// ANY visitor, regardless of how correct the rest of the recruitment pipeline is — this is the
/// actual first blocker in that whole chain.
class _PublicCareersPageSection extends ConsumerStatefulWidget {
  const _PublicCareersPageSection();

  @override
  ConsumerState<_PublicCareersPageSection> createState() =>
      _PublicCareersPageSectionState();
}

class _PublicCareersPageSectionState extends ConsumerState<_PublicCareersPageSection> {
  final _slugController = TextEditingController();
  String? _claimedSlug;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadClaimedSlug();
  }

  @override
  void dispose() {
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _loadClaimedSlug() async {
    try {
      final slug = await ref.read(hrServiceProvider).getClaimedSlugForTenant();
      if (mounted) setState(() => _claimedSlug = slug);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _claimSlug() async {
    final slug = _slugController.text.trim();
    if (slug.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(hrServiceProvider).claimTenantSlug(slug);
      if (mounted) {
        setState(() => _claimedSlug = slug);
        UIUtils.showToast(context, 'Careers page URL claimed', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error claiming URL — it may already be taken: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_claimedSlug != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.public, color: XMTheme.success),
          title: Text('/careers/$_claimedSlug'),
          subtitle: const Text('Your public careers page is live at this URL'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Claim a URL for your public careers page (e.g. "acme-corp").'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _slugController,
                    decoration: const InputDecoration(
                      prefixText: '/careers/',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isSaving ? null : _claimSlug,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Claim'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
