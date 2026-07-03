// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/integrations_service.dart';

class IntegrationConfigForm extends ConsumerStatefulWidget {
  final IntegrationConfig? config;

  const IntegrationConfigForm({super.key, this.config});

  @override
  ConsumerState<IntegrationConfigForm> createState() =>
      _IntegrationConfigFormState();
}

class _IntegrationConfigFormState extends ConsumerState<IntegrationConfigForm> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _type;
  late String _webhookUrl;
  late String _apiKey;
  late bool _isEnabled;
  bool _isLoading = false;

  final _integrationTypes = ['payroll', 'recruitment', 'equipment', 'finance'];

  @override
  void initState() {
    super.initState();
    _name = widget.config?.name ?? '';
    _type = widget.config?.type ?? 'payroll';
    _webhookUrl = widget.config?.webhookUrl ?? '';
    _apiKey = widget.config?.apiKey ?? '';
    _isEnabled = widget.config?.isEnabled ?? true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final siteId = ref.read(currentTenantIdProvider);
      if (siteId == null) throw Exception('No site context');

      final newConfig = IntegrationConfig(
        id: widget.config?.id ?? '',
        name: _name,
        type: _type,
        isEnabled: _isEnabled,
        webhookUrl: _webhookUrl,
        apiKey: _apiKey,
        tenantId: siteId,
      );

      await ref.read(integrationsServiceProvider).saveIntegration(newConfig);

      if (mounted) {
        UIUtils.showToast(
          context,
          'Integration saved',
          type: ToastType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(
                labelText: 'Integration Name',
                border: OutlineInputBorder(),
              ),
              validator:
                  (val) => val == null || val.isEmpty ? 'Required' : null,
              onSaved: (val) => _name = val!.trim(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Integration Type',
                border: OutlineInputBorder(),
              ),
              items:
                  _integrationTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.toUpperCase()),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(() => _type = val!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _webhookUrl,
              decoration: const InputDecoration(
                labelText: 'Webhook URL',
                border: OutlineInputBorder(),
              ),
              validator:
                  (val) => val == null || val.isEmpty ? 'Required' : null,
              onSaved: (val) => _webhookUrl = val!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _apiKey,
              decoration: const InputDecoration(
                labelText: 'API Key / Bearer Token (Optional)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onSaved: (val) => _apiKey = val?.trim() ?? '',
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Integration'),
              value: _isEnabled,
              onChanged: (val) => setState(() => _isEnabled = val),
            ),
            const SizedBox(height: 32),
            UIUtils.buildFormButtons(
              context: context,
              onSave: _submit,
              isSubmitting: _isLoading,
            ),
            if (widget.config != null) ...[
              const Divider(),
              TextButton.icon(
                onPressed: () async {
                  await ref
                      .read(integrationsServiceProvider)
                      .deleteIntegration(
                        ref.read(currentTenantIdProvider) ?? "",
                        widget.config!.id,
                      );
                  if (mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete Integration'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
