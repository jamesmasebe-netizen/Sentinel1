import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../property/providers/property_providers.dart';

/// Optional property/site filter shared by the 3 emergency list tabs (contacts, drills,
/// equipment) — added 2026-08-12 alongside the propertyId field on all 3 models. Shows nothing
/// if the tenant has no properties recorded yet, rather than an empty/useless dropdown.
class PropertyFilterDropdown extends ConsumerWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const PropertyFilterDropdown({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesProvider).valueOrNull ?? [];
    if (properties.isEmpty) return const SizedBox.shrink();

    return DropdownButton<String?>(
      value: value,
      isDense: true,
      underline: const SizedBox(),
      hint: const Text('All sites', style: TextStyle(fontSize: 13)),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('All sites')),
        ...properties.map(
          (p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
