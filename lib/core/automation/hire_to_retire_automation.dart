import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/people/services/hr_service.dart';
import '../../features/field_service/services/field_service_service.dart';
import '../../features/field_service/models/field_service_models.dart';

final hireToRetireAutomationProvider = Provider<HireToRetireAutomationService>((
  ref,
) {
  final hrService = ref.watch(hrServiceProvider);
  final fieldService = ref.watch(fieldServiceServiceProvider);
  return HireToRetireAutomationService(hrService, fieldService);
});

class HireToRetireAutomationService {
  final HRService hrService;
  final FieldServiceService fieldService;

  HireToRetireAutomationService(this.hrService, this.fieldService);

  /// Checks whether a technician is eligible for field service assignments.
  /// Returns false if the employee is onboarding or missing mandatory safety training.
  Future<bool> canAssignTechnician(String technicianId) async {
    final employee = await hrService.getEmployee(technicianId);
    if (employee == null) return false;

    if (employee.missingMandatorySafetyTraining ||
        employee.employmentStatus.toUpperCase() == 'ONBOARDING') {
      return false;
    }
    return true;
  }

  /// Safely assigns a route to a technician, applying Hire-to-Retire constraints.
  /// Throws an exception if the technician is missing mandatory safety training
  /// or is currently onboarding.
  Future<void> safeAssignRoute(
    String technicianId,
    DispatcherRoute route,
  ) async {
    final isEligible = await canAssignTechnician(technicianId);
    if (!isEligible) {
      throw Exception(
        'Technician is not eligible for field service assignments '
        '(missing mandatory safety training or currently onboarding).',
      );
    }

    final updatedRoute = DispatcherRoute(
      id: route.id,
      technicianId: technicianId,
      date: route.date,
      status: route.status,
      startLocation: route.startLocation,
      endLocation: route.endLocation,
      metrics: route.metrics,
      generatedBy: route.generatedBy,
      createdAt: route.createdAt,
      updatedAt: route.updatedAt,
    );

    if (updatedRoute.id.isEmpty) {
      await fieldService.createRoutePlan(updatedRoute);
    } else {
      await fieldService.updateRoutePlan(updatedRoute);
    }
  }

  /// Automatically validates all routes for a given technician.
  /// This could be used by a background listener or periodic sync to
  /// unassign technicians who fall out of compliance.
  Future<void> auditTechnicianRoutes(String technicianId) async {
    final isEligible = await canAssignTechnician(technicianId);

    // If the technician is still eligible, no action needed.
    if (isEligible) return;

    // Otherwise, find all their routes and potentially unassign them.
    // Assuming streamRoutePlansForTechnician provides the routes, we take the first snapshot.
    final routesStream = fieldService.streamRoutePlansForTechnician(
      technicianId,
    );
    final routes = await routesStream.first;

    for (final route in routes) {
      // Unassign the technician by setting technicianId to empty and perhaps status to 'UNASSIGNED'
      final unassignedRoute = DispatcherRoute(
        id: route.id,
        technicianId: '', // Removing the assignment
        date: route.date,
        status: 'UNASSIGNED',
        startLocation: route.startLocation,
        endLocation: route.endLocation,
        metrics: route.metrics,
        generatedBy: route.generatedBy,
        createdAt: route.createdAt,
        updatedAt: route.updatedAt,
      );

      await fieldService.updateRoutePlan(unassignedRoute);
    }
  }
}
