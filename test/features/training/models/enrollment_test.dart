// Tests for Enrollment (lib/features/training/models/enrollment.dart) — unified 2026-08-12 onto
// one collection covering both self-paced and manager-assigned course progress, discriminated by
// [source]. Focused on the new fields this unification added.
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/training/models/enrollment.dart';

void main() {
  group('toMap/fromMap round-trip', () {
    test('self-paced enrollment: optional manager-assigned fields are omitted from toMap', () {
      final enrollment = Enrollment(
        id: 'enr-1',
        courseId: 'course-1',
        employeeId: 'emp-1',
        enrollmentDate: DateTime(2026, 1, 1),
      );

      final map = enrollment.toMap();

      expect(map['source'], 'self_paced');
      expect(map.containsKey('employeeName'), isFalse);
      expect(map.containsKey('courseName'), isFalse);
      expect(map.containsKey('dueDate'), isFalse);
      expect(map.containsKey('assignedAt'), isFalse);
    });

    test('manager-assigned enrollment: full shape round-trips through fromMap', () {
      final original = Enrollment(
        id: 'enr-2',
        courseId: 'course-2',
        employeeId: 'emp-2',
        employeeName: 'Jane Doe',
        courseName: 'Working at Heights',
        status: 'Assigned',
        source: 'manager_assigned',
        enrollmentDate: DateTime(2026, 1, 1),
        dueDate: DateTime(2026, 2, 1),
        assignedAt: DateTime(2026, 1, 1),
        authorId: 'manager-1',
        siteId: 'tenant-1',
      );

      final restored = Enrollment.fromMap(original.toMap(), 'enr-2');

      expect(restored.source, 'manager_assigned');
      expect(restored.employeeName, 'Jane Doe');
      expect(restored.courseName, 'Working at Heights');
      expect(restored.status, 'Assigned');
      expect(restored.dueDate, DateTime(2026, 2, 1));
      expect(restored.assignedAt, DateTime(2026, 1, 1));
      expect(restored.authorId, 'manager-1');
      expect(restored.siteId, 'tenant-1');
    });

    test('fromMap defaults source to self_paced when absent (pre-unification documents)', () {
      final restored = Enrollment.fromMap({
        'courseId': 'course-3',
        'employeeId': 'emp-3',
        'enrollmentDate': DateTime(2026, 1, 1).toIso8601String(),
      }, 'enr-3');

      expect(restored.source, 'self_paced');
    });
  });
}
