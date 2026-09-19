// lib/features/stories/data/stories_repository.dart

import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/story_model.dart';

class DraftStoryMedia {
  final String type; // PHOTO | VIDEO | AUDIO
  final Uint8List bytes;
  final String filename;
  const DraftStoryMedia({required this.type, required this.bytes, required this.filename});
}

class StoriesRepository {
  final ApiClient _api = apiClient;

  Future<List<StoryModel>> getFeed({int limit = 20, int offset = 0, String? query}) async {
    try {
      final response = await _api.get('/stories', queryParameters: {
        'limit': limit,
        'offset': offset,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      });
      return (response.data['data']['stories'] as List)
          .map((s) => StoryModel.fromJson(s as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  /// Envoie le fichier directement à Cloudinary (signature fournie par le
  /// backend) : évite la limite de taille des requêtes du backend serverless.
  /// Retourne null si Cloudinary n'est pas configuré (dev local).
  Future<String?> _uploadDirect(DraftStoryMedia media, String folder) async {
    final sig = (await _api.get('/uploads/signature', queryParameters: {'folder': folder}))
        .data['data'] as Map<String, dynamic>;
    if (sig['enabled'] != true) return null;

    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(media.bytes, filename: media.filename),
      'api_key': sig['api_key'],
      'timestamp': sig['timestamp'],
      'folder': sig['folder'],
      'signature': sig['signature'],
    });
    final response = await Dio().post(
      'https://api.cloudinary.com/v1_1/${sig['cloud_name']}/auto/upload',
      data: form,
    );
    return response.data['secure_url'] as String;
  }

  Future<StoryModel> createStory({
    required String titre,
    required String description,
    String? dateHistoire,
    String? region,
    String? village,
    required String categorie,
    String? motsCles,
    String? source,
    bool autoriserTts = true,
    List<DraftStoryMedia> media = const [],
  }) async {
    try {
      final directUrls = <String>[];
      final directTypes = <String>[];
      final viaBackend = <DraftStoryMedia>[];
      for (final m in media) {
        final url = await _uploadDirect(m, 'story_media');
        if (url != null) {
          directUrls.add(url);
          directTypes.add(m.type);
        } else {
          viaBackend.add(m);
        }
      }

      final formData = FormData.fromMap({
        'titre': titre,
        'description': description,
        if (dateHistoire != null) 'date_histoire': dateHistoire,
        if (region != null) 'region': region,
        if (village != null) 'village': village,
        'categorie': categorie,
        if (motsCles != null) 'mots_cles': motsCles,
        if (source != null) 'source': source,
        'autoriser_tts': autoriserTts,
        'medias': viaBackend
            .map((m) => MultipartFile.fromBytes(m.bytes, filename: m.filename))
            .toList(),
        'media_types': viaBackend.map((m) => m.type).toList(),
        'media_urls': directUrls,
        'media_url_types': directTypes,
      });
      final response = await _api.post('/stories', data: formData);
      return StoryModel.fromJson(response.data['data']['story'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> deleteStory(int storyId) async {
    try {
      await _api.delete('/stories/$storyId');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<bool> toggleLike(int storyId) async {
    try {
      final response = await _api.post('/stories/$storyId/like');
      return response.data['data']['liked'] as bool;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<StoryCommentModel>> getComments(int storyId) async {
    try {
      final response = await _api.get('/stories/$storyId/comments');
      return (response.data['data']['comments'] as List)
          .map((c) => StoryCommentModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<StoryCommentModel> addComment(int storyId, String contenu) async {
    try {
      final response = await _api.post('/stories/$storyId/comments', data: {'contenu': contenu});
      return StoryCommentModel.fromJson(response.data['data']['comment'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> reportStory(int storyId, {String? raison}) async {
    try {
      await _api.post('/stories/$storyId/report', data: {'raison': raison});
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> submitCertificationRequest({
    required String typeProfessionnel,
    String? description,
    required Uint8List documentBytes,
    required String documentFilename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'type_professionnel': typeProfessionnel,
        if (description != null) 'description': description,
        'document': MultipartFile.fromBytes(documentBytes, filename: documentFilename),
      });
      await _api.post('/certification-requests', data: formData);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<Map<String, dynamic>?> getMyCertificationStatus() async {
    try {
      final response = await _api.get('/certification-requests/me');
      return response.data['data']['request'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  // ── ADMINISTRATION ──────────────────────────────────────────────────
  Future<List<CertificationRequestModel>> getCertificationRequests({String? statut}) async {
    try {
      final response = await _api.get('/admin/certification-requests', queryParameters: {
        if (statut != null) 'statut': statut,
      });
      return (response.data['data']['requests'] as List)
          .map((r) => CertificationRequestModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<CertificationRequestModel> reviewCertificationRequest(int requestId, String statut) async {
    try {
      final response = await _api.put('/admin/certification-requests/$requestId', data: {
        'statut': statut,
      });
      return CertificationRequestModel.fromJson(response.data['data']['request'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
