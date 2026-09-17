// lib/features/family_chat/data/family_chat_repository.dart

import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/family_chat_model.dart';

class FamilyChatRepository {
  final ApiClient _api = apiClient;

  Future<List<FamilyGroupModel>> getMyGroups() async {
    try {
      final response = await _api.get('/family-groups');
      return (response.data['data']['groups'] as List)
          .map((g) => FamilyGroupModel.fromJson(g as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<FamilyGroupModel> createGroup(String nom, {List<int> memberIds = const []}) async {
    try {
      final response = await _api.post('/family-groups', data: {
        'nom': nom,
        'member_ids': memberIds,
      });
      return FamilyGroupModel.fromJson(response.data['data']['group'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> addMember(int groupId, int userId) async {
    try {
      await _api.post('/family-groups/$groupId/members', data: {'user_id': userId});
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<FamilyMessageModel>> getMessages(int groupId, {int limit = 50, int offset = 0}) async {
    try {
      final response = await _api.get('/family-groups/$groupId/messages', queryParameters: {
        'limit': limit,
        'offset': offset,
      });
      return (response.data['data']['messages'] as List)
          .map((m) => FamilyMessageModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<FamilyMessageModel> sendMessage(
    int groupId, {
    String? contenu,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (contenu != null) 'contenu': contenu,
        if (imageBytes != null && imageFilename != null)
          'image': MultipartFile.fromBytes(imageBytes, filename: imageFilename),
      });
      final response = await _api.post('/family-groups/$groupId/messages', data: formData);
      return FamilyMessageModel.fromJson(response.data['data']['message'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<ChatUserModel>> searchUsers(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final response = await _api.get('/users/search', queryParameters: {'q': query.trim()});
      return (response.data['data']['users'] as List)
          .map((u) => ChatUserModel.fromJson(u as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
