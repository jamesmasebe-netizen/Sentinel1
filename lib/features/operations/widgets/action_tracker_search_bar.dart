import 'package:flutter/material.dart';
import '../../../core/widgets/ds_widgets.dart';

class ActionTrackerSearchBar extends StatelessWidget {
  final String searchValue;
  final ValueChanged<String> onSearchChanged;
  final String filterValue;
  final ValueChanged<String> onFilterChanged;

  const ActionTrackerSearchBar({
    super.key,
    required this.searchValue,
    required this.onSearchChanged,
    required this.filterValue,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: searchValue,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search actions...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          GSpacing.hMd,
          DropdownButton<String>(
            value: filterValue,
            underline: const SizedBox(),
            items:
                ['All', 'Pending', 'In Progress', 'Open', 'Completed', 'Closed']
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
            onChanged: (v) {
              if (v != null) onFilterChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
