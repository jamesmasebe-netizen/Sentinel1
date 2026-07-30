import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../config/theme.dart';
import 'package:go_router/go_router.dart';
import '../widgets/login_card.dart';

/// Login screen with Google Sign-In and biometric authentication.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final authService = ref.read(authServiceProvider);
    final hasPrevious = await authService.hasPreviousSession();
    if (hasPrevious) {
      final success = await authService.authenticateWithBiometrics();
      if (success && mounted) {
        await authService.refreshProfile();
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Sign-in failed. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _devBypassLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // F-501: was setting isMockLoggedInProvider directly (client-side only,
      // no real Firebase Auth token). Use the real anonymous-auth path instead,
      // so at least request.auth is genuinely populated for rule checks.
      await ref.read(authServiceProvider).devBypassLogin();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Bypass failed: $e';
        });
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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [XMTheme.sidebarBg, Color(0xFF1E293B), XMTheme.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(XMTheme.spacingLg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 420 : double.infinity,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ─── Logo ───
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: XMTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: XMTheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.shield,
                        size: 64,
                        color: XMTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(height: XMTheme.spacingLg),

                    // ─── Title ───
                    const Text(
                      'XM System',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enterprise SHEQ Management',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: XMTheme.spacingXxl),

                    // ─── Login Card ───
                    LoginCard(
                      isLoading: _isLoading,
                      error: _error,
                      onSignInWithGoogle: _signInWithGoogle,
                      onEnterpriseSSO: () => context.go('/sso'),
                      onDevBypassLogin: _devBypassLogin,
                    ),

                    const SizedBox(height: XMTheme.spacingXl),

                    // ─── Footer ───
                    Text(
                      'Safety · Health · Environment · Quality',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
