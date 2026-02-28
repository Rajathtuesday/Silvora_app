// *************************************************************************  

// lib/screens/viewers/image_view_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageViewScreen extends StatelessWidget {
  final Uint8List bytes;
  final String filename;

  const ImageViewScreen({
    super.key,
    required this.bytes,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(filename, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.memory(bytes),
        ),
      ),
    );
  }
}
