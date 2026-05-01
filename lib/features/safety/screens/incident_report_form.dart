import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';


/// Full incident reporting form — matches React IncidentsCAPA component.
/// Includes: form fields, photo capture, AI classification (placeholder),
/// GPS location, anonymous reporting, cost tracking, dynamic sub-fields.
class IncidentReportForm extends ConsumerStatefulWidget {
  const IncidentReportForm({super.key});

  @override
  ConsumerState<IncidentReportForm> createState() => _IncidentReportFormState();
}

class _IncidentReportFormState extends ConsumerState<IncidentReportForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isAnonymous = false;

  // Form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _type = 'Injury';
  String _severity = 'Minor';
  DateTime _dateOfIncident = DateTime.now();
  String? _selectedContractorId;
  XFile? _photoFile;


  // Cost tracking
  final _directCostsController = TextEditingController(text: '0');
  final _indirectCostsController = TextEditingController(text: '0');

  // Injury sub-fields
  final _bodyPartController = TextEditingController();
  String _treatmentType = 'First Aid';

  // Environmental sub-fields
  final _substanceController = TextEditingController();
  final _volumeController = TextEditingController();
  String _envUnit = 'Liters';

  // Property damage sub-fields
  final _assetIdController = TextEditingController();
  final _damageEstimateController = TextEditingController(text: '0');

  static const _types = ['Injury', 'Near Miss', 'Property Damage', 'Environmental', 'Hazard Observation'];
  static const _severities = ['Minor', 'Moderate', 'Major', 'Critical'];
  static const _treatments = ['First Aid', 'Medical Treatment', 'Hospitalization', 'Fatality'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _directCostsController.dispose();
    _indirectCostsController.dispose();
    _bodyPartController.dispose();
    _substanceController.dispose();
    _volumeController.dispose();
    _assetIdController.dispose();
    _damageEstimateController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 80);
    if (photo != null) {
      setState(() { _photoFile = photo; });
      // TODO: AI photo analysis via Gemini in Phase 6
    }
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');

      // Upload photo if present
      String? photoUrl;
      if (_photoFile != null) {
        final storageRef = FirebaseStorage.instance.ref()
            .child('incidents/${DateTime.now().millisecondsSinceEpoch}_${_photoFile!.name}');
        await storageRef.putFile(File(_photoFile!.path));
        photoUrl = await storageRef.getDownloadURL();
      }

      final directCosts = double.tryParse(_directCostsController.text) ?? 0;
      final indirectCosts = double.tryParse(_indirectCostsController.text) ?? 0;

      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _type,
        'severity': _severity,
        'location': _locationController.text.trim(),
        'status': 'Open',
        'reporterId': _isAnonymous ? 'anonymous' : profile.uid,
        'reporterName': _isAnonymous ? 'Anonymous Whistleblower' : profile.displayName,
        'siteId': profile.siteId,
        'contractorId': _selectedContractorId,
        'dateOfIncident': _dateOfIncident.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'photoUrl': photoUrl,
        'isAnonymous': _isAnonymous,
        'directCosts': directCosts,
        'indirectCosts': indirectCosts,
        'totalCost': directCosts + indirectCosts,
      };

      // Dynamic sub-fields
      if (_type == 'Injury') {
        data['injuryDetails'] = {
          'bodyPart': _bodyPartController.text.trim(),
          'treatmentType': _treatmentType,
        };
      } else if (_type == 'Environmental') {
        data['environmentalDetails'] = {
          'substance': _substanceController.text.trim(),
          'volume': _volumeController.text.trim(),
          'unit': _envUnit,
        };
      } else if (_type == 'Property Damage') {
        data['propertyDamageDetails'] = {
          'assetId': _assetIdController.text.trim(),
          'estimatedDamage': double.tryParse(_damageEstimateController.text) ?? 0,
        };
      }

      // Write through offline-first service
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createDocument(collection: 'incidents', data: data);

      // Auto-create CAPA for Major/Critical
      if (_severity == 'Major' || _severity == 'Critical') {
        await firestoreService.createDocument(
          collection: 'capas',
          data: {
            'description': 'Automatic CAPA for $_severity incident: ${_titleController.text}',
            'status': 'Open',
            'createdById': profile.uid,
            'siteId': profile.siteId,
            'createdAt': DateTime.now().toIso8601String(),
            'assignedToName': 'Safety Manager',
            'dueDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incident reported successfully${_severity == "Major" || _severity == "Critical" ? " — CAPA auto-created" : ""}'),
            backgroundColor: XMTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: XMTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : _submitIncident,
            icon: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(XMTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Anonymous Toggle ───
              SwitchListTile(
                value: _isAnonymous,
                onChanged: (v) => setState(() => _isAnonymous = v),
                title: const Text('Anonymous Report'),
                subtitle: const Text('Your identity will be hidden'),
                secondary: Icon(
                  _isAnonymous ? Icons.visibility_off : Icons.visibility,
                  color: _isAnonymous ? XMTheme.warning : null,
                ),
              ),
              const SizedBox(height: XMTheme.spacingMd),

              // ─── Title ───
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Incident Title *',
                  hintText: 'Brief description of what happened',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: XMTheme.spacingMd),

              // ─── Description ───
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Detailed Description *',
                  hintText: 'Describe the incident in detail...',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: XMTheme.spacingMd),

              // ─── Type & Severity Row ───
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.category)),
                      items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _severity,
                      decoration: const InputDecoration(labelText: 'Severity', prefixIcon: Icon(Icons.warning)),
                      items: _severities.map((s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: _severityColor(s),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(s),
                          ],
                        ),
                      )).toList(),
                      onChanged: (v) => setState(() => _severity = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: XMTheme.spacingMd),

              // ─── Location ───
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  hintText: 'Where did it happen?',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Use GPS',
                    onPressed: () {
                      // TODO: Geolocator in Phase 4
                      _locationController.text = 'GPS coordinates unavailable';
                    },
                  ),
                ),
              ),
              const SizedBox(height: XMTheme.spacingMd),

              // ─── Date of Incident ───
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date of Incident'),
                subtitle: Text(
                  '${_dateOfIncident.day}/${_dateOfIncident.month}/${_dateOfIncident.year} ${_dateOfIncident.hour}:${_dateOfIncident.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateOfIncident,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null && mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_dateOfIncident),
                    );
                    if (time != null) {
                      setState(() {
                        _dateOfIncident = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: XMTheme.spacingMd),

              // ─── Photo Capture ───
              Text('Photo Evidence', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PhotoButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickPhoto(ImageSource.camera),
                  ),
                  const SizedBox(width: 12),
                  _PhotoButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickPhoto(ImageSource.gallery),
                  ),
                  if (_photoFile != null) ...[
                    const SizedBox(width: 12),
                    Chip(
                      avatar: const Icon(Icons.check, size: 16),
                      label: const Text('Photo attached'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _photoFile = null),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: XMTheme.spacingLg),

              // ─── Dynamic Sub-Fields ───
              _buildDynamicFields(),
              const SizedBox(height: XMTheme.spacingLg),

              // ─── Cost Tracking ───
              Text('Cost Tracking', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _directCostsController,
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
                      controller: _indirectCostsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Indirect Costs (R)',
                        prefixIcon: Icon(Icons.money_off),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: XMTheme.spacingXxl),

              // ─── Submit Button ───
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitIncident,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Incident Report'),
                ),
              ),
              const SizedBox(height: XMTheme.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicFields() {
    switch (_type) {
      case 'Injury':
        return _SectionCard(
          title: 'Injury Details',
          color: XMTheme.error,
          children: [
            TextFormField(
              controller: _bodyPartController,
              decoration: const InputDecoration(labelText: 'Body Part Affected', prefixIcon: Icon(Icons.accessibility)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _treatmentType,
              decoration: const InputDecoration(labelText: 'Treatment Type', prefixIcon: Icon(Icons.medical_services)),
              items: _treatments.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _treatmentType = v!),
            ),
          ],
        );
      case 'Environmental':
        return _SectionCard(
          title: 'Environmental Details',
          color: XMTheme.success,
          children: [
            TextFormField(
              controller: _substanceController,
              decoration: const InputDecoration(labelText: 'Substance', prefixIcon: Icon(Icons.science)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _volumeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Volume'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    value: _envUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: ['Liters', 'Gallons', 'kg', 'Tonnes']
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _envUnit = v!),
                  ),
                ),
              ],
            ),
          ],
        );
      case 'Property Damage':
        return _SectionCard(
          title: 'Property Damage Details',
          color: XMTheme.warning,
          children: [
            TextFormField(
              controller: _assetIdController,
              decoration: const InputDecoration(labelText: 'Asset ID / Name', prefixIcon: Icon(Icons.inventory)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _damageEstimateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Estimated Damage (R)', prefixIcon: Icon(Icons.attach_money)),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Critical': return XMTheme.severityCritical;
      case 'Major': return XMTheme.severityMajor;
      case 'Moderate': return XMTheme.severityModerate;
      case 'Minor': return XMTheme.severityMinor;
      default: return XMTheme.severityNegligible;
    }
  }
}

// ─── Reusable sub-widgets ───

class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PhotoButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(XMTheme.radiusSm),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(XMTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4, height: 20,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
