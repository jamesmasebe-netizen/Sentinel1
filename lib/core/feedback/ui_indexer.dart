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

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'screen_name': screenName,
      'theme_context': {
        'brightness': theme.brightness.name,
        'primary': _toHex(colorScheme.primary),
        'secondary': _toHex(colorScheme.secondary),
        'surface': _toHex(colorScheme.surface),
        'error': _toHex(colorScheme.error),
        'on_primary': _toHex(colorScheme.onPrimary),
        'surface_container': _toHex(colorScheme.surfaceContainer),
      },
      'ui_index': _indexElements(),
    };
  }

  List<Map<String, dynamic>> _indexElements() {
    final List<Map<String, dynamic>> indexedElements = [];
    
    // Start traversal from the nearest RenderObject boundary or the root of the feature
    void traverse(Element element, String? parentId) {
      final id = _uuid.v4();
      final widget = element.widget;
      
      // Capture basic properties
      final elementData = {
        'id': id,
        'parent_id': parentId,
        'type': widget.runtimeType.toString(),
        'key': widget.key?.toString(),
      };

      // Capture Text content if available
      if (widget is Text) {
        elementData['text'] = widget.data;
      } else if (widget is EditableText) {
        elementData['text'] = widget.controller.text;
      }

      // Capture RenderBox data for coordinates
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
        
        // Mark if it's currently visible on screen
        elementData['is_visible'] = _isVisible(position, size);
      }

      indexedElements.add(elementData);

      // Recursive step
      element.visitChildElements((child) => traverse(child, id));
    }

    // Begin traversal from the current context
    traverse(context as Element, null);
    
    return indexedElements;
  }

  bool _isVisible(Offset position, Size size) {
    final screenSize = MediaQuery.of(context).size;
    return position.dx < screenSize.width &&
           position.dy < screenSize.height &&
           (position.dx + size.width) > 0 &&
           (position.dy + size.height) > 0;
  }

  String _toHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}
