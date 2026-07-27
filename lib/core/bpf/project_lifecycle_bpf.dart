import 'bpf_models.dart';

final projectLifecycleDefinition = BpfDefinition(
  id: 'project_lifecycle',
  title: 'Project Concept to Close',
  stages: [
    BpfStageDefinition(
      id: 'concept',
      title: 'Concept',
      description: 'Project initiation and conceptualization.',
      expectedRecordType: 'project',
    ),
    BpfStageDefinition(
      id: 'planning',
      title: 'Planning',
      description: 'Resource Allocation and SHEQ Safety File Request.',
      expectedRecordType: 'project',
    ),
    BpfStageDefinition(
      id: 'execution',
      title: 'Execution',
      description: 'Project is active. SHEQ compliance monitoring and PTWs in effect.',
      expectedRecordType: 'project',
    ),
    BpfStageDefinition(
      id: 'closure',
      title: 'Closure',
      description: 'Project is complete and resources are released.',
      expectedRecordType: 'project',
    ),
  ],
);
