import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class UIUtils {
  /// Shows a custom MD3 style toast notification
  static void showToast(BuildContext context, String message, {bool isError = false}) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.hideCurrentSnackBar();
    scaffold.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: isError ? XMTheme.error : XMTheme.success,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B), // Dark slate
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(XMTheme.radiusSm),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a standard 90% height modal bottom sheet with blurred backdrop
  static Future<T?> showAppBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent, // To show custom decoration
      barrierColor: Colors.black.withValues(alpha: 0.4),
      useSafeArea: true,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.90, // 90% Height Rule
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(XMTheme.radiusXl), // Squircle top
              ),
            ),
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: builder(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows a Material 3 Side Sheet for large screens, falling back to a Bottom Sheet for mobile.
  /// Used for "In-Place Drill Downs" without losing dashboard context.
  static Future<T?> showSideSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    required String title,
    double width = 450,
  }) {
    final isWideScreen = MediaQuery.sizeOf(context).width >= 800;
    
    if (!isWideScreen) {
      // Mobile fallback: show bottom sheet
      return showAppBottomSheet<T>(
        context: context,
        builder: (ctx) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(child: builder(ctx)),
          ],
        )
      );
    }

    // Desktop/Tablet: Show Side Sheet sliding from the right edge
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.2), // Soft Google Workspace dimming
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 8,
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(XMTheme.radiusLg)),
            child: SizedBox(
              width: width,
              height: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Side Sheet Header
                  Padding(
                    padding: const EdgeInsets.all(XMTheme.spacingLg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                          color: XMTheme.secondaryLight,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Side Sheet Content
                  Expanded(child: builder(context)),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic, // Smooth expressive curve
          )),
          child: child,
        );
      },
    );
  }
}
