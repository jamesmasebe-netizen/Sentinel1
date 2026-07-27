import 'bpf_models.dart';

final issueToResolutionDefinition = BpfDefinition(
  id: 'issue_to_resolution',
  title: 'Issue to Resolution',
  stages: [
    BpfStageDefinition(
      id: 'logged',
      title: 'Logged',
      description: 'Incident, hazard, or non-conformance is reported.',
      expectedRecordType: 'incident',
    ),
    BpfStageDefinition(
      id: 'investigation',
      title: 'Investigation',
      description: 'Safety team investigates the root cause.',
      expectedRecordType: 'incident',
    ),
    BpfStageDefinition(
      id: 'capa',
      title: 'CAPA',
      description: 'Corrective and Preventive Actions assigned.',
      expectedRecordType: 'capa',
    ),
    BpfStageDefinition(
      id: 'closure',
      title: 'Closure',
      description: 'Verification that the issue is permanently resolved.',
      expectedRecordType: 'incident',
    ),
  ],
);
