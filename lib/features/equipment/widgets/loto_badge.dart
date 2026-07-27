import 'package:flutter/material.dart';

class LotoBadge extends StatelessWidget {
  final String status;
  final String? lockoutReason;

  const LotoBadge({
    super.key,
    required this.status,
    this.lockoutReason,
  });

  @override
  Widget build(BuildContext context) {
    if (status != 'Locked Out') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            lockoutReason != null ? 'LOCKED OUT: $lockoutReason' : 'LOCKED OUT',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
