import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/utils/ui_utils.dart';
import '../providers/property_providers.dart';
import '../models/property_models.dart';
import 'property_project_form.dart';
import 'legal_appointment_form.dart';

class PropertyFacilityTab extends ConsumerWidget {
  final Property property;
  const PropertyFacilityTab({super.key, required this.property});

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: XMTheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, color: XMTheme.primary),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(PropertyProject project) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: XMTheme.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.settings_suggest_outlined,
                color: XMTheme.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${project.type} • Assigned to ${project.assigneeId}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${project.progress}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: XMTheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  project.status,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(LegalAppointment appointment) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: XMTheme.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: XMTheme.success, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appointment.role,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    appointment.personId,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              color:
                  appointment.status == 'Appointed'
                      ? XMTheme.success
                      : XMTheme.warning,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(propertyProjectsProvider(property.id));
    final appointmentsAsync = ref.watch(
      propertyAppointmentsProvider(property.id),
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader(
          context,
          'Facility Projects & Maintenance',
          Icons.build_circle_outlined,
          () => UIUtils.showSideSheet(
            context: context,
            title: 'New Facility Project',
            builder: (_) => PropertyProjectForm(propertyId: property.id),
          ),
        ),
        projectsAsync.when(
          data:
              (projects) => Column(
                children: projects.map((p) => _buildProjectCard(p)).toList(),
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error: $err'),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader(
          context,
          'Legal Appointments',
          Icons.verified_user_outlined,
          () => UIUtils.showSideSheet(
            context: context,
            title: 'New Legal Appointment',
            builder: (_) => LegalAppointmentForm(propertyId: property.id),
          ),
        ),
        appointmentsAsync.when(
          data:
              (appointments) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3,
                ),
                itemCount: appointments.length,
                itemBuilder:
                    (context, index) =>
                        _buildAppointmentCard(appointments[index]),
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error: $err'),
        ),
      ],
    );
  }
}
