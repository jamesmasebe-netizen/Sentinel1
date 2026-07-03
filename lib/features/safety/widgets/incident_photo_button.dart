import 'package:flutter/material.dart';

class PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PhotoButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
