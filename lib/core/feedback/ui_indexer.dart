import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:uuid/uuid.dart';

/// A utility to index the current UI state for AI consumption.
/// Captures widget hierarchy, positions, text content, and theme tokens.
class UIIndexer {
  final BuildContext context;
  final String screenName;
  final Uuid _uuid = const Uuid();

  UIIndexer(this.context, {this.screenName = 'Unknown'});

  /// Performs the 'State Dump' and returns a structured Map.
  Map<String, dynamic> captureState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final media = MediaQuery.of(context);

    final List<Map<String, dynamic>> flatList = [];
    final hierarchyTree = _traverse(context as Element, null, flatList);

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'screen_name': screenName,
      'device_info': {
        'platform': theme.platform.name,
        'screen_size': {'w': media.size.width.round(), 'h': media.size.height.round()},
        'pixel_ratio': media.devicePixelRatio,
        'padding': {'t': media.padding.top, 'b': media.padding.bottom},
      },
      'theme_context': {
        'brightness': theme.brightness.name,
        'colors': {
          'primary': _toHex(colorScheme.primary),
          'secondary': _toHex(colorScheme.secondary),
          'surface': _toHex(colorScheme.surface),
          'error': _toHex(colorScheme.error),
          'on_primary': _toHex(colorScheme.onPrimary),
          'on_surface': _toHex(colorScheme.onSurface),
        },
        'typography': {
          'font_family': theme.textTheme.bodyMedium?.fontFamily ?? 'System',
          'display_large': _textStyleToMap(theme.textTheme.displayLarge),
          'headline_medium': _textStyleToMap(theme.textTheme.headlineMedium),
          'title_large': _textStyleToMap(theme.textTheme.titleLarge),
          'body_large': _textStyleToMap(theme.textTheme.bodyLarge),
          'body_medium': _textStyleToMap(theme.textTheme.bodyMedium),
          'label_small': _textStyleToMap(theme.textTheme.labelSmall),
        },
      },
      'ui_hierarchy_tree': hierarchyTree,
      'ui_index_flat': flatList,
    };
  }

  Map<String, dynamic> _traverse(Element element, String? parentId, List<Map<String, dynamic>> flatList) {
    final id = _uuid.v4();
    final widget = element.widget;
    final children = <Map<String, dynamic>>[];

    final elementData = {
      'id': id,
      'parent_id': parentId,
      'type': widget.runtimeType.toString(),
      'key': widget.key?.toString(),
    };

    // Capture Text content
    if (widget is Text) {
      elementData['text'] = widget.data;
    } else if (widget is EditableText) {
      elementData['text'] = widget.controller.text;
    }

    // Capture Layout
    final RenderObject? renderObject = element.renderObject;
    if (renderObject is RenderBox && renderObject.hasSize) {
      final position = renderObject.localToGlobal(Offset.zero);
      final size = renderObject.size;
      elementData['rect'] = {
        'x': position.dx.round(),
        'y': position.dy.round(),
        'w': size.width.round(),
        'h': size.height.round(),
      };
    }

    flatList.add(elementData);

    element.visitChildElements((child) {
      children.add(_traverse(child, id, flatList));
    });

    return {
      ...elementData,
      'children': children,
    };
  }

  bool _isVisible(Offset position, Size size) {
    final screenSize = MediaQuery.of(context).size;
    return position.dx < screenSize.width &&
           position.dy < screenSize.height &&
           (position.dx + size.width) > 0 &&
           (position.dy + size.height) > 0;
  }

  Map<String, dynamic> _textStyleToMap(TextStyle? style) {
    if (style == null) return {};
    return {
      'size': style.fontSize,
      'weight': style.fontWeight?.index,
      'letter_spacing': style.letterSpacing,
      'color': style.color != null ? _toHex(style.color!) : null,
    };
  }

  String _toHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}
