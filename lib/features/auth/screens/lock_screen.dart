import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/services/session_manager.dart';
import '../../../core/providers/app_providers.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Start authentication as soon as the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate(auto: true);
    });
  }

  Future<void> _authenticate({bool auto = false}) async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (isDeviceSupported) {
        // biometricOnly: false lets the OS fall back to PIN/pattern/password
        // if no biometric is enrolled — never unlock without some device
        // credential check. See F-505 in docs/fixes/FIX_LIST.md.
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to unlock XM System',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (didAuthenticate && mounted) {
          ref.read(sessionManagerProvider).unlockSession();
          // The router will automatically redirect back to the previous screen or dashboard
          // because we update the isAppLockedProvider to false.
        }
      } else if (!auto && mounted) {
        // No device credential of any kind exists to verify against —
        // never auto-unlock; force a full sign-out instead.
        await ref.read(authServiceProvider).signOut();
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Session Locked',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'For your security, the app has been locked due to inactivity.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isAuthenticating ? null : _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: Text(_isAuthenticating ? 'Authenticating...' : 'Unlock'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ref.read(authServiceProvider).signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
