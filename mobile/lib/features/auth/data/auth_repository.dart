// lib/features/auth/data/auth_repository.dart

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/constants.dart';
import '../../../shared/models/user_model.dart';

class AuthRepository {
  final ApiClient _api = apiClient;
  final _storage = const FlutterSecureStorage();

  Future<UserModel> login(String email, String motDePasse) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'mot_de_passe': motDePasse,
      });

      final data = response.data['data'] as Map<String, dynamic>;

      await _storage.write(
        key: AppConstants.kAccessToken,
        value: data['access_token'] as String,
      );
      await _storage.write(
        key: AppConstants.kRefreshToken,
        value: data['refresh_token'] as String,
      );

      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.write(key: AppConstants.kUserId, value: user.id.toString());

      return user;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<UserModel> register(
    Map<String, dynamic> data, {
    Uint8List? photoBytes,
    String? photoFilename,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...data,
        if (photoBytes != null && photoFilename != null)
          'photo': MultipartFile.fromBytes(photoBytes, filename: photoFilename),
      });
      final response = await _api.post('/auth/register', data: formData);
      return UserModel.fromJson(
        response.data['data']['user'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: AppConstants.kRefreshToken);
    try {
      await _api.post('/auth/logout', data: {'refresh_token': refreshToken});
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.kAccessToken);
    return token != null;
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _api.get('/auth/me');
      return UserModel.fromJson(
        response.data['data']['user'] as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}
