import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/chronicle_theme.dart';

class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChronicleTheme.majorColor,
      appBar: AppBar(
        backgroundColor: ChronicleTheme.minorColor,
        foregroundColor: ChronicleTheme.majorColor,
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
