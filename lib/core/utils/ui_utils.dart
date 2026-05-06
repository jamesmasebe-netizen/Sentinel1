import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../widgets/ds_widgets.dart';

enum ToastType { success, error, info, warning }

class UIUtils {
  /// Shows a custom Google Expressive style toast notification
  static void showToast(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
  }) {
    final theme = Theme.of(context);
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.hideCurrentSnackBar();

    final bool isError = type == ToastType.error;
    final bool isSuccess = type == ToastType.success;
    final bool isWarning = type == ToastType.warning;

    Color bgColor = theme.colorScheme.primaryContainer;
    Color fgColor = theme.colorScheme.onPrimaryContainer;
    IconData icon = Icons.info_outline_rounded;

    if (isError) {
      bgColor = theme.colorScheme.errorContainer;
      fgColor = theme.colorScheme.onErrorContainer;
      icon = Icons.error_outline_rounded;
    } else if (isSuccess) {
      bgColor = const Color(0xFFE8F5E9);
      fgColor = const Color(0xFF2E7D32);
      icon = Icons.check_circle_outline_rounded;
    } else if (isWarning) {
      bgColor = const Color(0xFFFFF3E0);
      fgColor = const Color(0xFFEF6C00);
      icon = Icons.warning_amber_rounded;
    }
    scaffold.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: fgColor,
              size: 20,
            ),
            GSpacing.hMd,
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(XMTheme.radiusLg),
          side: BorderSide(
            color: fgColor.withValues(alpha: 0.1),
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a standardized Google-style confirmation dialog
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(XMTheme.radiusLg)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDestructive ? FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ) : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      useSafeArea: true,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(XMTheme.radiusXl),
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(child: builder(ctx)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows a Material 3 Side Sheet for large screens, falling back to a Bottom Sheet for mobile.
  static Future<T?> showSideSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    required String title,
    double width = 480,
  }) {
    final isWideScreen = MediaQuery.sizeOf(context).width >= 900;
    final theme = Theme.of(context);

    if (!isWideScreen) {
      return showAppBottomSheet<T>(
        context: context,
        builder: (ctx) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: builder(ctx)),
          ],
        ),
      );
    }

    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Material(
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(XMTheme.radiusXl),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: SizedBox(
                width: width,
                height: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(XMTheme.spacingLg),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(child: builder(context)),
                  ],
                ),
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
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  /// Formats a Firestore Timestamp or ISO String to a readable date
  static String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is String) {
      dt = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return 'N/A';
    }
    return '${dt.day} ${getMonthName(dt.month)} ${dt.year}';
  }

  /// Returns the short month name
  static String getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  /// Standard date formatter
  static String formatDate(DateTime date) {
    return '${date.day} ${getMonthName(date.month)} ${date.year}';
  }

  /// Standardized form action buttons
  static Widget buildFormButtons({
    required BuildContext context,
    required VoidCallback onSave,
    required bool isSubmitting,
    String saveLabel = 'Save Record',
    String submittingLabel = 'Saving...',
  }) {
    return Column(
      children: [
        GSpacing.vLg,
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: isSubmitting ? null : onSave,
            child: Text(isSubmitting ? submittingLabel : saveLabel),
          ),
        ),
      ],
    );
  }
}
