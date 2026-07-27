import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/automation/loto_automation.dart';

final lockedOutEquipmentProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final automation = ref.watch(lotoAutomationProvider);
  return automation.streamLockedOutEquipment();
});
