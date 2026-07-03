import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base class for all cross-module events in Sentinel
abstract class AppEvent {
  final DateTime timestamp;
  final String sourceModule;

  AppEvent({required this.sourceModule}) : timestamp = DateTime.now();
}

/// Examples of specific events
class EmployeeTerminatedEvent extends AppEvent {
  final String employeeId;
  final String employeeName;

  EmployeeTerminatedEvent({
    required this.employeeId,
    required this.employeeName,
    super.sourceModule = 'HR',
  });
}

class HighRiskIncidentReportedEvent extends AppEvent {
  final String incidentId;
  final String projectId;

  HighRiskIncidentReportedEvent({
    required this.incidentId,
    required this.projectId,
    super.sourceModule = 'Safety',
  });
}

/// The centralized Event Bus Provider
final appEventBusProvider = Provider<AppEventBus>((ref) {
  return AppEventBus();
});

class AppEventBus {
  final _controller = StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get stream => _controller.stream;

  void fire(AppEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
