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

/// A standardized Section Header for Google-style apps.
class GHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const GHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(XMTheme.spacingMd),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A standardized Status Badge using semantic colors.
class GStatusTag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const GStatusTag({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(XMTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standardized Spacing widgets to avoid hardcoded SizedBoxes.
class GSpacing {
  static const hXs = SizedBox(width: XMTheme.spacingXs);
  static const hSm = SizedBox(width: XMTheme.spacingSm);
  static const hMd = SizedBox(width: XMTheme.spacingMd);
  static const hLg = SizedBox(width: XMTheme.spacingLg);

  static const vXs = SizedBox(height: XMTheme.spacingXs);
  static const vSm = SizedBox(height: XMTheme.spacingSm);
  static const vMd = SizedBox(height: XMTheme.spacingMd);
  static const vLg = SizedBox(height: XMTheme.spacingLg);
  static const vXl = SizedBox(height: XMTheme.spacingXl);
  static const vXxl = SizedBox(height: XMTheme.spacingXxl);

  // Aliases for legacy usage or more descriptive naming
  static Widget vSmall() => vSm;
  static Widget vMedium() => vMd;
  static Widget vLarge() => vLg;
  static Widget hSmall() => hSm;
  static Widget vExtraLarge() => vXl;
}
