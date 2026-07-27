import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/customer_service_models.dart';
import '../services/customer_service_service.dart';

final articleFutureProvider = FutureProvider.family<KnowledgeArticle?, String>((
  ref,
  articleId,
) {
  final service = ref.watch(customerServiceServiceProvider);
  return service.getKnowledgeArticle(articleId);
});

class KnowledgeArticleDetailScreen extends ConsumerWidget {
  final String articleId;

  const KnowledgeArticleDetailScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(articleFutureProvider(articleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Article'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(articleFutureProvider(articleId));
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit action
            },
          ),
        ],
      ),
      body: articleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (article) {
          if (article == null) {
            return const Center(child: Text('Article not found'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildMainContent(context, article),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildMetadataPanel(context, article),
                      ),
                    ),
                  ],
                );
              } else {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainContent(context, article),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      _buildMetadataPanel(context, article),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, KnowledgeArticle article) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          article.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (article.summary != null && article.summary!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    article.summary!,
                    style: TextStyle(fontSize: 16, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        SelectableText(
          article.content ?? 'No content available.',
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataPanel(BuildContext context, KnowledgeArticle article) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Article Info',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildMetaRow('Article Number', article.articleNumber),
        _buildMetaRow('Status', article.status),
        _buildMetaRow('Approval Status', article.approvalStatus),
        _buildMetaRow('Version', 'v${article.version}'),
        _buildMetaRow('Language', article.language ?? 'en'),
        _buildMetaRow('Visibility', article.visibility),
        const SizedBox(height: 24),
        Text(
          'Dates',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildMetaRow(
          'Published At',
          article.publishedAt != null
              ? dateFormat.format(article.publishedAt!)
              : 'Not Published',
        ),
        _buildMetaRow(
          'Updated At',
          article.updatedAt != null
              ? dateFormat.format(article.updatedAt!)
              : 'N/A',
        ),
        _buildMetaRow(
          'Created At',
          article.createdAt != null
              ? dateFormat.format(article.createdAt!)
              : 'N/A',
        ),
        if (article.expirationDate != null)
          _buildMetaRow(
            'Expiration',
            dateFormat.format(article.expirationDate!),
          ),
        const SizedBox(height: 24),
        if (article.categories.isNotEmpty) ...[
          Text(
            'Categories',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                article.categories
                    .map(
                      (c) => Chip(
                        label: Text(c, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (article.tags.isNotEmpty) ...[
          Text(
            'Tags',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                article.tags
                    .map(
                      (t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.grey.shade200,
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          'Metrics',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (article.metrics.isEmpty)
          const Text(
            'No metrics available.',
            style: TextStyle(color: Colors.grey),
          )
        else
          ...article.metrics.entries.map(
            (e) => _buildMetaRow(e.key, e.value.toString()),
          ),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
