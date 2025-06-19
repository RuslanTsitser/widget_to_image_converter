import 'package:flutter/material.dart';
import 'package:widget_to_image_converter/src/widget/widget_to_image_controller.dart';

/// Provider for the widget to image conversion
class WidgetToImageProvider extends StatefulWidget {
  /// Create a provider for the widget to image conversion
  const WidgetToImageProvider({
    super.key,
    required this.child,
    this.controller,
  });

  /// Child widget
  final Widget child;

  /// Controller for the widget to image conversion
  final WidgetToImageController? controller;

  /// Get the controller for the widget to image conversion
  static WidgetToImageController of(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<WidgetToImageInherited>()!
          .notifier!;
    }
    return context
        .getInheritedWidgetOfExactType<WidgetToImageInherited>()!
        .notifier!;
  }

  @override
  State<WidgetToImageProvider> createState() => _WidgetToImageProviderState();
}

class _WidgetToImageProviderState extends State<WidgetToImageProvider> {
  /// Controller for the widget to image conversion
  late final WidgetToImageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? WidgetToImageController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WidgetToImageInherited(notifier: _controller, child: widget.child);
  }
}

/// Inherited widget for the widget to image conversion
class WidgetToImageInherited
    extends InheritedNotifier<WidgetToImageController> {
  const WidgetToImageInherited({
    super.key,
    required super.notifier,
    required super.child,
  });
}
