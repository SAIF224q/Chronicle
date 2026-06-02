import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/chronicle_theme.dart';

class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: const Text('Image'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 6,
          child: Image.file(file, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
