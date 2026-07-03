import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../people/widgets/employee_selector.dart';

class IncidentBasicInfoFields extends StatelessWidget {
  final String? selectedReporterId;
  final ValueChanged<String?> onReporterChanged;
  final TextEditingController titleController;
  final TextEditingController descriptionController;

  const IncidentBasicInfoFields({
    super.key,
    required this.selectedReporterId,
    required this.onReporterChanged,
    required this.titleController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EmployeeSelector(
          value: selectedReporterId,
          onChanged: onReporterChanged,
          label: 'Reported By (Optional)',
        ),
        const SizedBox(height: XMTheme.spacingMd),
        TextFormField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Incident Title *',
            hintText: 'Brief description of what happened',
            prefixIcon: Icon(Icons.title),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: XMTheme.spacingMd),
        TextFormField(
          controller: descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Detailed Description *',
            hintText: 'Describe the incident in detail...',
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
