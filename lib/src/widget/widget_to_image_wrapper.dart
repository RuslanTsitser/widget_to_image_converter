import 'package:flutter/material.dart';
import 'package:widget_to_image_converter/src/widget/widget_to_image_provider.dart';

class WidgetToImageWrapper extends StatelessWidget {
  const WidgetToImageWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = WidgetToImageProvider.of(context);
    return RepaintBoundary(key: controller.repaintKey, child: child);
  }
}
