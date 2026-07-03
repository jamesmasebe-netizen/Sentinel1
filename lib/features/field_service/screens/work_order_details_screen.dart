import 'package:flutter/material.dart';

class WorkOrderDetailsScreen extends StatelessWidget {
  final String workOrderId;

  const WorkOrderDetailsScreen({super.key, required this.workOrderId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Work Order: $workOrderId'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Details', icon: Icon(Icons.info_outline)),
              Tab(text: 'Safety & Hazards', icon: Icon(Icons.security)),
              Tab(text: 'Tasks', icon: Icon(Icons.checklist)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Details
            _buildDetailsTab(),
            // Tab 2: Safety & Hazards
            _buildSafetyTab(context),
            // Tab 3: Tasks
            _buildTasksTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        ListTile(
          title: Text('Description'),
          subtitle: Text(
            'Perform detailed inspection and replace faulty components on Turbine 4 as part of scheduled maintenance.',
          ),
        ),
        Divider(),
        ListTile(
          title: Text('Location'),
          subtitle: Text('Sector 7, North Wing, Level 3'),
          leading: Icon(Icons.location_on),
        ),
        Divider(),
        ListTile(
          title: Text('Priority'),
          subtitle: Text('High'),
          leading: Icon(Icons.priority_high, color: Colors.red),
        ),
      ],
    );
  }

  Widget _buildSafetyTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          color: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.red.shade200, width: 2),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Permit To Work (PTW) Required',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Before proceeding with this work order, a certified Safety PTW must be filled and approved. This work involves high voltage and confined spaces.',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Trigger PTW Checklist flow
                    },
                    icon: const Icon(Icons.assignment),
                    label: const Text('Complete Safety PTW Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Identified Hazards',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildHazardItem(
          'High Voltage',
          'Ensure power is isolated and LOTO (Lockout/Tagout) procedures are followed.',
        ),
        _buildHazardItem(
          'Confined Space',
          'Adequate ventilation required. Confined space entry permit needed.',
        ),
        _buildHazardItem(
          'Working at Heights',
          'Fall protection gear (harness) mandatory.',
        ),
      ],
    );
  }

  Widget _buildHazardItem(String title, String description) {
    return ListTile(
      leading: const Icon(Icons.dangerous, color: Colors.orange),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(description),
    );
  }

  Widget _buildTasksTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        CheckboxListTile(
          value: false,
          onChanged: (bool? value) {},
          title: const Text('Isolate main power supply'),
        ),
        CheckboxListTile(
          value: false,
          onChanged: (bool? value) {},
          title: const Text('Remove access panels'),
        ),
        CheckboxListTile(
          value: false,
          onChanged: (bool? value) {},
          title: const Text('Inspect rotor assembly'),
        ),
      ],
    );
  }
}
