import 'package:flutter/material.dart';

class IncidentCostTrackingFields extends StatelessWidget {
  final TextEditingController directCostsController;
  final TextEditingController indirectCostsController;

  const IncidentCostTrackingFields({
    super.key,
    required this.directCostsController,
    required this.indirectCostsController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cost Tracking', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: directCostsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Direct Costs (R)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: indirectCostsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Indirect Costs (R)',
                  prefixIcon: Icon(Icons.money_off),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
