import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/ds_widgets.dart';
import 'manager_training_dashboard.dart';

import '../widgets/my_learning_tab.dart';
import '../widgets/course_catalog_tab.dart';
import '../widgets/training_records_tab.dart';
import '../widgets/toolbox_talks_tab.dart';
import '../widgets/expiry_alerts_tab.dart';

/// Training & Competency — LMS Hub, training records, toolbox talks, expiry alerts.
class TrainingScreen extends ConsumerStatefulWidget {
  final String? initialSearch;
  final String? highlightId;

  const TrainingScreen({
    super.key,
    this.initialSearch,
    this.highlightId,
  });

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingState();
}

class _TrainingState extends ConsumerState<TrainingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const GHeader(
          title: 'Training & Development',
          subtitle: 'Learning Management System and Records',
        ),
        // Premium Sub-Header for Tabs
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'My Learning'),
              Tab(text: 'Course Catalog'),
              Tab(text: 'Records'),
              Tab(text: 'Toolbox Talks'),
              Tab(text: 'Expiry Alerts'),
              Tab(text: 'Manager Hub'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [
              MyLearningTab(),
              CourseCatalogTab(),
              TrainingRecordsTab(),
              ToolboxTalksTab(),
              ExpiryAlertsTab(),
              ManagerTrainingDashboard(),
            ],
          ),
        ),
      ],
    );
  }
}
