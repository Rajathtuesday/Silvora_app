//lib/infrastructure/services/files_service.dart
import '../api/upload_api.dart';
import '../../state/secure_state.dart';

class FilesService {
  static UploadApi _api() =>
      UploadApi(accessToken: SecureState.accessToken!);

  static Future<List<dynamic>> listFiles() async {
    return _api().listFiles();
  }

  static Future<void> deleteFile(String fileId) async {
    await _api().deleteFile(fileId);
  }

  static Future<Map<String, dynamic>> fetchQuota() async {
    return _api().fetchQuota();
  }
}
