import 'bpf_models.dart';

final assetLifecycleDefinition = BpfDefinition(
  id: 'asset_lifecycle',
  title: 'Asset Lifecycle',
  stages: [
    BpfStageDefinition(
      id: 'acquisition',
      title: 'Acquisition',
      description: 'Asset is purchased and registered in the system.',
      expectedRecordType: 'equipment',
    ),
    BpfStageDefinition(
      id: 'deployment',
      title: 'Deployment',
      description: 'Asset is assigned to a location or project.',
      expectedRecordType: 'equipment',
    ),
    BpfStageDefinition(
      id: 'maintenance',
      title: 'Maintenance',
      description: 'Asset undergoes scheduled or reactive maintenance.',
      expectedRecordType: 'equipment',
    ),
    BpfStageDefinition(
      id: 'decommissioning',
      title: 'Decommissioning',
      description: 'Asset is retired and removed from active service.',
      expectedRecordType: 'equipment',
    ),
  ],
);
