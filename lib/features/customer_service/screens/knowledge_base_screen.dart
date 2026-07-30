import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/customer_service_service.dart';
import '../widgets/knowledge_article_form.dart';
import 'knowledge_article_detail_screen.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:intl/intl.dart';

class KnowledgeBaseScreen extends ConsumerStatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  ConsumerState<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends ConsumerState<KnowledgeBaseScreen> {
  static const _categories = [
    ('Getting Started', Icons.article),
    ('Account Management', Icons.account_circle),
    ('Billing & Payments', Icons.payment),
    ('Security & Privacy', Icons.security),
    ('Troubleshooting', Icons.build),
  ];

  String _selectedCategory = _categories.first.$1;

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
                for (final (name, icon) in _categories)
                  ListTile(
                    leading: Icon(icon),
                    title: Text(name),
                    selected: _selectedCategory == name,
                    onTap: () => setState(() => _selectedCategory = name),
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
                    'Articles in "$_selectedCategory"',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ref.watch(knowledgeArticlesProvider).when(
                      data: (allArticles) {
                        final articles = allArticles
                            .where((a) => a.categories.contains(_selectedCategory))
                            .toList();
                        if (articles.isEmpty) {
                          return Center(
                            child: Text('No articles found in "$_selectedCategory".'),
                          );
                        }
                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 3 / 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: articles.length,
                          itemBuilder: (context, index) {
                            final article = articles[index];
                            return Card(
                              elevation: 2,
                              child: InkWell(
                                onTap: () {
                                  UIUtils.showSideSheet(
                                    context: context,
                                    title: article.title,
                                    builder: (_) => KnowledgeArticleDetailScreen(articleId: article.id),
                                  );
                                },
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
                                        article.title,
                                        style:
                                            Theme.of(context).textTheme.titleMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        article.updatedAt != null
                                            ? 'Last updated ${DateFormat.yMMMd().format(article.updatedAt!)}'
                                            : 'Not yet updated',
                                        style: const TextStyle(
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
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text('Error: $e')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          UIUtils.showSideSheet(
            context: context,
            title: 'New Article',
            builder: (_) => const KnowledgeArticleForm(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
