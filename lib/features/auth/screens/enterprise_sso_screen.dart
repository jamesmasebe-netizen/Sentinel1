import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../config/theme.dart';

class EnterpriseSSOScreen extends ConsumerStatefulWidget {
  const EnterpriseSSOScreen({super.key});

  @override
  ConsumerState<EnterpriseSSOScreen> createState() =>
      _EnterpriseSSOScreenState();
}

class _EnterpriseSSOScreenState extends ConsumerState<EnterpriseSSOScreen> {
  bool _isLoading = false;
  final TextEditingController _providerIdController = TextEditingController();

  Future<void> _handleSAMLSignIn() async {
    final providerId = _providerIdController.text.trim();
    if (providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Provider ID')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final profile = await authService.signInWithSAML(providerId);

      if (profile != null) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SAML login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _providerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise SSO'),
        backgroundColor: XMTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.business, size: 80, color: XMTheme.primary),
                const SizedBox(height: 32),
                const Text(
                  'Login with Microsoft / Okta',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your organization\'s SAML provider ID.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _providerIdController,
                  decoration: const InputDecoration(
                    labelText: 'Provider ID (e.g. saml.my-company)',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _handleSAMLSignIn(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSAMLSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: XMTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Sign In with SAML',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
