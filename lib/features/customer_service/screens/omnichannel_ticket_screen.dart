import 'package:flutter/material.dart';

class OmnichannelTicketScreen extends StatefulWidget {
  const OmnichannelTicketScreen({super.key});

  @override
  State<OmnichannelTicketScreen> createState() =>
      _OmnichannelTicketScreenState();
}

class _OmnichannelTicketScreenState extends State<OmnichannelTicketScreen> {
  int _selectedTicketIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Omnichannel Ticketing')),
      body: Row(
        children: [
          // Queue (Left Pane)
          SizedBox(
            width: 350,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.grey.shade200,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Queue',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.filter_list),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 15,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedTicketIndex;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                        leading: CircleAvatar(child: Text('U${index + 1}')),
                        title: Text('User ${index + 1}'),
                        subtitle: const Text('Need help with...'),
                        trailing: const Text(
                          '2m ago',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedTicketIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Ticket Details & Chat (Right Pane)
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ticket #${2000 + _selectedTicketIndex}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Status: Open • Channel: Web Chat',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.check),
                            label: const Text('Resolve'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.person_add),
                            label: const Text('Transfer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      final isAgent = index % 2 != 0;
                      return Align(
                        alignment:
                            isAgent
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          padding: const EdgeInsets.all(12.0),
                          constraints: const BoxConstraints(maxWidth: 400),
                          decoration: BoxDecoration(
                            color:
                                isAgent
                                    ? Colors.blue.shade100
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAgent
                                ? 'Hello! I am reviewing your issue now. Please give me a moment.'
                                : 'Hi, I am unable to access my account. It says invalid credentials.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () {},
                      ),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Type a message or use / for macros...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () {},
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
