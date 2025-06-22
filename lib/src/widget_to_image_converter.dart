// You have generated a new plugin project without specifying the `--platforms`
// flag. An FFI plugin project that supports no platforms is generated.
// To add platforms, run `flutter create -t plugin_ffi --platforms <platforms> .`
// in this directory. You can also find a detailed instruction on how to
// add platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'widget_to_image_converter_bindings_generated.dart';

const String _libName = 'widget_to_image_converter';

/// The dynamic library in which the symbols for [WidgetToImageConverterBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final WidgetToImageConverterBindings _bindings = WidgetToImageConverterBindings(
  _dylib,
);

/// Convert RGBA image data to JPEG and save to file
///
/// Parameters:
///   rgbaData: RGBA image data (4 bytes per pixel: R, G, B, A)
///   width: Image width in pixels
///   height: Image height in pixels
///   quality: JPEG quality (1-100)
///   outputPath: Path where to save the JPEG file
///
String convertRgbaToJpeg(
  Uint8List rgbaData,
  int width,
  int height,
  int quality,
  String outputPath,
) {
  // Validate parameters
  if (rgbaData.isEmpty) {
    throw ArgumentError('RGBA data cannot be empty');
  }
  if (width <= 0 || height <= 0) {
    throw ArgumentError('Width and height must be positive');
  }
  if (quality < 1 || quality > 100) {
    throw ArgumentError('Quality must be between 1 and 100');
  }
  if (outputPath.isEmpty) {
    throw ArgumentError('Output path cannot be empty');
  }

  // Check if data size matches dimensions
  final expectedSize = width * height * 4;
  if (rgbaData.length != expectedSize) {
    throw ArgumentError(
      'RGBA data size (${rgbaData.length}) does not match dimensions '
      '(${width}x${height}x4 = $expectedSize)',
    );
  }

  // Allocate memory for RGBA data
  final Pointer<Uint8> rgbaPtr = calloc<Uint8>(rgbaData.length);
  rgbaPtr.asTypedList(rgbaData.length).setAll(0, rgbaData);

  // Convert output path to C string
  final Pointer<Char> outputPathPtr = outputPath.toNativeUtf8().cast<Char>();

  // Call C function
  final Pointer<Char> resultPtr = _bindings.convert_rgba_to_jpeg(
    rgbaPtr,
    width,
    height,
    quality,
    outputPathPtr,
  );

  // Free allocated memory
  calloc.free(rgbaPtr);
  calloc.free(outputPathPtr);

  // Check if conversion was successful
  if (resultPtr == nullptr) {
    throw Exception('Failed to convert RGBA to JPEG');
  }

  // Get the actual path where the file was saved
  final String actualPath = resultPtr.cast<Utf8>().toDartString();

  // Free the result pointer (allocated in C)
  calloc.free(resultPtr);

  return actualPath;
}

/// Convert RGBA file to JPEG and save to file
///
/// Parameters:
///   inputPath: Path to the input RGBA file
///   width: Image width in pixels
///   height: Image height in pixels
///   quality: JPEG quality (1-100)
///   outputPath: Path where to save the JPEG file
///
String convertRgbaFileToJpeg(
  String inputPath,
  int width,
  int height,
  int quality,
  String outputPath,
) {
  // Validate parameters
  if (inputPath.isEmpty) {
    throw ArgumentError('Input path cannot be empty');
  }
  if (width <= 0 || height <= 0) {
    throw ArgumentError('Width and height must be positive');
  }
  if (quality < 1 || quality > 100) {
    throw ArgumentError('Quality must be between 1 and 100');
  }
  if (outputPath.isEmpty) {
    throw ArgumentError('Output path cannot be empty');
  }

  // Convert paths to C strings
  final Pointer<Char> inputPathPtr = inputPath.toNativeUtf8().cast<Char>();
  final Pointer<Char> outputPathPtr = outputPath.toNativeUtf8().cast<Char>();

  // Call C function
  final Pointer<Char> resultPtr = _bindings.convert_rgba_file_to_jpeg(
    inputPathPtr,
    width,
    height,
    quality,
    outputPathPtr,
  );

  // Free allocated memory
  calloc.free(inputPathPtr);
  calloc.free(outputPathPtr);

  // Check if conversion was successful
  if (resultPtr == nullptr) {
    throw Exception('Failed to convert RGBA file to JPEG');
  }

  // Get the actual path where the file was saved
  final String actualPath = resultPtr.cast<Utf8>().toDartString();

  // Free the result pointer (allocated in C)
  calloc.free(resultPtr);

  return actualPath;
}
