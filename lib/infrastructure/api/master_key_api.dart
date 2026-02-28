// lib/api/master_key_api.dart

import 'package:dio/dio.dart';
import '../../state/secure_state.dart';

class MasterKeyApi {
  late final Dio _dio;

  MasterKeyApi({required String accessToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: SecureState.serverBaseUrl,
        headers: {
          "Authorization": "Bearer $accessToken",
        },
      ),
    );
  }

  /// POST /master-key/setup/
  Future<void> setupMasterKey({
    required String encMasterKeyHex,
    required String nonceHex,
    required String saltHex,
    required int memoryKb,
    required int iterations,
    required int parallelism,
  }) async {
    await _dio.post(
      '/api/auth/master-key/setup/',
      data: {
        "enc_master_key": encMasterKeyHex,
        "enc_master_key_nonce": nonceHex,
        "kdf_salt": saltHex,
        "kdf_memory_kb": memoryKb,
        "kdf_iterations": iterations,
        "kdf_parallelism": parallelism,
      },
    );
  }
}