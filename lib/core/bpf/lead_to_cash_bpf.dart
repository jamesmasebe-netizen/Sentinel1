import 'bpf_models.dart';

const leadToCashDefinition = BpfDefinition(
  id: 'lead_to_cash',
  title: 'Lead to Cash',
  stages: [
    BpfStageDefinition(
      id: 'lead',
      title: 'Lead',
      description: 'Qualify the lead in CRM',
      expectedRecordType: 'leadId',
    ),
    BpfStageDefinition(
      id: 'opportunity',
      title: 'Opportunity',
      description: 'Develop the opportunity and gather requirements',
      expectedRecordType: 'opportunityId',
    ),
    BpfStageDefinition(
      id: 'quote',
      title: 'Quote',
      description: 'Generate and send a quote',
      expectedRecordType: 'quoteId',
    ),
    BpfStageDefinition(
      id: 'project_execution',
      title: 'Project Execution',
      description: 'Execute PMO Project, capture time, expenses, and SHEQ compliance',
      expectedRecordType: 'projectId',
    ),
    BpfStageDefinition(
      id: 'invoice',
      title: 'Invoice',
      description: 'Generate client invoice and collect cash',
      expectedRecordType: 'invoiceId',
    ),
  ],
);
