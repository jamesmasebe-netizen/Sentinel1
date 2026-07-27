import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bpf_models.dart';
import 'bpf_service.dart';

class BpfRibbonWidget extends ConsumerWidget {
  final String bpfTypeId;
  final String recordType; // e.g., 'leadId'
  final String recordId;
  final BpfDefinition definition;

  const BpfRibbonWidget({
    super.key,
    required this.bpfTypeId,
    required this.recordType,
    required this.recordId,
    required this.definition,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInstances = ref.watch(bpfInstancesForRecordProvider({
      'recordType': recordType,
      'recordId': recordId,
    }));

    return asyncInstances.when(
      data: (instances) {
        final bpfInstance = instances.where((i) => i.bpfTypeId == bpfTypeId).firstOrNull;
        
        if (bpfInstance == null) {
          // Can optionally show a "Start Process" button here
          return const SizedBox.shrink(); 
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  definition.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: definition.stages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stage = entry.value;
                    
                    final currentIndex = definition.stages.indexWhere((s) => s.id == bpfInstance.currentStageId);
                    final isCompleted = index < currentIndex || bpfInstance.status == 'completed';
                    final isCurrent = index == currentIndex && bpfInstance.status != 'completed';
                    
                    return Row(
                      children: [
                        _buildStageIndicator(context, stage, isCompleted, isCurrent),
                        if (index < definition.stages.length - 1)
                          _buildConnector(context, isCompleted || isCurrent),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStageIndicator(BuildContext context, BpfStageDefinition stage, bool isCompleted, bool isCurrent) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Color circleColor = colorScheme.surface;
    Color iconColor = colorScheme.onSurfaceVariant;
    IconData icon = Icons.circle_outlined;

    if (isCompleted) {
      circleColor = colorScheme.primary;
      iconColor = colorScheme.onPrimary;
      icon = Icons.check;
    } else if (isCurrent) {
      circleColor = colorScheme.primaryContainer;
      iconColor = colorScheme.onPrimaryContainer;
      icon = Icons.radio_button_checked;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: circleColor,
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            stage.title,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent || isCompleted ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(BuildContext context, bool isActive) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
      margin: const EdgeInsets.only(bottom: 24), // Align with circle center
    );
  }
}
