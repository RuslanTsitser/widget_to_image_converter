import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:widget_to_image_converter/widget_to_image_converter.dart';

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
    return const Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Widget to Image Converter'),
            centerTitle: true,
            pinned: true,
          ),
          SliverToBoxAdapter(child: InitialImage()),
          SliverToBoxAdapter(child: ButtonsRow()),
          SliverToBoxAdapter(child: ResultRow()),
        ],
      ),
    );
  }
}

class InitialImage extends StatelessWidget {
  const InitialImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 200,
        child: WidgetToImageWrapper(
          child: Image.network(
            'https://picsum.photos/2000/2000',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class ButtonsRow extends StatefulWidget {
  const ButtonsRow({super.key});

  @override
  State<ButtonsRow> createState() => _ButtonsRowState();
}

class _ButtonsRowState extends State<ButtonsRow> {
  String _pngLength = '';
  String _pngTime = '';
  String _jpegLength = '';
  String _jpegTime = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          Column(
            spacing: 10,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final controller = WidgetToImageProvider.of(
                    context,
                    listen: false,
                  );
                  final now = DateTime.now().millisecondsSinceEpoch;
                  final tempDir = await getTemporaryDirectory();
                  final outputPath = '${tempDir.path}/test_$now.png';
                  final Stopwatch stopwatch = Stopwatch()..start();
                  await controller.saveAsPng(outputPath: outputPath);
                  stopwatch.stop();
                  _pngTime = 'PNG saved in ${stopwatch.elapsedMilliseconds}ms';
                  final length = File(outputPath).lengthSync();
                  final lengthKb = length / 1024;
                  _pngLength = 'PNG length: ${lengthKb.toStringAsFixed(2)} KB';
                  log(_pngTime);
                  log(_pngLength);
                  setState(() {});
                },
                child: const Text('Save PNG'),
              ),
              Text(_pngTime),
              Text(_pngLength),
            ],
          ),
          Column(
            spacing: 10,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final controller = WidgetToImageProvider.of(
                    context,
                    listen: false,
                  );
                  final now = DateTime.now().millisecondsSinceEpoch;
                  final tempDir = await getTemporaryDirectory();
                  final outputPath = '${tempDir.path}/test_$now.jpg';
                  final Stopwatch stopwatch = Stopwatch()..start();
                  await controller.saveAsJpeg(outputPath: outputPath);
                  stopwatch.stop();
                  _jpegTime =
                      'JPEG saved in ${stopwatch.elapsedMilliseconds}ms';
                  final length = File(outputPath).lengthSync();
                  final lengthKb = length / 1024;
                  _jpegLength =
                      'JPEG length: ${lengthKb.toStringAsFixed(2)} KB';
                  log(_jpegTime);
                  log(_jpegLength);
                  setState(() {});
                },
                child: const Text('Save JPEG'),
              ),
              Text(_jpegTime),
              Text(_jpegLength),
            ],
          ),
        ],
      ),
    );
  }
}

class ResultRow extends StatelessWidget {
  const ResultRow({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = WidgetToImageProvider.of(context, listen: true);
    final pngPath = controller.pngPath;
    final jpegPath = controller.jpegPath;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            if (pngPath != null)
              Expanded(child: Image.file(File(pngPath), fit: BoxFit.cover)),
            if (jpegPath != null)
              Expanded(child: Image.file(File(jpegPath), fit: BoxFit.cover)),
          ],
        ),
      ),
    );
  }
}
