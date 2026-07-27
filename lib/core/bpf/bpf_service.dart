import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_providers.dart';
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

class BpfService {
  final FirebaseFirestore _db;
  final String _tenantId;

  BpfService(this._db, this._tenantId);

  CollectionReference get _bpfCollection =>
      _db.collection('tenants').doc(_tenantId).collection('bpf_instances');

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

  Future<String> startBpf(String bpfTypeId, String startingStageId, String recordType, String recordId) async {
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
