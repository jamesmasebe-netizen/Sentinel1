import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class LoginCard extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback onSignInWithGoogle;
  final VoidCallback onDevBypassLogin;

  const LoginCard({
    super.key,
    required this.isLoading,
    this.error,
    required this.onSignInWithGoogle,
    required this.onDevBypassLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(XMTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(XMTheme.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            'Sign in to continue',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: XMTheme.spacingLg),

          // Google Sign-In Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onSignInWithGoogle,
              icon:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.login, size: 20),
              label: Text(isLoading ? 'Signing in...' : 'Sign in with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E293B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(XMTheme.radiusSm),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Dev Bypass Button — debug builds only (F-501: this was unconditionally
          // visible in release builds with no build-flavor/feature-flag gate).
          if (kDebugMode) ...[
            const SizedBox(height: XMTheme.spacingMd),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onDevBypassLogin,
                icon: const Icon(Icons.developer_mode, size: 20),
                label: const Text('Bypass Login (Dev)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(XMTheme.radiusSm),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          if (error != null) ...[
            const SizedBox(height: XMTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: XMTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(XMTheme.radiusSm),
                border: Border.all(color: XMTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: XMTheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: XMTheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
