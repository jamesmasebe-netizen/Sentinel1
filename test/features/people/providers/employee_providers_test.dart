// Tests for EmployeeService (lib/features/people/providers/employee_providers.dart)
// — the real, tenant-scoped employee CRUD used by employee_hub_screen.dart
// and friends (not to be confused with hr_provider.dart's unreachable,
// root-collection-querying HRService — see hr_service_test.dart's header).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel1/features/people/models/employee.dart';
import 'package:sentinel1/features/people/providers/employee_providers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late EmployeeService service;
  const tenantId = 'tenant-emp-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = EmployeeService(firestore, tenantId);
  });

  Employee buildEmployee({String id = '', String status = 'Active'}) {
    return Employee(
      id: id,
      fullName: 'Test Employee',
      email: 'test@example.com',
      department: 'Engineering',
      jobTitle: 'Engineer',
      leaveBalance: 15.0,
      status: status,
    );
  }

  group('createEmployee', () {
    test('writes to the tenant-scoped employees collection with a real generated id', () async {
      final id = await service.createEmployee(buildEmployee());

      expect(id, isNotEmpty);
      final doc = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('employees')
          .doc(id)
          .get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['fullName'], 'Test Employee');
      // The document's own id field must match the real Firestore doc id,
      // not be left blank from the input model's placeholder id: ''.
      expect(doc.data()!['id'], id);
    });
  });

  group('updateEmployee', () {
    test('merges fields into an existing employee doc', () async {
      final id = await service.createEmployee(buildEmployee());
      final updated = buildEmployee(id: id, status: 'Suspended');

      await service.updateEmployee(updated);

      final doc = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('employees')
          .doc(id)
          .get();
      expect(doc.data()!['status'], 'Suspended');
    });
  });

  group('seedDummyEmployeesIfEmpty', () {
    test('seeds 3 dummy employees when the collection is empty', () async {
      await service.seedDummyEmployeesIfEmpty();

      final docs = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('employees')
          .get();
      expect(docs.docs, hasLength(3));
    });

    test('does nothing when the collection already has an employee', () async {
      await service.createEmployee(buildEmployee());

      await service.seedDummyEmployeesIfEmpty();

      final docs = await firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('employees')
          .get();
      expect(docs.docs, hasLength(1));
    });
  });
}
