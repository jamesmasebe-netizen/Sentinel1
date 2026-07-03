import 'package:flutter/material.dart';

class AssetManagementScreen extends StatelessWidget {
  const AssetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enterprise Asset Management')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.business),
              title: Text('Property Management'),
              subtitle: Text('Manage real estate and facilities'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.precision_manufacturing),
              title: Text('Equipment Tracking'),
              subtitle: Text('Track machinery and heavy equipment'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.build_circle_outlined),
              title: Text('Preventative Maintenance'),
              subtitle: Text('Schedule and track maintenance tasks'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.history),
              title: Text('Asset Lifecycle'),
              subtitle: Text('Depreciation and lifecycle tracking'),
            ),
          ),
        ],
      ),
    );
  }
}
