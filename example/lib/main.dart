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
    return const DefaultTabController(
      length: 3,
      child: Scaffold(
        body: CustomScrollView(
          physics: NeverScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              title: Text('Widget to Image Converter'),
              centerTitle: true,
              pinned: true,
            ),
            SliverToBoxAdapter(child: InitialImage()),
            SliverToBoxAdapter(
              child: TabBar(
                tabs: [
                  Tab(text: 'PNG'),
                  Tab(text: 'JPEG'),
                  Tab(text: 'RGBA'),
                ],
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                children: [
                  _Tab(tabType: TabType.png),
                  _Tab(tabType: TabType.jpeg),
                  _Tab(tabType: TabType.rgba),
                ],
              ),
            ),
          ],
        ),
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

enum TabType {
  png,
  jpeg,
  rgba;

  String get ext => switch (this) {
    TabType.png => 'png',
    TabType.jpeg => 'jpg',
    TabType.rgba => 'jpg',
  };
}

class _Tab extends StatefulWidget {
  const _Tab({required this.tabType});
  final TabType tabType;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> with AutomaticKeepAliveClientMixin {
  String? _path;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = WidgetToImageProvider.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        spacing: 10,
        children: [
          _Button(
            onPressed: (path) async {
              switch (widget.tabType) {
                case TabType.png:
                  await controller.saveAsPng(
                    outputPath: path,
                    measureTime: true,
                  );
                  break;
                case TabType.jpeg:
                  await controller.saveAsJpeg(
                    outputPath: path,
                    measureTime: true,
                  );
                  break;
                case TabType.rgba:
                  await controller.saveAsRgbaFile(
                    outputPath: path,
                    measureTime: true,
                  );
                  break;
              }
              setState(() {
                _path = path;
              });
            },
            text: 'Save ${widget.tabType.name}',
            ext: widget.tabType.ext,
          ),
          if (_path != null) Text(_path!.split('/').last),
          if (_path != null)
            Text(
              'Size: ${File(_path!).lengthSync() ~/ 1024} KB',
              style: const TextStyle(fontSize: 12),
            ),
          if (_path != null) Image.file(File(_path!), fit: BoxFit.cover),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _Button extends StatelessWidget {
  const _Button({
    required this.onPressed,
    required this.text,
    required this.ext,
  });
  final Future<void> Function(String path) onPressed;
  final String text;
  final String ext;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final tempDir = await getTemporaryDirectory();
        final outputPath = '${tempDir.path}/test_$now.$ext';
        await onPressed(outputPath);
      },
      child: Text(text),
    );
  }
}
