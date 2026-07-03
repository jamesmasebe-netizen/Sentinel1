import 'package:flutter/material.dart';
import '../../../../core/widgets/ds_widgets.dart';

class EmployeeFormCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController codeCtrl;
  final TextEditingController idCtrl;
  final TextEditingController titleCtrl;
  final TextEditingController deptCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const EmployeeFormCard({
    super.key,
    required this.nameCtrl,
    required this.codeCtrl,
    required this.idCtrl,
    required this.titleCtrl,
    required this.deptCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return GCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Employee',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            GSpacing.vMd,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name *'),
                  ),
                ),
                GSpacing.hMd,
                Expanded(
                  child: TextFormField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Employee Code *',
                    ),
                  ),
                ),
              ],
            ),
            GSpacing.vSm,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: idCtrl,
                    decoration: const InputDecoration(labelText: 'ID Number'),
                  ),
                ),
                GSpacing.hMd,
                Expanded(
                  child: TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Job Title'),
                  ),
                ),
              ],
            ),
            GSpacing.vSm,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(labelText: 'Department'),
                  ),
                ),
                GSpacing.hMd,
                Expanded(
                  child: TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ),
              ],
            ),
            GSpacing.vSm,
            TextFormField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            GSpacing.vMd,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSubmitting ? null : onSubmit,
                child: Text(isSubmitting ? 'Saving...' : 'Save Employee'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
