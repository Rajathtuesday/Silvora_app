// import '../_archive/models/file_item.dart';
// import 'removal/api_client.dart';

// class FileService {
//   static Future<List<FileItem>> fetchFiles() async {
//     final res = await ApiClient.get("/files/");
//     return (res as List)
//         .map((j) => FileItem.fromJson(j))
//         .toList();
//   }

//   static Future<Map<String, dynamic>> resumeInfo(String fileId) async {
//     return await ApiClient.get("/file/$fileId/resume/");
//   }
// }
