import 'package:flutter/material.dart';
import 'new_project_dialog/new_project_dialog_content.dart';

class NewProjectDialog extends StatelessWidget {
  const NewProjectDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: const NewProjectDialogContent(),
      ),
    );
  }
}
