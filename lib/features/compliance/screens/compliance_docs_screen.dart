import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../widgets/register_tab.dart';
import '../widgets/expiring_tab.dart';
import '../widgets/legal_tab.dart';
import '../widgets/register_doc_form.dart';
/// Compliance & Documents — register, upload, review, expiry alerts.
class ComplianceDocsScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? highlightId;

  const ComplianceDocsScreen({
    super.key,
    this.initialSearch,
    this.highlightId,
  });

  @override
  ConsumerState<ComplianceDocsScreen> createState() => _CompDocsState();
}

class _CompDocsState extends ConsumerState<ComplianceDocsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    if (widget.highlightId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
                UIUtils.showSideSheet(
          context: context,
          title: 'Item Details',
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Viewing item: ${widget.highlightId}\n(Detail view not yet implemented)'),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // ─── Actions Bar ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Text('Regulatory Compliance', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => UIUtils.showSideSheet(
                  context: context,
                  title: 'Register Document',
                  builder: (ctx) => const RegisterDocForm(),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Document'),
              ),
            ],
          ),
        ),

        // ─── Modern TabBar ───
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tab,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Register'),
              Tab(text: 'Expiring'),
              Tab(text: 'Framework'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [RegisterTab(), ExpiringTab(), LegalTab()],
          ),
        ),
      ],
    );
  }
}

