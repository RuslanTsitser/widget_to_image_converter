# Widget to Image Converter

Flutter FFI плагин для конвертации виджетов в изображения JPEG с использованием нативного C кода.

## 🚀 Возможности

- Конвертация RGBA данных изображения в формат JPEG
- Сохранение конвертированных изображений в файловую систему
- Настройка качества JPEG (1-100)
- Автономная работа без внешних зависимостей
- Кроссплатформенная поддержка (iOS, Android, macOS, Linux, Windows)
- Использование однофайловой библиотеки stb_image_write.h

## 📦 Установка

Добавьте в `pubspec.yaml` вашего проекта:

```yaml
dependencies:
  widget_to_image_converter: ^0.0.1
  path_provider: ^2.0.0  # для получения путей к директориям
```

## 🔧 Использование

### Базовое использование

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

### Пример: Конвертация Flutter виджета в JPEG

```dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:widget_to_image_converter/widget_to_image_converter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ImageConverterExample extends StatefulWidget {
  @override
  _ImageConverterExampleState createState() => _ImageConverterExampleState();
}

class _ImageConverterExampleState extends State<ImageConverterExample> {
  final GlobalKey _widgetKey = GlobalKey();
  String? _convertedImagePath;

  Widget _buildTargetWidget() {
    return RepaintBoundary(
      key: _widgetKey,
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
        child: Center(
          child: Text(
            'Конвертированный виджет',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _convertWidgetToImage() async {
    try {
      // Ждем рендеринга виджета
      await Future.delayed(Duration(milliseconds: 100));
    
      // Получаем RenderRepaintBoundary
      final RenderRepaintBoundary? boundary = 
          _widgetKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    
      if (boundary == null) {
        throw Exception('Не удалось найти RenderRepaintBoundary');
      }

      // Получаем изображение
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    
      if (byteData != null) {
        final Uint8List rgbaData = byteData.buffer.asUint8List();
      
        // Получаем директорию документов для сохранения
        final Directory documentsDir = await getApplicationDocumentsDirectory();
        final String outputPath = '${documentsDir.path}/converted_image.jpg';
      
        // Конвертируем в JPEG используя нашу нативную функцию
        final String? resultPath = convertRgbaToJpeg(
          rgbaData,
          image.width,
          image.height,
          90, // качество
          outputPath,
        );
      
        setState(() {
          _convertedImagePath = resultPath;
        });
      
        if (resultPath != null) {
          print('Изображение сохранено в: $resultPath');
        } else {
          print('Ошибка конвертации изображения');
        }
      }
    } catch (e) {
      print('Ошибка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Пример конвертера изображений')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTargetWidget(),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _convertWidgetToImage,
              child: Text('Конвертировать в JPEG'),
            ),
            if (_convertedImagePath != null) ...[
              SizedBox(height: 20),
              Text('Конвертированное изображение:'),
              SizedBox(height: 10),
              Image.file(File(_convertedImagePath!)),
            ],
          ],
        ),
      ),
    );
  }
}
```

## 📋 API Справочник

### `convertRgbaToJpeg`

Конвертирует RGBA данные изображения в формат JPEG и сохраняет в файл.

**Параметры:**

- `rgbaData` (Uint8List): RGBA данные изображения (4 байта на пиксель: R, G, B, A)
- `width` (int): Ширина изображения в пикселях
- `height` (int): Высота изображения в пикселях
- `quality` (int): Качество JPEG (1-100)
- `outputPath` (String): Путь для сохранения JPEG файла

**Возвращает:**

- `String?`: Путь к сохраненному JPEG файлу, или null если конвертация не удалась

**Исключения:**

- `ArgumentError`: Если параметры неверны

## ⚙️ Требования

- Flutter 3.3.0 или выше
- Dart 3.8.1 или выше

## 🖥️ Поддержка платформ

- ✅ iOS
- ✅ Android
- ✅ macOS
- ✅ Linux
- ✅ Windows

## 🔍 Детали реализации

Плагин использует нативный C код для выполнения конвертации JPEG. C функция:

1. Проверяет входные параметры
2. Генерирует уникальное имя файла, если указана только директория
3. Создает JPEG файл с правильными заголовками
4. Конвертирует RGBA данные в RGB (пропуская альфа-канал)
5. Записывает данные изображения в файл
6. Возвращает полный путь к сохраненному файлу

Реализация включает правильное управление памятью и обработку ошибок.

### Технические детали

- **Использует stb_image_write.h**: Однофайловая библиотека без внешних зависимостей
- **FFI привязки**: Автоматически генерируются с помощью ffigen
- **Память**: Правильное выделение и освобождение памяти через FFI
- **Ошибки**: Валидация параметров и обработка ошибок на C и Dart сторонах

## 📝 Примеры использования

### Конвертация виджета с кастомными настройками

```dart
// Высокое качество для печати
final String? highQualityPath = convertRgbaToJpeg(
  rgbaData, image.width, image.height, 95, outputPath
);

// Низкое качество для веба
final String? webQualityPath = convertRgbaToJpeg(
  rgbaData, image.width, image.height, 70, outputPath
);
```

### Обработка ошибок

```dart
try {
  final String? result = convertRgbaToJpeg(rgbaData, width, height, quality, path);
  if (result != null) {
    print('Успешно сохранено: $result');
  } else {
    print('Ошибка конвертации');
  }
} catch (e) {
  print('Ошибка: $e');
}
```

## 📄 Лицензия

Этот проект лицензирован под MIT License - см. файл LICENSE для деталей.
