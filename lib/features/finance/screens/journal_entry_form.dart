import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_entry.dart';
import '../providers/finance_providers.dart';

class JournalEntryForm extends ConsumerStatefulWidget {
  const JournalEntryForm({super.key});

  @override
  ConsumerState<JournalEntryForm> createState() => _JournalEntryFormState();
}

class _JournalEntryFormState extends ConsumerState<JournalEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _accountIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _accountIdController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newEntry = JournalEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        accountId: _accountIdController.text,
        amount: double.parse(_amountController.text),
        date: DateTime.now(),
        description: _descriptionController.text,
      );

      ref
          .read(journalEntriesProvider.notifier)
          .update((state) => [...state, newEntry]);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Journal Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _accountIdController,
                decoration: const InputDecoration(labelText: 'Account ID'),
                validator:
                    (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator:
                    (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
