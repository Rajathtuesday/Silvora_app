// import 'dart:io';
// import 'dart:typed_data';
// import 'package:silvora_app/uploads/upload_manager.dart';


// import '../api/upload_api.dart';

// Future<void> simulateCrashAndResume() async {
//   final api = UploadApi();
//   final manager = UploadManager(api);

//   // Fake file data (20 bytes → 4 chunks)
//   final fileBytes = Uint8List.fromList(
//     List.generate(20, (i) => i),
//   );

//   final chunkSize = 5;
//   final chunks = <Uint8List>[];

//   for (int i = 0; i < fileBytes.length; i += chunkSize) {
//     chunks.add(
//       fileBytes.sublist(i, i + chunkSize),
//     );
//   }

//   // ---- START UPLOAD ----
//   final session = await manager.start(
//     filenameEnc: "aa",
//     filenameNonce: "bb",
//     filenameHash: "cc",
//     fileSize: fileBytes.length,
//     chunkSize: chunkSize,
//     securityMode: "zero_knowledge",
//   );

//   // Upload only FIRST TWO chunks
//   await manager.uploadOneChunk(
//     session: session,
//     index: 0,
//     file: File(''), // You need to provide the actual file here
//   );
//   await manager.uploadOneChunk(
//     session: session,
//     index: 1,
//     file: File(''), // You need to provide the actual file here
//   );

//   print("💥 APP CRASHES HERE 💥");

//   // ---- APP RESTARTS ----
//   final resumed = await manager.resume(session.fileId);

//   print("Resumed chunks: ${resumed.uploadedChunks}");

//   // Continue upload
//   await manager.uploadAll(
//     session: resumed,
//     chunks: chunks, file: null,
//   );

//   print("✅ Upload finished successfully");
// }
