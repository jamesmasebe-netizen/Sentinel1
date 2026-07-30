import 'bpf_models.dart';

// Stage IDs/titles mirror the PRINCE2-based `ProjectStage` list every project
// is seeded with (see new_project_dialog_content.dart's `_defaultStages`) so
// that BpfInstance.currentStageId always matches a real Project.stages[].id —
// see F-008 in docs/fixes/FIX_LIST.md.
final projectLifecycleDefinition = BpfDefinition(
  id: 'project_lifecycle',
  title: 'Project Concept to Close',
  stages: [
    BpfStageDefinition(
      id: 'stage_0',
      title: 'Starting Up a Project (SU)',
      description: 'Project initiation and conceptualization.',
      expectedRecordType: 'project',
    ),
    BpfStageDefinition(
      id: 'stage_1',
      title: 'Initiating a Project (IP)',
      description: 'Resource allocation and SHEQ Safety File request.',
      expectedRecordType: 'project',
    ),
    BpfStageDefinition(
      id: 'stage_2',
      title: 'Controlling a Stage (CS)',
      description: 'Project is active. SHEQ compliance monitoring and PTWs in effect.',
      expectedRecordType: 'project',
    ),
    BpfStageDefinition(
      id: 'stage_3',
      title: 'Managing Stage Boundaries (SB)',
      description: 'Stage review and approval to proceed to the next stage.',
      expectedRecordType: 'project',
    ),
    BpfStageDefinition(
      id: 'stage_4',
      title: 'Managing Product Delivery (MP)',
      description: 'Work package delivery. SHEQ compliance monitoring and PTWs in effect.',
      expectedRecordType: 'project',
    ),
    BpfStageDefinition(
      id: 'stage_5',
      title: 'Closing a Project (CP)',
      description: 'Project is complete and resources are released.',
      expectedRecordType: 'project',
    ),
  ],
);
