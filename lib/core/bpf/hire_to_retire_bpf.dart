import 'bpf_models.dart';

final hireToRetireDefinition = BpfDefinition(
  id: 'hire_to_retire',
  title: 'Hire to Retire',
  stages: [
    BpfStageDefinition(
      id: 'recruitment',
      title: 'Recruitment',
      description: 'Candidate offer and acceptance.',
      expectedRecordType: 'employee',
    ),
    BpfStageDefinition(
      id: 'onboarding',
      title: 'Onboarding',
      description: 'IT access, safety inductions, and PPE issuance.',
      expectedRecordType: 'employee',
    ),
    BpfStageDefinition(
      id: 'active',
      title: 'Active',
      description: 'Employee is deployed and active.',
      expectedRecordType: 'employee',
    ),
    BpfStageDefinition(
      id: 'offboarding',
      title: 'Offboarding',
      description: 'Termination or retirement process.',
      expectedRecordType: 'employee',
    ),
  ],
);
