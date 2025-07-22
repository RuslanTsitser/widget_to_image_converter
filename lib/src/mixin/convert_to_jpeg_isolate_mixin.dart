import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import '../../widget_to_image_converter.dart';

/// Mixin for converting a widget to a JPEG image using an isolate
mixin ConvertToJpegIsolateMixin {
  Worker? _worker;

  /// Get the current worker instance (for testing purposes)
  Worker? get worker => _worker;

  /// Initialize the isolate
  Future<void> initIsolate() async {
    _worker ??= await Worker.spawn();
  }

  /// Convert a widget to a JPEG image using an isolate
  Future<void> convertToJpegAsync(String path, int width, int height) async {
    if (_worker == null) {
      await initIsolate();
    }
    await _worker!.convert(path, width, height);
  }

  /// Dispose the isolate
  void disposeIsolate() {
    _worker?.close();
    _worker = null;
  }
}

/// Asynchronous queue for processing tasks in the isolate
class IsolateQueue {
  final Queue<_QueueItem> _queue = Queue();
  bool _isProcessing = false;

  /// Add a task to the queue and return a Future that will complete after the task is executed
  Future<void> addTask(Future<void> Function() task) async {
    final completer = Completer<void>();
    _queue.add(_QueueItem(task, completer));

    if (!_isProcessing) {
      _processQueue();
    }

    return completer.future;
  }

  /// Get the number of tasks in the queue
  int get queueLength => _queue.length;

  /// Check if the queue is being processed
  bool get isProcessing => _isProcessing;

  /// Process the queue of tasks sequentially
  Future<void> _processQueue() async {
    if (_isProcessing) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final item = _queue.removeFirst();
      try {
        await item.task();
        item.completer.complete();
      } catch (e) {
        item.completer.completeError(e);
      }
    }

    _isProcessing = false;
  }
}

class _QueueItem {
  final Future<void> Function() task;
  final Completer<void> completer;

  _QueueItem(this.task, this.completer);
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
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, path, width, height));
    return completer.future;
  }

  static Future<Worker> spawn() async {
    // Create a receive port and add its initial message handler
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

    // Spawn the isolate.
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

    if (_closed && _activeRequests.isEmpty) _responses.close();
  }

  static void _handleCommandsToIsolate(
    ReceivePort receivePort,
    SendPort sendPort,
  ) {
    final queue = IsolateQueue();

    receivePort.listen((message) async {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }

      final (int id, String path, int width, int height) =
          message as (int, String, int, int);

      try {
        // Add a task to the queue and wait for it to complete
        await queue.addTask(() async {
          _convertToJpeg(path, width, height);
        });

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
      if (_activeRequests.isEmpty) _responses.close();
    }
  }
}
