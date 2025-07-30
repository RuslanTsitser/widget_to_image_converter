# Widget to Image Converter

Flutter FFI plugin for converting widgets to JPEG and PNG images using native C code.

## Features

- Convert Flutter widgets to JPEG and PNG images
- Automatic conversion state management
- JPEG quality configuration (1-100)
- **Parallel processing with worker pool** - handle multiple images efficiently
- **Configurable pool size** - optimize for your device performance
- Cross-platform support (iOS, Android, macOS)

## Worker Pool

For processing multiple images efficiently, use the isolate pool:

```dart
import 'package:widget_to_image_converter/widget_to_image_converter.dart';

void main() {
  // Configure pool size (default is 4)
  ConvertToJpegIsolatePoolMixin.configurePool(poolSize: 6);
  
  runApp(MyApp());
}

// Usage with controller
final controller = WidgetToImageProvider.of(context);
await controller.saveAsJpegWithPool(
  outputPath: '/path/to/image.jpg',
  quality: 90,
);
```

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  widget_to_image_converter: ^1.0.0
  path_provider: ^2.0.0
```

## Usage

### Basic Example

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:widget_to_image_converter/widget_to_image_converter.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetToImageProvider(
      child: Scaffold(
        body: Column(
          children: [
            // Wrap widget to convert
            WidgetToImageWrapper(
              child: Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('Widget to convert', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SomeButton(),
          ],
        ),
      ),
    );
  }
}


class SomeButton extends StatelessWidget {
  const SomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final controller = WidgetToImageProvider.of(context, listen: false);
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/widget.jpg';
        await controller.saveAsJpeg(outputPath: path, quality: 90);
      }, 
      child: const Text('Save as JPEG'),
    );
  }
}
```

### Advanced Usage

```dart
class AdvancedExample extends StatefulWidget {
  const AdvancedExample({super.key});

  @override
  _AdvancedExampleState createState() => _AdvancedExampleState();
}

class _AdvancedExampleState extends State<AdvancedExample> {
  late final WidgetToImageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WidgetToImageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveHighQuality() async {
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/high_quality.jpg';
    await _controller.saveAsJpeg(
      outputPath: path,
      quality: 95,
      pixelRatio: 2.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WidgetToImageProvider(
      controller: _controller,
      child: Scaffold(
        body: Column(
          children: [
            WidgetToImageWrapper(child: YourWidget()),
            ElevatedButton(
              onPressed: _saveHighQuality,
              child: const Text('Save High Quality'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## API Reference

### WidgetToImageProvider

Wrapper for providing controller to widgets.

### WidgetToImageController

- `saveAsJpeg({required String outputPath, double? pixelRatio, int quality = 90})`
- `saveAsPng({required String outputPath, double? pixelRatio})`
- `saveAsRgbaFile({required String outputPath, double? pixelRatio})`
- `getRgba({required String outputPath, double? pixelRatio})`
- `convertToJpegAsync(String path, int width, int height)`

### WidgetToImageWrapper

Wrapper widget for automatic RepaintBoundary creation.

## Requirements

- Dart 3.0.0+
- Flutter 3.0.0+

## License

MIT License
