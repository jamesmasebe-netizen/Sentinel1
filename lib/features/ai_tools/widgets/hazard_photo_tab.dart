import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme.dart';
import '../providers/gemini_provider.dart';
import 'hazard_photo_widgets.dart';

class HazardPhotoTab extends ConsumerStatefulWidget {
  const HazardPhotoTab({super.key});
  @override
  ConsumerState<HazardPhotoTab> createState() => _HazardPhotoState();
}

class _HazardPhotoState extends ConsumerState<HazardPhotoTab> {
  File? _image;
  String _result = '';
  bool _loading = false;

  Future<void> _pick(ImageSource src) async {
    final picked = await ImagePicker().pickImage(source: src, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _result = '';
      });
    }
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() => _loading = true);
    try {
      final model = ref.read(geminiProvider);
      final bytes = await _image!.readAsBytes();
      final resp = await model.generateContent([
        Content.multi([
          TextPart(
            'You are a workplace safety inspector. Analyze this image and identify: 1) All visible hazards (classify each as Critical/High/Medium/Low risk), 2) Non-compliances with OHS standards, 3) Recommended immediate corrective actions, 4) PPE requirements for this area. Format your response clearly with headers.',
          ),
          DataPart('image/jpeg', bytes),
        ]),
      ]);
      if (mounted) {
        setState(() => _result = resp.text ?? 'No analysis returned');
      }
    } catch (e) {
      if (mounted) setState(() => _result = 'Analysis error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          const HazardPhotoHeader(),
          const SizedBox(height: 16),
          // Image picker
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Take Photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('From Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _image!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _analyze,
                icon:
                    _loading
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.search, size: 18),
                label: Text(
                  _loading ? 'Analyzing hazards…' : 'Analyze for Hazards',
                ),
                style: FilledButton.styleFrom(backgroundColor: XMTheme.warning),
              ),
            ),
          ],
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 16),
            AIHazardReport(result: _result),
          ],
          if (_image == null) const EmptyPhotoView(),
        ],
      ),
    );
  }
}
