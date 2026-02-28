import 'dart:io';

Future<void> saveToDownloads(
  File tempFile,
  String filename,
) async {
  final downloadsDir =
      Directory('/storage/emulated/0/Download');

  if (!downloadsDir.existsSync()) {
    downloadsDir.createSync(recursive: true);
  }

  final outFile = File('${downloadsDir.path}/$filename');
  await tempFile.copy(outFile.path);
  print("📁 Saved to ${outFile.path}");
}
  