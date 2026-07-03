import 'package:flutter/material.dart';
import '../../../../core/widgets/ds_widgets.dart';

class EmployeeFilters extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final String filterStatus;
  final ValueChanged<String?> onStatusChanged;
  final String filterDept;
  final ValueChanged<String?> onDeptChanged;

  const EmployeeFilters({
    super.key,
    required this.onSearchChanged,
    required this.filterStatus,
    required this.onStatusChanged,
    required this.filterDept,
    required this.onDeptChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextFormField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search name or code...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          GSpacing.vSm,
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filterStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items:
                      ['All', 'Active', 'On Leave', 'Inactive', 'Terminated']
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: onStatusChanged,
                ),
              ),
              GSpacing.hMd,
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filterDept,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items:
                      [
                            'All',
                            'Operations',
                            'Safety',
                            'Engineering',
                            'Admin',
                            'HR',
                          ]
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: onDeptChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
