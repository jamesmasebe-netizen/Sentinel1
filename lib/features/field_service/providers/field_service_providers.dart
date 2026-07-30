import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dispatcher.dart';
import '../models/field_service_models.dart';
import '../services/field_service_service.dart';


final dispatchersProvider = StateProvider<List<Dispatcher>>((ref) => []);
final workOrdersStreamProvider = StreamProvider<List<WorkOrder>>((ref) => ref.watch(fieldServiceServiceProvider).streamWorkOrders());

final territoriesStreamProvider = StreamProvider<List<Territory>>((ref) => ref.watch(fieldServiceServiceProvider).streamTerritories());
final incidentTypesStreamProvider = StreamProvider<List<IncidentType>>((ref) => ref.watch(fieldServiceServiceProvider).streamIncidentTypes());
final serviceTypesStreamProvider = StreamProvider<List<ServiceType>>((ref) => ref.watch(fieldServiceServiceProvider).streamServiceTypes());
final woSubstatusesStreamProvider = StreamProvider<List<WorkOrderSubstatus>>((ref) => ref.watch(fieldServiceServiceProvider).streamWorkOrderSubstatuses());
final agreementsStreamProvider = StreamProvider<List<Agreement>>((ref) => ref.watch(fieldServiceServiceProvider).streamAgreements());
final allCustomerAssetsStreamProvider = StreamProvider<List<CustomerAsset>>((ref) => ref.watch(fieldServiceServiceProvider).streamAllCustomerAssets());
