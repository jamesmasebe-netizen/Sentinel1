import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'incident_photo_button.dart';

class IncidentPhotoCaptureSection extends StatelessWidget {
  final XFile? photoFile;
  final ValueChanged<ImageSource> onPickPhoto;
  final VoidCallback onRemovePhoto;

  const IncidentPhotoCaptureSection({
    super.key,
    required this.photoFile,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo Evidence',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            PhotoButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              onTap: () => onPickPhoto(ImageSource.camera),
            ),
            const SizedBox(width: 12),
            PhotoButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              onTap: () => onPickPhoto(ImageSource.gallery),
            ),
            if (photoFile != null) ...[
              const SizedBox(width: 12),
              Chip(
                avatar: const Icon(Icons.check, size: 16),
                label: const Text('Photo attached'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: onRemovePhoto,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
