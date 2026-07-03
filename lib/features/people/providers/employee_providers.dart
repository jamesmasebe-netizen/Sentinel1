import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/app_providers.dart';
import '../models/employee.dart';
import 'package:xm_system/core/utils/tenant_firestore_extension.dart';

final employeesCollectionProvider = Provider<CollectionReference<Employee>>((
  ref,
) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .tenantCollection(ref.watch(currentTenantIdProvider) ?? "", 'employees')
      .withConverter<Employee>(
        fromFirestore:
            (snapshot, _) => Employee.fromMap(snapshot.data()!, snapshot.id),
        toFirestore: (employee, _) => employee.toMap(),
      );
});

final employeesProvider = StreamProvider<List<Employee>>((ref) {
  final collection = ref.watch(employeesCollectionProvider);
  return collection.snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
  );
});

class EmployeeService {
  final FirebaseFirestore _firestore;
  final String _tenantId;

  EmployeeService(this._firestore, this._tenantId);

  Future<void> updateEmployee(Employee employee) async {
    await _firestore
        .tenantCollection(_tenantId, 'employees')
        .doc(employee.id)
        .set(employee.toMap(), SetOptions(merge: true));
  }

  Future<String> createEmployee(Employee employee) async {
    final ref = _firestore.tenantCollection(_tenantId, 'employees').doc();
    final newEmployee = employee.copyWith(id: ref.id);
    await ref.set(newEmployee.toMap());
    return ref.id;
  }

  Future<void> seedDummyEmployeesIfEmpty() async {
    final query =
        await _firestore
            .tenantCollection(_tenantId, 'employees')
            .limit(1)
            .get();
    if (query.docs.isEmpty) {
      final dummies = [
        Employee(
          id: '',
          fullName: 'Alice Smith',
          email: 'alice@example.com',
          department: 'Engineering',
          jobTitle: 'Software Engineer',
          leaveBalance: 15.0,
          status: 'Active',
        ),
        Employee(
          id: '',
          fullName: 'Bob Johnson',
          email: 'bob@example.com',
          department: 'HR',
          jobTitle: 'HR Manager',
          leaveBalance: 20.0,
          status: 'Active',
        ),
        Employee(
          id: '',
          fullName: 'Charlie Davis',
          email: 'charlie@example.com',
          department: 'Operations',
          jobTitle: 'Operations Coordinator',
          leaveBalance: 10.0,
          status: 'Active',
        ),
      ];

      for (var emp in dummies) {
        await createEmployee(emp);
      }
    }
  }
}

final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return EmployeeService(
    ref.watch(firestoreProvider),
    ref.watch(currentTenantIdProvider) ?? '',
  );
});
