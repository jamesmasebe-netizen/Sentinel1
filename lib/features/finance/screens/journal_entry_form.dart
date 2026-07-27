import 'package:flutter/material.dart';
import '../widgets/journal_entry_form.dart' as widget_form;

class JournalEntryForm extends StatelessWidget {
  const JournalEntryForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Journal Entry')),
      body: const widget_form.JournalEntryForm(),
    );
  }
}
