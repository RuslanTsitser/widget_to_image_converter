import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:widget_to_image_converter/src/widget_to_image_converter.dart';

void main() {
  group('WidgetToImageConverter Tests', () {
    test('convertRgbaToJpeg should convert RGBA data to JPEG', () {
      // Create a simple 2x2 RGBA image (red, green, blue, white)
      final Uint8List rgbaData = Uint8List.fromList([
        255, 0, 0, 255, // Red
        0, 255, 0, 255, // Green
        0, 0, 255, 255, // Blue
        255, 255, 255, 255, // White
      ]);

      // Create a temporary directory for testing
      final Directory tempDir = Directory.systemTemp;
      final String outputPath = '${tempDir.path}/test_image.jpg';

      // Convert to JPEG
      convertRgbaToJpeg(
        rgbaData,
        2, // width
        2, // height
        90, // quality
        outputPath,
      );

      // Check if conversion was successful
      expect(outputPath, isNotNull);
      expect(outputPath, isNotEmpty);

      // Check if file was created
      final File resultFile = File(outputPath);
      expect(resultFile.existsSync(), isTrue);
      expect(resultFile.lengthSync(), greaterThan(0));

      // Clean up
      resultFile.deleteSync();
    });

    test('convertRgbaToJpeg should throw ArgumentError for empty data', () {
      expect(
        () => convertRgbaToJpeg(Uint8List(0), 100, 100, 90, '/tmp/test.jpg'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'convertRgbaToJpeg should throw ArgumentError for invalid dimensions',
      () {
        expect(
          () => convertRgbaToJpeg(Uint8List(100), 0, 100, 90, '/tmp/test.jpg'),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'convertRgbaToJpeg should throw ArgumentError for invalid quality',
      () {
        expect(
          () => convertRgbaToJpeg(Uint8List(100), 10, 10, 0, '/tmp/test.jpg'),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'convertRgbaToJpeg should throw ArgumentError for invalid data size',
      () {
        // Create data with wrong size
        final Uint8List rgbaData = Uint8List(100); // 100 bytes for 10x10 image

        expect(
          () => convertRgbaToJpeg(
            rgbaData,
            10, // width
            10, // height
            90, // quality
            '/tmp/test.jpg',
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('convertRgbaToJpeg should handle directory path correctly', () {
      // Create a simple 1x1 RGBA image
      final Uint8List rgbaData = Uint8List.fromList([
        255,
        0,
        0,
        255,
      ]); // Red pixel

      // Create a temporary directory for testing
      final Directory tempDir = Directory.systemTemp;
      final String outputPath = '${tempDir.path}/test_image.jpg';

      // Convert to JPEG
      convertRgbaToJpeg(
        rgbaData,
        1, // width
        1, // height
        90, // quality
        outputPath,
      );

      // Check if conversion was successful
      expect(outputPath, isNotNull);
      expect(outputPath, isNotEmpty);

      // Check if file was created
      final File resultFile = File(outputPath);
      expect(resultFile.existsSync(), isTrue);
      expect(resultFile.lengthSync(), greaterThan(0));

      // Clean up
      resultFile.deleteSync();
    });
  });
}
