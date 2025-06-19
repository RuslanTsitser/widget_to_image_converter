import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:widget_to_image_converter/src/widget_to_image_converter.dart';

/// Status of the widget to image conversion
enum WidgetToImageStatus { idle, saving, saved, error }

/// Controller for the widget to image conversion
class WidgetToImageController with ChangeNotifier {
  final GlobalKey _repaintKey = GlobalKey();

  /// Key for the widget to image conversion
  GlobalKey get repaintKey => _repaintKey;

  WidgetToImageStatus _status = WidgetToImageStatus.idle;

  /// Status of the widget to image conversion
  WidgetToImageStatus get status => _status;

  String? _jpegPath;

  /// Path to the saved JPEG file. Uses FFI to convert RGBA to JPEG
  String? get jpegPath => _jpegPath;

  String? _pngPath;

  /// Path to the saved PNG file. Uses default dart method to save as PNG
  String? get pngPath => _pngPath;

  /// Save the widget as a JPEG file
  /// - [outputPath] - Path to the saved JPEG file
  /// - [pixelRatio] - Pixel ratio of the image, default is 1.0
  /// - [quality] - Quality of the image, 0-100
  Future<void> saveAsJpeg({
    required String outputPath,
    double? pixelRatio,
    int quality = 90,
  }) async {
    _status = WidgetToImageStatus.saving;

    notifyListeners();

    try {
      /// Get the pixel ratio from the context
      pixelRatio ??=
          _repaintKey.currentContext
              ?.getInheritedWidgetOfExactType<MediaQuery>()
              ?.data
              .devicePixelRatio ??
          1.0;

      /// Get the boundary from the context
      final boundary = _repaintKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw Exception('Не найден RenderRepaintBoundary');
      }

      /// Get the image from the boundary
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      /// Get the byte data from the image
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) throw Exception('Не удалось получить байты');
      final Uint8List rgba = byteData.buffer.asUint8List();

      /// Convert the byte data to a JPEG file
      final actualPath = convertRgbaToJpeg(
        rgba,
        image.width,
        image.height,
        quality,
        outputPath,
      );

      /// Update the path to the actual saved file
      _jpegPath = actualPath;

      /// Set the status to saved
      _status = WidgetToImageStatus.saved;
      notifyListeners();
    } catch (e) {
      _status = WidgetToImageStatus.error;
      _jpegPath = null;
      notifyListeners();
    }
  }

  /// Default dart method to save as PNG
  Future<void> saveAsPng({
    required String outputPath,
    double? pixelRatio,
  }) async {
    _status = WidgetToImageStatus.saving;
    notifyListeners();

    try {
      /// Get the pixel ratio from the context
      pixelRatio ??=
          _repaintKey.currentContext
              ?.getInheritedWidgetOfExactType<MediaQuery>()
              ?.data
              .devicePixelRatio ??
          1.0;

      /// Get the boundary from the context
      final boundary = _repaintKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw Exception('Не найден RenderRepaintBoundary');
      }

      /// Get the image from the boundary
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      /// Get the byte data from the image
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) throw Exception('Не удалось получить байты');
      final Uint8List png = byteData.buffer.asUint8List();

      /// Save the byte data to a PNG file
      File(outputPath).writeAsBytesSync(png);

      /// Update the path to the actual saved file
      _pngPath = outputPath;

      /// Set the status to saved
      _status = WidgetToImageStatus.saved;
      notifyListeners();
    } catch (e) {
      _status = WidgetToImageStatus.error;
      _pngPath = null;
      notifyListeners();
    }
  }
}
