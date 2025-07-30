import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:widget_to_image_converter/src/widget_to_image_converter.dart';

import '../mixin/convert_to_jpeg_isolate_mixin.dart';
import '../mixin/convert_to_jpeg_isolate_pool_mixin.dart';

/// Controller for the widget to image conversion
class WidgetToImageController
    with ConvertToJpegIsolateMixin, ConvertToJpegIsolatePoolMixin {
  final GlobalKey _repaintKey = GlobalKey();

  /// Key for the widget to image conversion
  GlobalKey get repaintKey => _repaintKey;

  /// Save the widget as a JPEG file
  /// - [outputPath] - Path to the saved JPEG file
  /// - [pixelRatio] - Pixel ratio of the image, default is 1.0
  /// - [quality] - Quality of the image, 0-100
  /// - [measureTime] - Whether to count the speed of the conversion
  Future<String> saveAsJpeg({
    required String outputPath,
    double? pixelRatio,
    int quality = 90,
    bool measureTime = false,
  }) async {
    Stopwatch? stopwatch;

    try {
      if (measureTime) {
        stopwatch = Stopwatch()..start();
      }

      /// Get the pixel ratio from the context
      pixelRatio ??= _repaintKey.currentContext
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
      final ui.Image image = boundary.toImageSync(pixelRatio: pixelRatio);

      /// Get the byte data from the image
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      image.dispose();
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

      return actualPath;
    } catch (e) {
      rethrow;
    } finally {
      if (measureTime) {
        log('saveAsJpeg: ${stopwatch?.elapsedMilliseconds}ms');
      }
    }
  }

  /// Default dart method to save as PNG
  /// - [outputPath] - Path to the saved PNG file
  /// - [pixelRatio] - Pixel ratio of the image, default is [MediaQueryData.devicePixelRatio]
  /// - [measureTime] - Whether to count the speed of the conversion
  Future<String> saveAsPng({
    required String outputPath,
    double? pixelRatio,
    bool measureTime = false,
  }) async {
    Stopwatch? stopwatch;

    try {
      if (measureTime) {
        stopwatch = Stopwatch()..start();
      }

      /// Get the pixel ratio from the context
      pixelRatio ??= _repaintKey.currentContext
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
      final ui.Image image = boundary.toImageSync(pixelRatio: pixelRatio);

      /// Get the byte data from the image
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      if (byteData == null) throw Exception('Не удалось получить байты');
      final Uint8List png = byteData.buffer.asUint8List();

      /// Save the byte data to a PNG file
      File(outputPath).writeAsBytesSync(png);

      return outputPath;
    } catch (e) {
      rethrow;
    } finally {
      if (measureTime) {
        log('saveAsPng: ${stopwatch?.elapsedMilliseconds}ms');
      }
    }
  }

  /// Get the RGBA bytes of the widget
  /// - [pixelRatio] - Pixel ratio of the image, default is [MediaQueryData.devicePixelRatio]
  Future<(Uint8List bytes, int width, int height)> getRgba({
    double? pixelRatio,
    bool measureTime = false,
  }) async {
    Stopwatch? stopwatch;
    if (measureTime) {
      stopwatch = Stopwatch()..start();
    }

    pixelRatio ??= _repaintKey.currentContext
            ?.getInheritedWidgetOfExactType<MediaQuery>()
            ?.data
            .devicePixelRatio ??
        1.0;

    final boundary = _repaintKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw Exception('Не найден RenderRepaintBoundary');
    }
    final image = boundary.toImageSync(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (byteData == null) throw Exception('Не удалось получить байты');

    if (measureTime) {
      stopwatch?.stop();
      log('getRgba: ${stopwatch?.elapsedMilliseconds}ms');
    }

    return (
      byteData.buffer.asUint8List(),
      image.width,
      image.height,
    );
  }

  /// Convert to JPEG using isolate pool (for multiple images)
  Future<void> _saveAsJpegWithPoolInternal({
    required String outputPath,
    required Uint8List bytes,
    required int width,
    required int height,
    int quality = 90,
    bool measureTime = false,
    bool calculateSize = false,
  }) async {
    Stopwatch? stopwatchSave;
    Stopwatch? stopwatchConvert;
    if (measureTime) {
      stopwatchSave = Stopwatch();
      stopwatchConvert = Stopwatch();
    }

    try {
      stopwatchSave?.start();
      final tempPath = '${outputPath}_temp.rgba';

      /// Save the byte data to a PNG file
      File(tempPath).writeAsBytesSync(bytes);

      stopwatchSave?.stop();

      /// Convert the RGBA file to a JPEG file using pool
      stopwatchConvert?.start();
      await convertToJpegWithPool(tempPath, width, height);
      stopwatchConvert?.stop();

      /// Delete the temporary file
      File(tempPath).deleteSync();

      if (calculateSize) {
        final file = File(outputPath);
        final size = file.lengthSync();
        final sizeKb = size / 1024;
        final sizeMb = sizeKb / 1024;
        log('size: $size bytes ($sizeKb kb, $sizeMb mb)');
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    } finally {
      if (measureTime) {
        stopwatchSave?.stop();
        stopwatchConvert?.stop();

        final sb = StringBuffer();
        sb
          ..write(
            'saveAsJpegWithPool save: ${stopwatchSave?.elapsedMilliseconds}ms\n',
          )
          ..write(
            'saveAsJpegWithPool convert: ${stopwatchConvert?.elapsedMilliseconds}ms\n',
          );
        log(sb.toString());
      }
    }
  }

  void convertToJpeg({
    required String outputPath,
    required Uint8List bytes,
    required int width,
    required int height,
    int quality = 90,
    bool measureTime = false,
    bool calculateSize = false,
  }) async {
    Stopwatch? stopwatchSave;
    Stopwatch? stopwatchConvert;
    if (measureTime) {
      stopwatchSave = Stopwatch();
      stopwatchConvert = Stopwatch();
    }

    try {
      stopwatchSave?.start();
      final tempPath = '${outputPath}_temp.rgba';

      /// Save the byte data to a PNG file
      File(tempPath).writeAsBytesSync(bytes);

      stopwatchSave?.stop();

      /// Convert the RGBA file to a JPEG file
      stopwatchConvert?.start();
      convertRgbaFileToJpeg(
        tempPath,
        width,
        height,
        quality,
        outputPath,
      );
      stopwatchConvert?.stop();

      /// Delete the temporary file
      File(tempPath).deleteSync();

      if (calculateSize) {
        final file = File(outputPath);
        final size = file.lengthSync();
        final sizeKb = size / 1024;
        final sizeMb = sizeKb / 1024;
        log('size: $size bytes ($sizeKb kb, $sizeMb mb)');
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    } finally {
      if (measureTime) {
        stopwatchSave?.stop();
        stopwatchConvert?.stop();

        final sb = StringBuffer();
        sb
          ..write(
            'convertToJpeg save: ${stopwatchSave?.elapsedMilliseconds}ms\n',
          )
          ..write(
            'convertToJpeg convert: ${stopwatchConvert?.elapsedMilliseconds}ms\n',
          );
        log(sb.toString());
      }
    }
  }

  /// Save the widget as a JPEG using isolate pool (for multiple images)
  /// - [outputPath] - Path to the saved JPEG file
  /// - [pixelRatio] - Pixel ratio of the image, default is 1.0
  /// - [quality] - Quality of the image, 0-100
  /// - [measureTime] - Whether to count the speed of the conversion
  Future<String> saveAsJpegWithPool({
    required String outputPath,
    double? pixelRatio,
    int quality = 90,
    bool measureTime = false,
    bool calculateSize = false,
  }) async {
    Stopwatch? stopwatch;

    if (measureTime) {
      stopwatch = Stopwatch()..start();
    }

    try {
      final (bytes, width, height) = await getRgba(
        pixelRatio: pixelRatio,
        measureTime: measureTime,
      );

      await _saveAsJpegWithPoolInternal(
        outputPath: outputPath,
        bytes: bytes,
        width: width,
        height: height,
        quality: quality,
        measureTime: measureTime,
        calculateSize: calculateSize,
      );

      return outputPath;
    } catch (e) {
      log(e.toString());
      rethrow;
    } finally {
      if (measureTime) {
        stopwatch?.stop();
        log('saveAsJpegWithPool full: ${stopwatch?.elapsedMilliseconds}ms');
      }
    }
  }

  /// Save the widget as a RGBA file
  /// - [outputPath] - Path to the saved PNG file
  /// - [pixelRatio] - Pixel ratio of the image, default is 1.0
  /// - [quality] - Quality of the image, 0-100
  /// - [measureTime] - Whether to count the speed of the conversion
  Future<String> saveAsRgbaFile({
    required String outputPath,
    double? pixelRatio,
    int quality = 90,
    bool measureTime = false,
    bool calculateSize = false,
  }) async {
    Stopwatch? stopwatch;

    if (measureTime) {
      stopwatch = Stopwatch()..start();
    }

    try {
      final (bytes, width, height) = await getRgba(
        pixelRatio: pixelRatio,
        measureTime: measureTime,
      );

      convertToJpeg(
        outputPath: outputPath,
        bytes: bytes,
        width: width,
        height: height,
        quality: quality,
        measureTime: measureTime,
        calculateSize: calculateSize,
      );

      return outputPath;
    } catch (e) {
      log(e.toString());
      rethrow;
    } finally {
      if (measureTime) {
        stopwatch?.stop();
        log('saveAsRgbaFile full: ${stopwatch?.elapsedMilliseconds}ms');
      }
    }
  }
}
