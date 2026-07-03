import 'package:flutter/material.dart';

class DispatcherBoardScreen extends StatelessWidget {
  const DispatcherBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatcher Board'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.warning, color: Colors.orange),
            tooltip: 'Emergency Alerts',
            onPressed: () {},
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Sidebar - Active Units
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.blueGrey.shade50,
                    child: Text(
                      'Active Units',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.engineering),
                          ),
                          title: Text('Team Alpha ${index + 1}'),
                          subtitle: const Text('Status: Available'),
                          trailing: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content - Map/Timeline Placeholder
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Live Map / Dispatch Timeline Placeholder',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom Panel - Unassigned Work Orders
                SizedBox(
                  height: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        color: Colors.red.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Unassigned Critical Work Orders',
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.warning,
                              color: Colors.red,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.assignment_late,
                                  color: Colors.orange,
                                ),
                                title: Text(
                                  'WO-2026-00${index + 1} - High Voltage Maintenance',
                                ),
                                subtitle: const Text(
                                  'Location: Substation B\nSafety PTW: Required before dispatch',
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('Assign'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
