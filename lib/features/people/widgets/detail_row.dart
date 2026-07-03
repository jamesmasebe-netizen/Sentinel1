import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const DetailRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: XMTheme.secondaryLight),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: XMTheme.secondaryLight, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
