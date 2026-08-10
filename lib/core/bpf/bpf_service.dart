import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_providers.dart';
import 'bpf_definitions.dart';
import 'bpf_models.dart';

final bpfServiceProvider = Provider<BpfService>((ref) {
  final tenantId = ref.watch(currentTenantIdProvider);
  return BpfService(
    FirebaseFirestore.instance,
    tenantId ?? 'default_tenant',
  );
});

final bpfInstanceProvider = StreamProvider.family<BpfInstance?, String>((ref, bpfId) {
  final service = ref.watch(bpfServiceProvider);
  return service.streamBpfInstance(bpfId);
});

final bpfInstancesForRecordProvider = StreamProvider.family<List<BpfInstance>, Map<String, String>>((ref, args) {
  final service = ref.watch(bpfServiceProvider);
  final recordType = args['recordType']!;
  final recordId = args['recordId']!;
  return service.streamBpfInstancesByRecord(recordType, recordId);
});

final bpfInstancesByTypeProvider = StreamProvider.family<List<BpfInstance>, String>((ref, bpfTypeId) {
  final service = ref.watch(bpfServiceProvider);
  return service.streamInstancesByType(bpfTypeId);
});

class BpfService {
  final FirebaseFirestore _db;
  final String _tenantId;

  BpfService(this._db, this._tenantId);

  CollectionReference get _bpfCollection =>
      _db.collection('tenants').doc(_tenantId).collection('bpf_instances');

  /// Throws if [stageId] isn't a stage [bpfTypeId]'s BpfDefinition actually declares (see
  /// bpf_definitions.dart). A bpfTypeId with no registered definition passes through unchecked —
  /// this guards against a wrong *stage id* for a known flow, not against undeclared flow types.
  void _assertKnownStage(String bpfTypeId, String stageId) {
    final definition = bpfDefinitionsById[bpfTypeId];
    if (definition == null) return;
    final isKnownStage = definition.stages.any((s) => s.id == stageId);
    if (!isKnownStage) {
      final knownIds = definition.stages.map((s) => s.id).join(', ');
      throw ArgumentError(
        'BPF "$bpfTypeId" (${definition.title}) has no stage "$stageId". '
        'Known stages: $knownIds.',
      );
    }
  }

  Stream<BpfInstance?> streamBpfInstance(String id) {
    return _bpfCollection.doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      return BpfInstance.fromMap(snap.data() as Map<String, dynamic>, snap.id);
    });
  }

  Stream<List<BpfInstance>> streamBpfInstancesByRecord(String recordType, String recordId) {
    return _bpfCollection
        .where('linkedRecordIds.$recordType', isEqualTo: recordId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BpfInstance.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  /// All instances of a given BPF flow across the tenant (e.g. every equipment's
  /// asset_lifecycle progress at once), as opposed to streamBpfInstancesByRecord's
  /// single-record scope.
  Stream<List<BpfInstance>> streamInstancesByType(String bpfTypeId) {
    return _bpfCollection
        .where('bpfTypeId', isEqualTo: bpfTypeId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BpfInstance.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<String> startBpf(String bpfTypeId, String startingStageId, String recordType, String recordId) async {
    _assertKnownStage(bpfTypeId, startingStageId);

    final newRef = _bpfCollection.doc();
    final instance = BpfInstance(
      id: newRef.id,
      bpfTypeId: bpfTypeId,
      currentStageId: startingStageId,
      status: 'in_progress',
      linkedRecordIds: {recordType: recordId},
      startedAt: DateTime.now(),
      stageStartedAt: DateTime.now(),
    );
    await newRef.set(instance.toMap());
    return newRef.id;
  }

  Future<void> advanceStage(String bpfId, String nextStageId, {Map<String, String>? newlyLinkedRecords}) async {
    final doc = await _bpfCollection.doc(bpfId).get();
    if (!doc.exists) return;

    final current = BpfInstance.fromMap(doc.data() as Map<String, dynamic>, doc.id);

    if (current.status != 'in_progress') {
      throw StateError(
        'Cannot advance BPF instance $bpfId: status is "${current.status}", not "in_progress".',
      );
    }
    _assertKnownStage(current.bpfTypeId, nextStageId);

    final updatedLinks = Map<String, String>.from(current.linkedRecordIds);
    if (newlyLinkedRecords != null) {
      updatedLinks.addAll(newlyLinkedRecords);
    }

    final updated = current.copyWith(
      currentStageId: nextStageId,
      stageStartedAt: DateTime.now(),
      linkedRecordIds: updatedLinks,
    );

    await _bpfCollection.doc(bpfId).update(updated.toMap());
  }
  
  Future<void> completeBpf(String bpfId) async {
    await _bpfCollection.doc(bpfId).update({'status': 'completed'});
  }
}
