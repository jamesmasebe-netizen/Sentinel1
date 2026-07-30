import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/providers/app_providers.dart';

final equipmentServiceProvider = Provider<EquipmentService>((ref) {
  final fs = ref.read(firestoreServiceProvider);
  final tenantId = ref.read(currentTenantIdProvider);
  return EquipmentService(fs, tenantId);
});

class EquipmentService {
  final FirestoreService _fs;
  final String? _tenantId;

  EquipmentService(this._fs, this._tenantId);

  /// Assigns equipment to an employee (e.g. an operator/inspector) and marks
  /// it Deployed. [assignedToId] is an employee ID, not a project ID — see
  /// F-005 in docs/fixes/FIX_LIST.md for the naming confusion this replaced.
  Future<void> deployEquipment(String equipmentId, String assignedToId) async {
    if (_tenantId == null || _tenantId.isEmpty) throw Exception('No tenant context');
    await _fs.updateDocument(
      tenantId: _tenantId,
      collection: 'equipment',
      documentId: equipmentId,
      data: {
        'status': 'Deployed',
        'assignedToId': assignedToId,
      },
    );
  }
}
