import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/widgets/ds_widgets.dart';
import '../../../scripts/seed_dummy_data.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_charts_grid.dart';
import 'control_tower_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isSeeding = false;
  String? _latestAlert;
  StreamSubscription? _eventSubscription;
  bool _showExecutiveView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _eventSubscription = ref.read(appEventBusProvider).stream.listen((event) {
        if (mounted) {
          setState(() {
            if (event is HighRiskIncidentReportedEvent) {
              _latestAlert =
                  'ALERT (Safety): High Risk Incident ${event.incidentId} reported on project ${event.projectId}';
            } else if (event is EmployeeTerminatedEvent) {
              _latestAlert =
                  'UPDATE (HR): Employee ${event.employeeName} terminated. Related clearances flagged.';
            } else {
              _latestAlert =
                  'EVENT (${event.sourceModule}): System update received.';
            }
          });
          // Auto clear after 10 seconds
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) setState(() => _latestAlert = null);
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    if (screenWidth > 1200) {
      crossAxisCount = 3;
    } else if (screenWidth > 800) {
      crossAxisCount = 2;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            DashboardHeader(
              isSeeding: _isSeeding,
              onSeedData: () => _seedData(context),
            ),
            
            GSpacing.vLg,
            
            // Toggle
            Center(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Operational View'), icon: Icon(Icons.dashboard_rounded)),
                  ButtonSegment(value: true, label: Text('Executive View'), icon: Icon(Icons.cell_tower_rounded)),
                ],
                selected: {_showExecutiveView},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() => _showExecutiveView = newSelection.first);
                },
              ),
            ),
            
            GSpacing.vLg,

            if (_showExecutiveView)
              SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: const ControlTowerScreen(),
              )
            else ...[
              if (_latestAlert != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _latestAlert!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        onPressed: () => setState(() => _latestAlert = null),
                      ),
                    ],
                  ),
                ),

              // 9 Charts Grid
              DashboardChartsGrid(crossAxisCount: crossAxisCount),
              GSpacing.vXl,
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _seedData(BuildContext context) async {
    setState(() => _isSeeding = true);
    try {
      final firestore = ref.read(firestoreProvider);
      await seedAllDummyData(firestore);
      if (context.mounted) {
        UIUtils.showToast(context, 'Database Seeded Successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        UIUtils.showToast(context, 'Seeding Failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }
}
