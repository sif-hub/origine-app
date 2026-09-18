// lib/features/admin/data/admin_repository.dart

import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/user_model.dart';

class AdminStats {
  final int utilisateurs;
  final int familles;
  final int histoires;
  final int groupesFamiliaux;
  final int messages;
  final int certificationsEnAttente;
  final int histoiresSignalees;

  const AdminStats({
    required this.utilisateurs,
    required this.familles,
    required this.histoires,
    required this.groupesFamiliaux,
    required this.messages,
    required this.certificationsEnAttente,
    required this.histoiresSignalees,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        utilisateurs: json['utilisateurs'] as int? ?? 0,
        familles: json['familles'] as int? ?? 0,
        histoires: json['histoires'] as int? ?? 0,
        groupesFamiliaux: json['groupes_familiaux'] as int? ?? 0,
        messages: json['messages'] as int? ?? 0,
        certificationsEnAttente: json['certifications_en_attente'] as int? ?? 0,
        histoiresSignalees: json['histoires_signalees'] as int? ?? 0,
      );
}

class ReportedStoryModel {
  final int id;
  final String titre;
  final String description;
  final Map<String, dynamic> author;
  final List<Map<String, dynamic>> reports;

  const ReportedStoryModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.author,
    required this.reports,
  });

  factory ReportedStoryModel.fromJson(Map<String, dynamic> json) {
    final story = json['story'] as Map<String, dynamic>;
    return ReportedStoryModel(
      id: story['id'] as int,
      titre: story['titre'] as String? ?? '',
      description: story['description'] as String? ?? '',
      author: (story['author'] as Map<String, dynamic>?) ?? {},
      reports: (json['reports'] as List).cast<Map<String, dynamic>>(),
    );
  }
}

class AdminRepository {
  final ApiClient _api = apiClient;

  Future<AdminStats> getStats() async {
    try {
      final response = await _api.get('/admin/stats');
      return AdminStats.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<UserModel>> listUsers({String? q}) async {
    try {
      final response = await _api.get('/admin/users', queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
      });
      return (response.data['data']['users'] as List)
          .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> setUserStatus(int userId, String statut) async {
    try {
      await _api.put('/admin/users/$userId/status', data: {'statut': statut});
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      await _api.delete('/admin/users/$userId');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<ReportedStoryModel>> getReportedStories() async {
    try {
      final response = await _api.get('/admin/reported-stories');
      return (response.data['data']['items'] as List)
          .map((i) => ReportedStoryModel.fromJson(i as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> dismissReports(int storyId) async {
    try {
      await _api.post('/admin/reported-stories/$storyId/dismiss');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> deleteReportedStory(int storyId) async {
    try {
      await _api.delete('/admin/reported-stories/$storyId');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
