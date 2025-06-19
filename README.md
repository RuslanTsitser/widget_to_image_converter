# Widget to Image Converter

Flutter FFI плагин для конвертации виджетов в изображения JPEG и PNG с использованием нативного C кода.

## 🚀 Возможности

- Конвертация Flutter виджетов в изображения JPEG и PNG
- Автоматическое управление состоянием конвертации
- Настройка качества JPEG (1-100)
- Поддержка различных pixel ratio
- Автономная работа без внешних зависимостей
- Кроссплатформенная поддержка (iOS, Android, macOS, Linux, Windows)
- Использование однофайловой библиотеки stb_image_write.h для JPEG
- Встроенная поддержка PNG через Flutter

## 📦 Установка

Добавьте в `pubspec.yaml` вашего проекта:

```yaml
dependencies:
  widget_to_image_converter: ^0.0.1
  path_provider: ^2.0.0  # для получения путей к директориям
```

## 🔧 Использование

### Простое использование с Provider

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
          // Оборачиваем виджет, который хотим конвертировать
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
                  'Конвертируемый виджет',
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
          // Кнопки для конвертации
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
                child: const Text('Сохранить как JPEG'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  final controller = WidgetToImageProvider.of(context, listen: false);
                  final tempDir = await getTemporaryDirectory();
                  final outputPath = '${tempDir.path}/widget_${DateTime.now().millisecondsSinceEpoch}.png';
                  await controller.saveAsPng(outputPath: outputPath);
                },
                child: const Text('Сохранить как PNG'),
              ),
            ],
          ),
          // Отображение результата
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
            const Text('Ошибка конвертации', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
```

### Расширенное использование с контроллером

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
      quality: 95, // Высокое качество
      pixelRatio: 2.0, // Высокое разрешение
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
              child: const Text('Сохранить с настройками'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Прямое использование FFI функции

Для прямого использования нативной функции конвертации:

```dart
import 'package:widget_to_image_converter/widget_to_image_converter.dart';
import 'dart:typed_data';

// Конвертация RGBA данных в JPEG
String? convertRgbaToJpeg(
  Uint8List rgbaData,  // RGBA данные изображения (4 байта на пиксель)
  int width,           // Ширина изображения в пикселях
  int height,          // Высота изображения в пикселях
  int quality,         // Качество JPEG (1-100)
  String outputPath,   // Путь для сохранения JPEG файла
);
```

## 📋 API Справочник

### WidgetToImageProvider

Для передачи контроллера в виджеты через `InheritedWidget`.

**Конструктор:**

```dart
WidgetToImageProvider({
  Key? key,
  required Widget child,
  WidgetToImageController? controller,
})
```

**Статические методы:**

- `WidgetToImageController of(BuildContext context, {bool listen = true})` - Получить контроллер

### WidgetToImageController

Контроллер для управления процессом конвертации.

**Свойства:**

- `GlobalKey repaintKey` - Ключ для RepaintBoundary
- `WidgetToImageStatus status` - Текущий статус конвертации
- `String? jpegPath` - Путь к сохраненному JPEG файлу
- `String? pngPath` - Путь к сохраненному PNG файлу

**Методы:**

- `Future<void> saveAsJpeg({required String outputPath, double? pixelRatio, int quality = 90})` - Сохранить как JPEG
- `Future<void> saveAsPng({required String outputPath, double? pixelRatio})` - Сохранить как PNG
- `void dispose()` - Освободить ресурсы

### WidgetToImageWrapper

Виджет-обертка для автоматического создания RepaintBoundary.

**Конструктор:**

```dart
WidgetToImageWrapper({Key? key, required Widget child})
```

### WidgetToImageStatus

Перечисление статусов конвертации:

- `idle` - Ожидание
- `saving` - Сохранение
- `saved` - Сохранено
- `error` - Ошибка

### convertRgbaToJpeg

Нативная функция для конвертации RGBA данных в JPEG.

**Параметры:**

- `rgbaData` (Uint8List): RGBA данные изображения (4 байта на пиксель: R, G, B, A)
- `width` (int): Ширина изображения в пикселях
- `height` (int): Высота изображения в пикселях
- `quality` (int): Качество JPEG (1-100)
- `outputPath` (String): Путь для сохранения JPEG файла

**Возвращает:**

- `String`: Путь к сохраненному JPEG файлу

**Исключения:**

- `ArgumentError`: Если параметры неверны
- `Exception`: Если конвертация не удалась

## ⚙️ Требования

- Dart 3.0.0 или выше

## 🖥️ Поддержка платформ

- ✅ iOS
- ✅ Android
- ✅ macOS
- Linux - пока не протестировано
- Windows - пока не протестировано

## 🔍 Детали реализации

### Процесс конвертации

1. **Получение изображения**: Используется `RepaintBoundary` для захвата виджета
2. **Извлечение данных**: RGBA данные извлекаются из `ui.Image`
3. **Конвертация JPEG**: Используется нативная C функция с stb_image_write.h
4. **Сохранение PNG**: Используется встроенный метод Flutter
5. **Обновление состояния**: Контроллер уведомляет о изменениях через `ChangeNotifier`

### Технические детали

- **FFI привязки**: Автоматически генерируются с помощью ffigen
- **Память**: Правильное выделение и освобождение памяти через FFI
- **Ошибки**: Валидация параметров и обработка ошибок на C и Dart сторонах
- **Состояние**: Реактивное обновление UI через ChangeNotifier

## 📝 Примеры использования

### Мониторинг статуса конвертации

```dart
class StatusMonitor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = WidgetToImageProvider.of(context, listen: true);
  
    switch (controller.status) {
      case WidgetToImageStatus.idle:
        return const Text('Готов к конвертации');
      case WidgetToImageStatus.saving:
        return const CircularProgressIndicator();
      case WidgetToImageStatus.saved:
        return const Text('Конвертация завершена');
      case WidgetToImageStatus.error:
        return const Text('Ошибка конвертации', style: TextStyle(color: Colors.red));
    }
  }
}
```

### Кастомные настройки качества

```dart
// Высокое качество для печати
await controller.saveAsJpeg(
  outputPath: path,
  quality: 95,
  pixelRatio: 2.0,
);

// Низкое качество для веба
await controller.saveAsJpeg(
  outputPath: path,
  quality: 70,
  pixelRatio: 1.0,
);
```

### Обработка ошибок

```dart
try {
  await controller.saveAsJpeg(outputPath: path);
  print('Успешно сохранено: ${controller.jpegPath}');
} catch (e) {
  print('Ошибка конвертации: $e');
}
```

## 📄 Лицензия

Этот проект лицензирован под MIT License - см. файл LICENSE для деталей.
