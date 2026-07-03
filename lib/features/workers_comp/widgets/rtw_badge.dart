import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ds_widgets.dart';

class RtwBadge extends StatelessWidget {
  final String label;

  const RtwBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final color =
        label == 'Full Duty'
            ? XMTheme.success
            : label == 'Light Duty'
            ? XMTheme.warning
            : XMTheme.error;
    return GStatusTag(label: label, color: color);
  }
}
