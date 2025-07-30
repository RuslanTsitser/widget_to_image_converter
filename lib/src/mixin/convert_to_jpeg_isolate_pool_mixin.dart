import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../../widget_to_image_converter.dart';

/// Mixin for JPEG conversion using isolate pool
mixin ConvertToJpegIsolatePoolMixin {
  static final List<Worker> _workers = [];
  static final Queue<Worker> _availableWorkers = Queue();
  static bool _initialized = false;
  static int _poolSize = 4;

  /// Configure pool size (call before first use)
  static void configurePool({int? poolSize}) {
    if (_initialized) {
      throw StateError('Pool already initialized');
    }
    if (poolSize != null && poolSize > 0) {
      _poolSize = poolSize;
    }
  }

  /// Reset state (for testing only)
  @visibleForTesting
  static void reset() {
    _workers.clear();
    _availableWorkers.clear();
    _initialized = false;
    _poolSize = 4;
  }

  /// Convert to JPEG using isolate pool
  Future<void> convertToJpegWithPool(String path, int width, int height) async {
    if (!_initialized) {
      await _initializePool();
    }

    // Wait for available worker
    while (_availableWorkers.isEmpty) {
      await Future.delayed(Duration(milliseconds: 10));
    }

    final worker = _availableWorkers.removeFirst();
    try {
      await worker.convert(path, width, height);
    } finally {
      _availableWorkers.add(worker);
    }
  }

  static Future<void> _initializePool() async {
    if (_initialized) return;

    for (int i = 0; i < _poolSize; i++) {
      final worker = await Worker.spawn();
      _workers.add(worker);
      _availableWorkers.add(worker);
    }
    _initialized = true;
  }
}

/// Worker for processing tasks in isolate
class Worker {
  Worker._(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;
  bool _closed = false;

  Future<Object?> convert(String path, int width, int height) async {
    if (_closed) throw StateError('Worker closed');

    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, path, width, height));
    return completer.future;
  }

  static Future<Worker> spawn() async {
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();

    initPort.handler = (SendPort initialMessage) {
      connection.complete(
        (
          ReceivePort.fromRawReceivePort(initPort),
          initialMessage,
        ),
      );
    };

    try {
      await Isolate.spawn(_startRemoteIsolate, initPort.sendPort);
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) =
        await connection.future;
    return Worker._(receivePort, sendPort);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    final (int id, Object? response) = message as (int, Object?);
    final completer = _activeRequests.remove(id)!;

    if (response is RemoteError) {
      completer.completeError(response);
    } else {
      completer.complete(response);
    }

    if (_closed && _activeRequests.isEmpty) {
      _responses.close();
    }
  }

  static void _handleCommandsToIsolate(
    ReceivePort receivePort,
    SendPort sendPort,
  ) {
    receivePort.listen((message) async {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }

      final (int id, String path, int width, int height) =
          message as (int, String, int, int);

      try {
        _convertToJpeg(path, width, height);
        sendPort.send((id, true));
      } catch (e) {
        sendPort.send((id, RemoteError(e.toString(), '')));
      }
    });
  }

  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, sendPort);
  }

  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) {
        _responses.close();
      }
    }
  }
}

void _convertToJpeg(String outputPath, int width, int height) {
  final tempPath = '${outputPath}_temp.rgba';

  File(outputPath).copySync(tempPath);

  convertRgbaFileToJpeg(
    tempPath,
    width,
    height,
    90,
    outputPath,
  );
  File(tempPath).deleteSync();
}
