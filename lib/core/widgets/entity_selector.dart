import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EntitySelector<T> extends StatelessWidget {
  final AsyncValue<List<T>> asyncEntities;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String Function(T) idMapper;
  final String Function(T) displayMapper;
  final String? Function(String?)? validator;

  const EntitySelector({
    super.key,
    required this.asyncEntities,
    required this.value,
    required this.onChanged,
    required this.idMapper,
    required this.displayMapper,
    this.label = 'Select Entity',
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return asyncEntities.when(
      data: (entities) {
        if (entities.isEmpty) {
          return DropdownButtonFormField<String>(
            value: null,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            items: const [],
            onChanged: null,
            hint: const Text('No records found'),
          );
        }
        
        // Use DropdownButtonFormField for consistency with EmployeeSelector
        return DropdownButtonFormField<String>(
          value: value != null && entities.any((e) => idMapper(e) == value)
              ? value
              : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: entities.map((e) {
            return DropdownMenuItem(
              value: idMapper(e),
              child: Text(displayMapper(e)),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: DropdownButtonFormField<String>(
            value: null,
            decoration: InputDecoration(
              labelText: '$label (Loading...)',
              border: const OutlineInputBorder(),
            ),
            items: const [],
            onChanged: null,
        ),
      ),
      error: (e, st) => Text('Error loading $label: $e'),
    );
  }
}
