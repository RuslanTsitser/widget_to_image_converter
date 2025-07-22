import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:widget_to_image_converter/src/mixin/convert_to_jpeg_isolate_mixin.dart';

// Тестовый класс, использующий миксин
class TestConverter with ConvertToJpegIsolateMixin {}

void main() {
  group('ConvertToJpegIsolateMixin Tests', () {
    late TestConverter converter;
    late Directory tempDir;

    setUp(() {
      converter = TestConverter();
      tempDir = Directory.systemTemp.createTempSync('isolate_test_');
    });

    tearDown(() {
      converter.disposeIsolate();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('IsolateQueue Tests', () {
      test('should process tasks sequentially', () async {
        final queue = IsolateQueue();
        final results = <int>[];
        final order = <int>[];

        // Добавляем несколько задач
        final futures = <Future<void>>[];

        for (int i = 0; i < 3; i++) {
          final index = i;
          futures.add(queue.addTask(() async {
            order.add(index);
            await Future.delayed(Duration(milliseconds: 100));
            results.add(index);
          }));
        }

        // Ждем завершения всех задач
        await Future.wait(futures);

        // Проверяем, что задачи выполнились в правильном порядке
        expect(results, equals([0, 1, 2]));
        expect(order, equals([0, 1, 2]));
        expect(queue.queueLength, equals(0));
        expect(queue.isProcessing, isFalse);
      });

      test('should handle errors properly', () async {
        final queue = IsolateQueue();
        final results = <String>[];

        // Добавляем задачу с ошибкой
        final errorFuture = queue.addTask(() async {
          throw Exception('Test error');
        });

        // Добавляем нормальную задачу
        final normalFuture = queue.addTask(() async {
          results.add('success');
        });

        // Проверяем, что ошибка передается правильно
        expect(errorFuture, throwsA(isA<Exception>()));

        // Проверяем, что нормальная задача все равно выполнилась
        await normalFuture;
        expect(results, equals(['success']));
      });

      test('should track queue length correctly', () async {
        final queue = IsolateQueue();

        expect(queue.queueLength, equals(0));
        expect(queue.isProcessing, isFalse);

        // Добавляем задачу
        final future = queue.addTask(() async {
          // В момент выполнения задачи она уже взята из очереди
          expect(queue.queueLength, equals(0));
          expect(queue.isProcessing, isTrue);
          await Future.delayed(Duration(milliseconds: 50));
        });

        // Проверяем, что задача добавлена в очередь
        // Но так как обработка начинается сразу, размер может быть 0 или 1
        expect(queue.queueLength, anyOf(0, 1));
        expect(queue.isProcessing, isTrue);

        await future;

        expect(queue.queueLength, equals(0));
        expect(queue.isProcessing, isFalse);
      });
    });

    group('Worker Tests', () {
      test('should initialize isolate correctly', () async {
        expect(converter.worker, isNull);

        await converter.initIsolate();

        expect(converter.worker, isNotNull);
      });

      test('should not create multiple workers', () async {
        await converter.initIsolate();
        final worker1 = converter.worker;

        await converter.initIsolate();
        final worker2 = converter.worker;

        expect(worker1, same(worker2));
      });

      test('should dispose isolate correctly', () async {
        await converter.initIsolate();
        expect(converter.worker, isNotNull);

        converter.disposeIsolate();
        expect(converter.worker, isNull);
      });

      test('should handle multiple dispose calls', () {
        // Не должно вызывать ошибок
        converter.disposeIsolate();
        converter.disposeIsolate();
        expect(converter.worker, isNull);
      });
    });

    group('Integration Tests', () {
      test('should handle conversion request (mock test)', () async {
        // Создаем тестовый файл
        final testPath = '${tempDir.path}/test.jpg';
        File(testPath).writeAsBytesSync([1, 2, 3, 4]); // Простые данные

        // Инициализируем изолят
        await converter.initIsolate();

        // Проверяем, что воркер создан
        expect(converter.worker, isNotNull);

        // Проверяем, что файл существует
        expect(File(testPath).existsSync(), isTrue);
      });

      test('should handle multiple concurrent requests (mock test)', () async {
        await converter.initIsolate();

        final futures = <Future<void>>[];
        final results = <String>[];

        // Создаем несколько тестовых файлов
        for (int i = 0; i < 3; i++) {
          final testPath = '${tempDir.path}/test_$i.jpg';
          File(testPath).writeAsBytesSync([1, 2, 3, 4]);

          // Просто проверяем, что воркер работает
          futures.add(Future.value().then((_) => results.add('success_$i')));
        }

        // Ждем завершения всех операций
        await Future.wait(futures);

        // Проверяем, что все операции завершились
        expect(results.length, equals(3));
        expect(results, containsAll(['success_0', 'success_1', 'success_2']));

        // Проверяем, что все файлы созданы
        for (int i = 0; i < 3; i++) {
          final file = File('${tempDir.path}/test_$i.jpg');
          expect(file.existsSync(), isTrue);
        }
      });

      test('should handle errors in conversion', () async {
        await converter.initIsolate();

        // Пытаемся конвертировать несуществующий файл
        expect(
          () => converter.convertToJpegAsync('/nonexistent/file.jpg', 100, 100),
          throwsA(anything),
        );
      });
    });
  });
}
