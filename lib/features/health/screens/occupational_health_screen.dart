import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../widgets/medical_tab.dart';
import '../widgets/hygiene_tab.dart';
import '../widgets/first_aid_tab.dart';
import '../widgets/wellbeing_tab.dart';

/// Occupational Health — medical exams, hygiene surveys, first aid log, wellbeing.
class OccupationalHealthScreen extends ConsumerStatefulWidget {
  const OccupationalHealthScreen({super.key});
  @override
  ConsumerState<OccupationalHealthScreen> createState() => _OHState();
}

class _OHState extends ConsumerState<OccupationalHealthScreen>
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
    final theme = Theme.of(context);
    return Column(
      children: [
        const GHeader(
          title: 'Occupational Health',
          subtitle: 'Medical surveillance, hygiene surveys, and wellbeing',
        ),
        // Premium Sub-Header for Tabs
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tab,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Medicals'),
              Tab(text: 'Hygiene'),
              Tab(text: 'First Aid'),
              Tab(text: 'Wellbeing'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              MedicalsTab(),
              HygieneTab(),
              FirstAidTab(),
              WellbeingTab(),
            ],
          ),
        ),
      ],
    );
  }
}
