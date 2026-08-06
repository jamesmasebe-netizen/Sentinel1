import 'asset_lifecycle_bpf.dart';
import 'bpf_models.dart';
import 'hire_to_retire_bpf.dart';
import 'issue_to_resolution_bpf.dart';
import 'lead_to_cash_bpf.dart';
import 'procure_to_pay_bpf.dart';
import 'project_lifecycle_bpf.dart';

/// Registry of every [BpfDefinition] by id — the only place BpfService can look up which stage
/// ids are actually valid for a given bpfTypeId, so it can reject a transition into a stage that
/// doesn't exist instead of writing it unconditionally.
final Map<String, BpfDefinition> bpfDefinitionsById = {
  leadToCashDefinition.id: leadToCashDefinition,
  procureToPayDefinition.id: procureToPayDefinition,
  assetLifecycleDefinition.id: assetLifecycleDefinition,
  issueToResolutionDefinition.id: issueToResolutionDefinition,
  hireToRetireDefinition.id: hireToRetireDefinition,
  projectLifecycleDefinition.id: projectLifecycleDefinition,
};
