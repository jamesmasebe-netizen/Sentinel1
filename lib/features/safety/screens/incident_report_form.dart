// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../config/theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/events/app_event_bus.dart';
import '../widgets/incident_report_dynamic_fields.dart';
import '../widgets/incident_basic_info_fields.dart';
import '../widgets/incident_type_severity_fields.dart';
import '../widgets/incident_location_date_fields.dart';
import '../widgets/incident_photo_capture_section.dart';
import '../widgets/incident_cost_tracking_fields.dart';

class IncidentReportForm extends ConsumerStatefulWidget {
  final String tenantId;
  const IncidentReportForm({super.key, required this.tenantId});

  @override
  ConsumerState<IncidentReportForm> createState() => _IncidentReportFormState();
}

class _IncidentReportFormState extends ConsumerState<IncidentReportForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _selectedReporterId;
  String? _selectedContractorId;

  String _type = 'Injury';
  String _severity = 'Minor';
  DateTime _dateOfIncident = DateTime.now();
  XFile? _photoFile;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _directCostsController = TextEditingController(text: '0');
  final _indirectCostsController = TextEditingController(text: '0');

  String _treatmentType = 'First Aid';
  final _bodyPartController = TextEditingController();

  String _envUnit = 'Liters';
  final _substanceController = TextEditingController();
  final _volumeController = TextEditingController();

  final _assetIdController = TextEditingController();
  final _damageEstimateController = TextEditingController(text: '0');

  @override
  void dispose() {
    for (final c in [
      _titleController, _descriptionController, _locationController,
      _directCostsController, _indirectCostsController, _bodyPartController,
      _substanceController, _volumeController, _assetIdController, _damageEstimateController
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final photo = await ImagePicker().pickImage(source: source, maxWidth: 1200, imageQuality: 80);
    if (photo != null) setState(() => _photoFile = photo);
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile == null) throw Exception('Not logged in');

      String? photoUrl;
      if (_photoFile != null) {
        final ref = FirebaseStorage.instance.ref().child('incidents/${DateTime.now().millisecondsSinceEpoch}_${_photoFile!.name}');
        await ref.putFile(File(_photoFile!.path));
        photoUrl = await ref.getDownloadURL();
      }

      final dCosts = double.tryParse(_directCostsController.text) ?? 0;
      final iCosts = double.tryParse(_indirectCostsController.text) ?? 0;

      final data = <String, dynamic>{
        'title': _titleController.text.trim(), 'description': _descriptionController.text.trim(),
        'type': _type, 'severity': _severity, 'location': _locationController.text.trim(),
        'status': 'Open', 'reporterId': _selectedReporterId ?? profile.uid,
        'reporterName': 'Selected Employee', 'siteId': profile.tenantId,
        'contractorId': _selectedContractorId, 'dateOfIncident': _dateOfIncident.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(), 'photoUrl': photoUrl, 'isAnonymous': false,
        'directCosts': dCosts, 'indirectCosts': iCosts, 'totalCost': dCosts + iCosts,
      };

      if (_type == 'Injury') {
        data['injuryDetails'] = {'bodyPart': _bodyPartController.text.trim(), 'treatmentType': _treatmentType};
      } else if (_type == 'Environmental') {
        data['environmentalDetails'] = {'substance': _substanceController.text.trim(), 'volume': _volumeController.text.trim(), 'unit': _envUnit};
      } else if (_type == 'Property Damage') {
        data['propertyDamageDetails'] = {'assetId': _assetIdController.text.trim(), 'estimatedDamage': double.tryParse(_damageEstimateController.text) ?? 0};
      }

      final fs = ref.read(firestoreServiceProvider);
      final docRef = await fs.createDocument(tenantId: profile.tenantId ?? '', collection: 'incidents', data: data);

      if (_severity == 'Major' || _severity == 'Critical') {
        ref.read(appEventBusProvider).fire(HighRiskIncidentReportedEvent(incidentId: docRef, projectId: profile.tenantId ?? 'Unknown'));
        await fs.createDocument(tenantId: profile.tenantId ?? '', collection: 'capas', data: {
          'description': 'Automatic CAPA for $_severity incident: ${_titleController.text}',
          'status': 'Open', 'createdById': profile.uid, 'siteId': profile.tenantId,
          'createdAt': DateTime.now().toIso8601String(), 'assignedToName': 'Safety Manager',
          'dueDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        });
      }

      if (mounted) {
        UIUtils.showToast(context, 'Incident reported successfully${_severity == "Major" || _severity == "Critical" ? " — CAPA auto-created" : ""}', type: ToastType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) UIUtils.showToast(context, 'Failed to report incident: $e', type: ToastType.error);
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
            icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
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
              IncidentBasicInfoFields(
                selectedReporterId: _selectedReporterId, onReporterChanged: (val) => setState(() => _selectedReporterId = val),
                titleController: _titleController, descriptionController: _descriptionController,
              ),
              const SizedBox(height: XMTheme.spacingMd),
              IncidentTypeSeverityFields(
                type: _type, onTypeChanged: (val) => setState(() => _type = val!),
                severity: _severity, onSeverityChanged: (val) => setState(() => _severity = val!),
              ),
              const SizedBox(height: XMTheme.spacingMd),
              IncidentLocationDateFields(
                locationController: _locationController, dateOfIncident: _dateOfIncident,
                onDateChanged: (val) => setState(() => _dateOfIncident = val),
                onGpsPressed: () async {
                  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                  if (!serviceEnabled) {
                    if (!mounted) return;
                    UIUtils.showToast(context, 'Location services are disabled.');
                    return;
                  }
                  LocationPermission permission = await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                    if (permission == LocationPermission.denied) {
                      if (!mounted) return;
                      UIUtils.showToast(context, 'Location permissions are denied');
                      return;
                    }
                  }
                  if (permission == LocationPermission.deniedForever) {
                    if (!mounted) return;
                    UIUtils.showToast(context, 'Location permissions are permanently denied.');
                    return;
                  }
                  final position = await Geolocator.getCurrentPosition();
                  if (!mounted) return;
                  setState(() => _locationController.text = 'Latitude: ${position.latitude.toStringAsFixed(4)}, Longitude: ${position.longitude.toStringAsFixed(4)}');
                  UIUtils.showToast(context, 'Location updated');
                },
              ),
              const SizedBox(height: XMTheme.spacingMd),
              IncidentPhotoCaptureSection(
                photoFile: _photoFile, onPickPhoto: _pickPhoto,
                onRemovePhoto: () => setState(() => _photoFile = null),
              ),
              const SizedBox(height: XMTheme.spacingLg),
              IncidentReportDynamicFields(
                type: _type, bodyPartController: _bodyPartController,
                treatmentType: _treatmentType, onTreatmentTypeChanged: (val) => setState(() => _treatmentType = val),
                substanceController: _substanceController, volumeController: _volumeController,
                envUnit: _envUnit, onEnvUnitChanged: (val) => setState(() => _envUnit = val),
                assetIdController: _assetIdController, damageEstimateController: _damageEstimateController,
              ),
              const SizedBox(height: XMTheme.spacingLg),
              IncidentCostTrackingFields(directCostsController: _directCostsController, indirectCostsController: _indirectCostsController),
              const SizedBox(height: XMTheme.spacingXxl),
              SizedBox(
                width: double.infinity, height: 52,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitIncident,
                  icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
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
}
