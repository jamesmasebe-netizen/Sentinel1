import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class CompetencyFormCard extends StatelessWidget {
  final TextEditingController employeeCtrl;
  final TextEditingController certCtrl;
  final TextEditingController issuerCtrl;
  final String status;
  final ValueChanged<String> onStatusChanged;
  final DateTime? expiryDate;
  final ValueChanged<DateTime?> onExpiryDateChanged;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const CompetencyFormCard({
    super.key,
    required this.employeeCtrl,
    required this.certCtrl,
    required this.issuerCtrl,
    required this.status,
    required this.onStatusChanged,
    required this.expiryDate,
    required this.onExpiryDateChanged,
    required this.isSubmitting,
    required this.onSubmit,
  });

  static const _statuses = ['Valid', 'Expiring Soon', 'Expired', 'Revoked'];

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Certification',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: employeeCtrl,
              decoration: const InputDecoration(
                labelText: 'Employee Name *',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: certCtrl,
              decoration: const InputDecoration(
                labelText: 'Certification / Competency *',
                prefixIcon: Icon(Icons.card_membership),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: issuerCtrl,
              decoration: const InputDecoration(
                labelText: 'Issuing Body',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items:
                        _statuses
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
                    onChanged: (v) => onStatusChanged(v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 1825),
                        ),
                      );
                      if (date != null) onExpiryDateChanged(date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        expiryDate != null
                            ? _formatDate(expiryDate!.toIso8601String())
                            : 'Select date',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              expiryDate != null
                                  ? null
                                  : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon:
                    isSubmitting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save),
                label: Text(isSubmitting ? 'Saving...' : 'Add Certification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
