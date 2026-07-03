import '../../models/project_models.dart';

Future<Map<String, List<Map<String, dynamic>>>> fetchSafetyComplianceData(
    dynamic fs, Project project, List<String> riskAssessmentIds) async {
  final risksList = <Map<String, dynamic>>[];
  final permitsList = <Map<String, dynamic>>[];
  final actionsList = <Map<String, dynamic>>[];

  // 1. Fetch risk assessment details
  for (final id in riskAssessmentIds) {
    final hira = await fs.tenantCollection('', 'risk_assessments').doc(id).get();
    if (hira.exists) {
      risksList.add({
        'id': id,
        'type': 'HIRA',
        'title': hira.data()['title'] ?? 'Unnamed HIRA',
        'rating': hira.data()['riskLevel'] ?? 'Medium',
      });
      continue;
    }
    final dra = await fs.tenantCollection('', 'dynamic_risk_assessments').doc(id).get();
    if (dra.exists) {
      risksList.add({
        'id': id,
        'type': 'DRA',
        'title': dra.data()['taskDescription'] ?? 'Unnamed DRA',
        'rating': dra.data()['isSafeToProceed'] == true ? 'Safe' : 'Action Required',
      });
      continue;
    }
    final strat = await fs.tenantCollection('', 'strategic_risks').doc(id).get();
    if (strat.exists) {
      risksList.add({
        'id': id,
        'type': 'Strategic',
        'title': strat.data()['title'] ?? 'Unnamed Strategic Risk',
        'rating': strat.data()['riskRating'] ?? 'Medium',
      });
    }
  }

  // 2. Fetch Permits (filtered by linked risk assessment IDs)
  if (riskAssessmentIds.isNotEmpty) {
    final permitSnap = await fs
        .tenantCollection('', 'permits')
        .where('siteId', isEqualTo: project.tenantId)
        .get();
    for (final doc in permitSnap.docs) {
      final pData = doc.data();
      final linkedRAId = pData['riskAssessmentId'] as String?;
      if (linkedRAId != null && riskAssessmentIds.contains(linkedRAId)) {
        permitsList.add(pData);
      }
    }
  }

  // 3. Fetch Action Items for this project
  final actionSnap = await fs
      .tenantCollection('', 'actionItems')
      .where('siteId', isEqualTo: project.tenantId)
      .where('sourceId', isEqualTo: project.id)
      .get();
  for (final doc in actionSnap.docs) {
    actionsList.add(doc.data());
  }

  return {'risks': risksList, 'permits': permitsList, 'actions': actionsList};
}
