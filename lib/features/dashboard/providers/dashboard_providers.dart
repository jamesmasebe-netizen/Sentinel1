import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'package:sentinel1/core/utils/tenant_firestore_extension.dart';

// FIXED (this pass): every provider below used to return a hardcoded, fabricated value whenever
// its query returned zero documents (or there was no active tenant), instead of signaling "no data
// yet" — a direct violation of AGENTS.md §2's "No Hardcoded Data" rule. Each now returns null for
// that case (a genuinely empty collection still computes and returns a real, informative zero
// value — e.g. "0 incidents this month" — only the "we have no records at all yet" case returns
// null); the chart widgets in dashboard/widgets/ render GEmptyChartState (core/widgets/ds_widgets.dart)
// when they see null instead of drawing a chart around fake numbers.

final dashboardLtifrHistoryProvider = StreamProvider<List<double>?>((ref) {
  final siteId = ref.watch(currentTenantIdProvider);
  final firestore = ref.watch(firestoreProvider);
  if (siteId == null) return Stream.value(null);
  return firestore
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'incidents')
      .where('siteId', isEqualTo: siteId)
      .snapshots()
      .map((s) {
        final now = DateTime.now();
        final monthsCounts = List.filled(6, 0.0);

        for (final doc in s.docs) {
          final data = doc.data();
          final date =
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          final difference = now.difference(date).inDays ~/ 30;
          if (difference >= 0 && difference < 6) {
            monthsCounts[5 - difference] += 1.0;
          }
        }

        final total = monthsCounts.fold<double>(0, (s, v) => s + v);
        if (total == 0) return monthsCounts;

        return monthsCounts.map((v) => v * 10).toList();
      });
});

final dashboardOhsComplianceProvider = StreamProvider<double?>((ref) {
  final siteId = ref.watch(currentTenantIdProvider);
  final firestore = ref.watch(firestoreProvider);
  if (siteId == null) return Stream.value(null);
  return firestore
      .tenantCollection(
        ref.watch(currentTenantIdProvider) ?? "",
        'competency_passports',
      )
      .where('siteId', isEqualTo: siteId)
      .snapshots()
      .map((s) {
        if (s.docs.isEmpty) return null;
        final valid =
            s.docs
                .where(
                  (d) =>
                      d.data()['status'] == 'Valid' ||
                      d.data()['status'] == 'Expiring Soon',
                )
                .length;
        return (valid / s.docs.length) * 100;
      });
});

final dashboardHiraMatrixProvider = StreamProvider<List<int>?>((ref) {
  final siteId = ref.watch(currentTenantIdProvider);
  final firestore = ref.watch(firestoreProvider);

  if (siteId == null) return Stream.value(null);
  return firestore
      .tenantCollection(
        ref.watch(currentTenantIdProvider) ?? "",
        'risk_assessments',
      )
      .where('siteId', isEqualTo: siteId)
      .snapshots()
      .map((s) {
        if (s.docs.isEmpty) return null;
        final matrix = List.filled(25, 0);
        final likelihoodMap = {
          'rare': 0,
          'unlikely': 1,
          'possible': 2,
          'likely': 3,
          'almost certain': 4,
          'almost_certain': 4,
        };
        final severityMap = {
          'catastrophic': 0,
          'major': 1,
          'moderate': 2,
          'minor': 3,
          'negligible': 4,
        };

        for (final doc in s.docs) {
          final data = doc.data();
          final lStr =
              (data['likelihood'] ?? '').toString().toLowerCase().trim();
          final sStr = (data['severity'] ?? '').toString().toLowerCase().trim();
          final col = likelihoodMap[lStr] ?? 2;
          final row = severityMap[sStr] ?? 2;
          final idx = row * 5 + col;
          if (idx >= 0 && idx < 25) {
            matrix[idx]++;
          }
        }
        return matrix;
      });
});

final dashboardTrainingProvider = StreamProvider<Map<String, double>?>((ref) {
  final siteId = ref.watch(currentTenantIdProvider);
  final firestore = ref.watch(firestoreProvider);
  if (siteId == null) return Stream.value(null);
  return firestore
      .tenantCollection(
        ref.watch(currentTenantIdProvider) ?? "",
        'competency_passports',
      )
      .where('siteId', isEqualTo: siteId)
      .snapshots()
      .map((s) {
        if (s.docs.isEmpty) return null;
        final total = {'First Aid': 0, 'Fire Fighting': 0, 'SHE Rep': 0};
        final valid = {'First Aid': 0, 'Fire Fighting': 0, 'SHE Rep': 0};
        for (final doc in s.docs) {
          final data = doc.data();
          final cert = (data['certification'] ?? '').toString().toLowerCase();
          final status = (data['status'] ?? '').toString();
          String? category;
          if (cert.contains('first aid')) {
            category = 'First Aid';
          } else if (cert.contains('rigging') ||
              cert.contains('fire') ||
              cert.contains('forklift')) {
            category = 'Fire Fighting';
          } else if (cert.contains('she') || cert.contains('samtrac')) {
            category = 'SHE Rep';
          }
          if (category != null) {
            total[category] = total[category]! + 1;
            if (status == 'Valid' || status == 'Expiring Soon') {
              valid[category] = valid[category]! + 1;
            }
          }
        }
        return {
          'First Aid':
              total['First Aid'] == 0
                  ? 0.0
                  : (valid['First Aid']! / total['First Aid']!) * 100,
          'Fire Fighting':
              total['Fire Fighting'] == 0
                  ? 0.0
                  : (valid['Fire Fighting']! / total['Fire Fighting']!) * 100,
          'SHE Rep':
              total['SHE Rep'] == 0
                  ? 0.0
                  : (valid['SHE Rep']! / total['SHE Rep']!) * 100,
        };
      });
});

final dashboardCapaProvider = StreamProvider<Map<String, double>?>((ref) {
  final siteId = ref.watch(currentTenantIdProvider);
  final firestore = ref.watch(firestoreProvider);
  if (siteId == null) return Stream.value(null);
  return firestore
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'capas')
      .where('siteId', isEqualTo: siteId)
      .snapshots()
      .map((s) {
        if (s.docs.isEmpty) return null;
        final closed =
            s.docs.where((d) {
              final status = d.data()['status'] ?? '';
              return status == 'Closed' ||
                  status == 'Completed' ||
                  status == 'Resolved';
            }).length;
        final pctClosed = (closed / s.docs.length) * 100;
        final pctOpen = 100.0 - pctClosed;
        return {'closed': pctClosed, 'open': pctOpen};
      });
});

final dashboardWasteProvider = StreamProvider<Map<String, double>?>((ref) {
  final siteId = ref.watch(currentTenantIdProvider);
  final firestore = ref.watch(firestoreProvider);
  if (siteId == null) return Stream.value(null);
  return firestore
      .tenantCollection(
        ref.watch(currentTenantIdProvider) ?? "",
        'waste_manifests',
      )
      .where('siteId', isEqualTo: siteId)
      .snapshots()
      .map((s) {
        if (s.docs.isEmpty) return null;
        double recyclable = 0.0;
        double general = 0.0;
        double hazardous = 0.0;
        for (final doc in s.docs) {
          final data = doc.data();
          final type = (data['wasteType'] ?? '').toString().toLowerCase();
          final unit = (data['unit'] ?? '').toString().toLowerCase();
          double qty = (data['quantity'] as num?)?.toDouble() ?? 0.0;
          if (unit == 'kg') {
            qty /= 1000.0;
          }
          if (type.contains('recycle') || type.contains('recyclable')) {
            recyclable += qty;
          } else if (type.contains('general')) {
            general += qty;
          } else if (type.contains('haz')) {
            hazardous += qty;
          }
        }
        return {'Recycle': recyclable, 'General': general, 'Haz': hazardous};
      });
});

final dashboardIncidentHeatmapProvider =
    StreamProvider<List<Map<String, double>>>((ref) {
      final siteId = ref.watch(currentTenantIdProvider);
      final firestore = ref.watch(firestoreProvider);
      if (siteId == null) return Stream.value([]);
      return firestore
          .tenantCollection(
            ref.watch(currentTenantIdProvider) ?? "",
            'incidents',
          )
          .where('siteId', isEqualTo: siteId)
          .snapshots()
          .map((s) {
            final points = <Map<String, double>>[];
            for (final doc in s.docs) {
              final data = doc.data();
              final date =
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              final hour = date.hour + (date.minute / 60.0);
              final severity = (data['severity'] ?? 'Minor').toString();

              double xPct = (hour - 6.0) / 12.0;
              if (xPct < 0.0) xPct = 0.0;
              if (xPct > 1.0) xPct = 1.0;

              final day = date.weekday;
              double yPct = (day - 1.0) / 6.0;

              points.add({
                'x': xPct,
                'y': yPct,
                'isCritical':
                    severity == 'Critical' || severity == 'Major' ? 1.0 : 0.0,
              });
            }
            return points;
          });
    });
