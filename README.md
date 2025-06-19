# Widget to Image Converter

Flutter FFI plugin for converting widgets to JPEG and PNG images using native C code.

## 🚀 Features

- Convert Flutter widgets to JPEG and PNG images
- Automatic conversion state management
- JPEG quality configuration (1-100)
- Support for various pixel ratios
- Standalone operation without external dependencies
- Cross-platform support (iOS, Android, macOS, Linux, Windows)
- Uses single-file library stb_image_write.h for JPEG
- Built-in PNG support through Flutter

## 📦 Installation

Add to your project's `pubspec.yaml`:

```yaml
dependencies:
  widget_to_image_converter: ^0.0.1
  path_provider: ^2.0.0  # for getting directory paths
```

## 🔧 Usage

### Simple usage with Provider

```dart
import 'package:flutter/material.dart';
import 'package:widget_to_image_converter/widget_to_image_converter.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WidgetToImageProvider(child: ExampleScreen()),
    );
  }
}

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Wrap the widget we want to convert
          WidgetToImageWrapper(
            child: Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'Widget to convert',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Conversion buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final controller = WidgetToImageProvider.of(context, listen: false);
                  final tempDir = await getTemporaryDirectory();
                  final outputPath = '${tempDir.path}/widget_${DateTime.now().millisecondsSinceEpoch}.jpg';
                  await controller.saveAsJpeg(outputPath: outputPath, quality: 90);
                },
                child: const Text('Save as JPEG'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  final controller = WidgetToImageProvider.of(context, listen: false);
                  final tempDir = await getTemporaryDirectory();
                  final outputPath = '${tempDir.path}/widget_${DateTime.now().millisecondsSinceEpoch}.png';
                  await controller.saveAsPng(outputPath: outputPath);
                },
                child: const Text('Save as PNG'),
              ),
            ],
          ),
          // Result display
          const ResultDisplay(),
        ],
      ),
    );
  }
}

class ResultDisplay extends StatelessWidget {
  const ResultDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = WidgetToImageProvider.of(context, listen: true);
  
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (controller.status == WidgetToImageStatus.saving)
            const CircularProgressIndicator(),
          if (controller.status == WidgetToImageStatus.saved) ...[
            if (controller.jpegPath != null)
              Image.file(File(controller.jpegPath!), height: 200),
            if (controller.pngPath != null)
              Image.file(File(controller.pngPath!), height: 200),
          ],
          if (controller.status == WidgetToImageStatus.error)
            const Text('Conversion error', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
```

### Advanced usage with controller

```dart
class AdvancedExample extends StatefulWidget {
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

  Future<void> _saveWithCustomSettings() async {
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/custom_${DateTime.now().millisecondsSinceEpoch}.jpg';
  
    await _controller.saveAsJpeg(
      outputPath: outputPath,
      quality: 95, // High quality
      pixelRatio: 2.0, // High resolution
    );
  }

  @override
  Widget build(BuildContext context) {
    return WidgetToImageProvider(
      controller: _controller,
      child: Scaffold(
        body: Column(
          children: [
            WidgetToImageWrapper(
              child: YourWidget(),
            ),
            ElevatedButton(
              onPressed: _saveWithCustomSettings,
              child: const Text('Save with settings'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Direct FFI function usage

For direct usage of the native conversion function:

```dart
import 'package:widget_to_image_converter/widget_to_image_converter.dart';
import 'dart:typed_data';

// Convert RGBA data to JPEG
String? convertRgbaToJpeg(
  Uint8List rgbaData,  // RGBA image data (4 bytes per pixel)
  int width,           // Image width in pixels
  int height,          // Image height in pixels
  int quality,         // JPEG quality (1-100)
  String outputPath,   // Path to save JPEG file
);
```

## 📋 API Reference

### WidgetToImageProvider

For passing controller to widgets through `InheritedWidget`.

**Constructor:**

```dart
WidgetToImageProvider({
  Key? key,
  required Widget child,
  WidgetToImageController? controller,
})
```

**Static methods:**

- `WidgetToImageController of(BuildContext context, {bool listen = true})` - Get controller

### WidgetToImageController

Controller for managing the conversion process.

**Properties:**

- `GlobalKey repaintKey` - Key for RepaintBoundary
- `WidgetToImageStatus status` - Current conversion status
- `String? jpegPath` - Path to saved JPEG file
- `String? pngPath` - Path to saved PNG file

**Methods:**

- `Future<void> saveAsJpeg({required String outputPath, double? pixelRatio, int quality = 90})` - Save as JPEG
- `Future<void> saveAsPng({required String outputPath, double? pixelRatio})` - Save as PNG
- `void dispose()` - Release resources

### WidgetToImageWrapper

Wrapper widget for automatic RepaintBoundary creation.

**Constructor:**

```dart
WidgetToImageWrapper({Key? key, required Widget child})
```

### WidgetToImageStatus

Conversion status enumeration:

- `idle` - Waiting
- `saving` - Saving
- `saved` - Saved
- `error` - Error

### convertRgbaToJpeg

Native function for converting RGBA data to JPEG.

**Parameters:**

- `rgbaData` (Uint8List): RGBA image data (4 bytes per pixel: R, G, B, A)
- `width` (int): Image width in pixels
- `height` (int): Image height in pixels
- `quality` (int): JPEG quality (1-100)
- `outputPath` (String): Path to save JPEG file

**Returns:**

- `String`: Path to saved JPEG file

**Exceptions:**

- `ArgumentError`: If parameters are invalid
- `Exception`: If conversion fails

## ⚙️ Requirements

- Dart 3.0.0 or higher

## 🖥️ Platform Support

- ✅ iOS
- ✅ Android
- ✅ macOS
- Linux - not tested yet
- Windows - not tested yet

## 🔍 Implementation Details

### Conversion Process

1. **Image capture**: Uses `RepaintBoundary` to capture the widget
2. **Data extraction**: RGBA data is extracted from `ui.Image`
3. **JPEG conversion**: Uses native C function with stb_image_write.h
4. **PNG saving**: Uses built-in Flutter method
5. **State update**: Controller notifies about changes through `ChangeNotifier`

### Technical Details

- **FFI bindings**: Automatically generated using ffigen
- **Memory**: Proper memory allocation and deallocation through FFI
- **Errors**: Parameter validation and error handling on C and Dart sides
- **State**: Reactive UI updates through ChangeNotifier

## 📝 Usage Examples

### Monitoring conversion status

```dart
class StatusMonitor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = WidgetToImageProvider.of(context, listen: true);
  
    switch (controller.status) {
      case WidgetToImageStatus.idle:
        return const Text('Ready for conversion');
      case WidgetToImageStatus.saving:
        return const CircularProgressIndicator();
      case WidgetToImageStatus.saved:
        return const Text('Conversion completed');
      case WidgetToImageStatus.error:
        return const Text('Conversion error', style: TextStyle(color: Colors.red));
    }
  }
}
```

### Custom quality settings

```dart
// High quality for printing
await controller.saveAsJpeg(
  outputPath: path,
  quality: 95,
  pixelRatio: 2.0,
);

// Low quality for web
await controller.saveAsJpeg(
  outputPath: path,
  quality: 70,
  pixelRatio: 1.0,
);
```

### Error handling

```dart
try {
  await controller.saveAsJpeg(outputPath: path);
  print('Successfully saved: ${controller.jpegPath}');
} catch (e) {
  print('Conversion error: $e');
}
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
