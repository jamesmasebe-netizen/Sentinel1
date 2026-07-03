import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work_order.dart';
import '../models/dispatcher.dart';

final workOrdersProvider = StateProvider<List<WorkOrder>>((ref) => []);
final dispatchersProvider = StateProvider<List<Dispatcher>>((ref) => []);
