import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import 'employee_ppe_profile_sheet.dart';
import 'ppe_inventory_details_sheet.dart';
import 'ppe_row.dart';

class PPEInspectionsList extends ConsumerWidget {
  final List<Map<String, dynamic>> records;
  final Function(String) onLogNewCheck;

  const PPEInspectionsList({
    super.key,
    required this.records,
    required this.onLogNewCheck,
  });

  void _showEmployeePPEProfile(
    BuildContext context,
    WidgetRef ref,
    String employeeName,
  ) {
    UIUtils.showSideSheet(
      context: context,
      title: 'PPE Profile: $employeeName',
      builder:
          (ctx) => EmployeePPEProfileSheet(
            employeeName: employeeName,
            onLogNewCheck: onLogNewCheck,
          ),
    );
  }

  void _showPPEInventoryDetails(
    BuildContext context,
    WidgetRef ref,
    String ppeType,
  ) {
    UIUtils.showSideSheet(
      context: context,
      title: 'PPE Inventory: $ppeType',
      builder: (ctx) => PPEInventoryDetailsSheet(ppeType: ppeType),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No PPE records found'),
        ),
      );
    }

    return Column(
      children:
          records
              .map(
                (r) => PPERow(
                  data: r,
                  onEmployeeTap: () {
                    _showEmployeePPEProfile(
                      context,
                      ref,
                      r['employeeName'] ?? '',
                    );
                  },
                  onPPETap: () {
                    _showPPEInventoryDetails(context, ref, r['ppeType'] ?? '');
                  },
                ),
              )
              .toList(),
    );
  }
}
