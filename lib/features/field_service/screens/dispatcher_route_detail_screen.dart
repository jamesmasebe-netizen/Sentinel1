import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/field_service_models.dart';
import '../services/field_service_service.dart';

class DispatcherRouteDetailScreen extends ConsumerWidget {
  final String routeId;

  const DispatcherRouteDetailScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(fieldServiceServiceProvider);

    return StreamBuilder<DispatcherRoute?>(
      stream: service.streamRoutePlan(routeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final route = snapshot.data;
        if (route == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Route Plan Details')),
            body: const Center(child: Text('Route Plan not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Route Details'), elevation: 0),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, route),
                const SizedBox(height: 24),
                _buildMetricsSection(route),
                const SizedBox(height: 24),
                _buildLocationSection(route),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DispatcherRoute route) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.route,
                    size: 30,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Technician: ${route.technicianId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${route.status}',
                        style: TextStyle(
                          color:
                              route.status == 'ACTIVE'
                                  ? Colors.green
                                  : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (route.date != null) ...[
              const Divider(height: 32),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${DateFormat.yMMMd().format(route.date!)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection(DispatcherRoute route) {
    if (route.metrics == null || route.metrics!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metrics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              route.metrics!.entries.map((e) {
                return Chip(
                  label: Text('${e.key}: ${e.value}'),
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationSection(DispatcherRoute route) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Locations',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (route.startLocation != null)
          ListTile(
            leading: const Icon(Icons.my_location, color: Colors.green),
            title: const Text('Start Location'),
            subtitle: Text(
              '${route.startLocation!.latitude}, ${route.startLocation!.longitude}',
            ),
            tileColor: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        if (route.endLocation != null) ...[
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.red),
            title: const Text('End Location'),
            subtitle: Text(
              '${route.endLocation!.latitude}, ${route.endLocation!.longitude}',
            ),
            tileColor: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ],
    );
  }
}
