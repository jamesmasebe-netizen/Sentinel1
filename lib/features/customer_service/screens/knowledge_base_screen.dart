import 'package:flutter/material.dart';

class KnowledgeBaseScreen extends StatelessWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Knowledge Base')),
      body: Row(
        children: [
          // Sidebar categories
          SizedBox(
            width: 250,
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Categories',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.article),
                  title: const Text('Getting Started'),
                  selected: true,
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: const Text('Account Management'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Billing & Payments'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Security & Privacy'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.build),
                  title: const Text('Troubleshooting'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search knowledge base...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Popular Articles in "Getting Started"',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 3 / 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 2,
                          child: InkWell(
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.menu_book,
                                    color: Colors.blue,
                                    size: 32,
                                  ),
                                  const Spacer(),
                                  Text(
                                    'How to setup your account - Part ${index + 1}',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Last updated 2 days ago',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
