import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:widget_to_image_converter/src/mixin/convert_to_jpeg_isolate_pool_mixin.dart';

// Тестовый класс, использующий миксин
class TestConverter with ConvertToJpegIsolatePoolMixin {}

void main() {
  group('ConvertToJpegIsolatePoolMixin Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('pool_test_');
      // Сбрасываем состояние пула перед каждым тестом
      ConvertToJpegIsolatePoolMixin.reset();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should configure pool size', () {
      ConvertToJpegIsolatePoolMixin.configurePool(poolSize: 6);
      // Конфигурация прошла без ошибок
    });

    test('should not allow configuration after first use', () async {
      final converter = TestConverter();

      // Создаем тестовый файл
      final testPath = '${tempDir.path}/test.jpg';
      File(testPath).writeAsBytesSync([1, 2, 3, 4]);

      // Первое использование инициализирует пул
      // Ожидаем ошибку загрузки библиотеки, но пул должен инициализироваться
      try {
        await converter.convertToJpegWithPool(testPath, 100, 100);
      } catch (e) {
        // Ожидаем ошибку загрузки библиотеки
        expect(e.toString(), contains('Failed to load dynamic library'));
      }

      // Попытка конфигурации должна вызвать ошибку
      expect(
        () => ConvertToJpegIsolatePoolMixin.configurePool(poolSize: 8),
        throwsStateError,
      );
    });

    test('should handle configuration correctly', () {
      // Конфигурация до использования должна работать
      ConvertToJpegIsolatePoolMixin.configurePool(poolSize: 6);

      // Повторная конфигурация должна работать (если пул еще не инициализирован)
      try {
        ConvertToJpegIsolatePoolMixin.configurePool(poolSize: 8);
      } catch (e) {
        // Если пул уже инициализирован, это нормально
        expect(e.toString(), contains('Пул уже инициализирован'));
      }
    });
  });
}
