import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class IncidentLocationDateFields extends StatelessWidget {
  final TextEditingController locationController;
  final DateTime dateOfIncident;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onGpsPressed;

  const IncidentLocationDateFields({
    super.key,
    required this.locationController,
    required this.dateOfIncident,
    required this.onDateChanged,
    required this.onGpsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: locationController,
          decoration: InputDecoration(
            labelText: 'Location',
            hintText: 'Where did it happen?',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Use GPS',
              onPressed: onGpsPressed,
            ),
          ),
        ),
        const SizedBox(height: XMTheme.spacingMd),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today),
          title: const Text('Date of Incident'),
          subtitle: Text(
            '${dateOfIncident.day}/${dateOfIncident.month}/${dateOfIncident.year} ${dateOfIncident.hour}:${dateOfIncident.minute.toString().padLeft(2, '0')}',
          ),
          trailing: const Icon(Icons.edit),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: dateOfIncident,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null && context.mounted) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(dateOfIncident),
              );
              if (time != null) {
                onDateChanged(
                  DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
