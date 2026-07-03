import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// A standardized Material 3 Card following Google App aesthetics.
/// Uses tonal elevation and consistent border-radius.
class GCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double? radius;
  final bool showBorder;
  final BorderSide? border;
  final double? width;
  final double? height;

  const GCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.radius,
    this.showBorder = true,
    this.border,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(XMTheme.spacingMd),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius ?? XMTheme.radiusXl),
        child: content,
      );
    }

    return Container(
      width: width,
      height: height,
      margin:
          margin ??
          const EdgeInsets.symmetric(
            vertical: XMTheme.spacingSm,
            horizontal: XMTheme.spacingMd,
          ),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(radius ?? XMTheme.radiusXl),
        border:
            showBorder
                ? Border.fromBorderSide(
                  border ??
                      BorderSide(
                        color: theme.colorScheme.outlineVariant,
                        width: 1,
                      ),
                )
                : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? XMTheme.radiusXl),
        child: content,
      ),
    );
  }
}
