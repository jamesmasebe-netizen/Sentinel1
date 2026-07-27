import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_service_models.dart';
import '../services/customer_service_service.dart';

class KnowledgeArticleForm extends ConsumerStatefulWidget {
  final KnowledgeArticle? initialArticle;
  final VoidCallback? onSaved;

  const KnowledgeArticleForm({super.key, this.initialArticle, this.onSaved});

  @override
  ConsumerState<KnowledgeArticleForm> createState() =>
      _KnowledgeArticleFormState();
}

class _KnowledgeArticleFormState extends ConsumerState<KnowledgeArticleForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _summaryController;
  late TextEditingController _articleNumberController;

  String _status = 'Draft';
  String _approvalStatus = 'Pending';
  String _visibility = 'Internal';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialArticle?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.initialArticle?.content ?? '',
    );
    _summaryController = TextEditingController(
      text: widget.initialArticle?.summary ?? '',
    );
    _articleNumberController = TextEditingController(
      text:
          widget.initialArticle?.articleNumber ??
          'KA-${DateTime.now().millisecondsSinceEpoch}',
    );

    _status = widget.initialArticle?.status ?? 'Draft';
    _approvalStatus = widget.initialArticle?.approvalStatus ?? 'Pending';
    _visibility = widget.initialArticle?.visibility ?? 'Internal';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _summaryController.dispose();
    _articleNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(customerServiceServiceProvider);

      final article = KnowledgeArticle(
        id: widget.initialArticle?.id ?? '',
        articleNumber: _articleNumberController.text,
        title: _titleController.text,
        content: _contentController.text,
        summary: _summaryController.text,
        status: _status,
        approvalStatus: _approvalStatus,
        visibility: _visibility,
        createdAt: widget.initialArticle?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.initialArticle == null) {
        await service.createKnowledgeArticle(article);
      } else {
        await service.updateKnowledgeArticle(article);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Knowledge Article saved successfully')),
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving article: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _articleNumberController,
            decoration: const InputDecoration(
              labelText: 'Article Number',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) =>
                    value == null || value.isEmpty
                        ? 'Article Number is required'
                        : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _summaryController,
            decoration: const InputDecoration(
              labelText: 'Summary',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Content',
              border: OutlineInputBorder(),
            ),
            maxLines: 8,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      ['Draft', 'Review', 'Published', 'Archived']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _status = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _approvalStatus,
                  decoration: const InputDecoration(
                    labelText: 'Approval Status',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      ['Pending', 'Approved', 'Rejected']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged:
                      (value) => setState(() => _approvalStatus = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _visibility,
            decoration: const InputDecoration(
              labelText: 'Visibility',
              border: OutlineInputBorder(),
            ),
            items:
                ['Internal', 'Public', 'Customer Only']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
            onChanged: (value) => setState(() => _visibility = value!),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveArticle,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Save Knowledge Article'),
          ),
        ],
      ),
    );
  }
}
