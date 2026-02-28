// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';

// class PdfViewScreen extends StatelessWidget {
//   final File file;
//   final String filename;

//   const PdfViewScreen({
//     super.key,
//     required this.file,
//     required this.filename, required Uint8List bytes,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(filename)),
//       body: PDFView(
//         filePath: file.path,
//         enableSwipe: true,
//         swipeHorizontal: true,
//         autoSpacing: true,
//         pageFling: true,
//       ),
//     );
//   }
// }

// ******************************************************

// lib/screens/viewers/pdf_view_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewScreen extends StatelessWidget {
  final Uint8List bytes;
  final String filename;

  const PdfViewScreen({
    super.key,
    required this.bytes,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(filename, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SfPdfViewer.memory(bytes),
    );
  }
}
