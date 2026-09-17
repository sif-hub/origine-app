// lib/features/genealogy/data/genealogy_repository.dart

import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/person_model.dart';

class GenealogyRepository {
  final ApiClient _api = apiClient;

  // ── FAMILLES ────────────────────────────────────────────────────────
  Future<List<FamilyModel>> getFamilies() async {
    try {
      final response = await _api.get('/families');
      return (response.data['data']['families'] as List)
          .map((f) => FamilyModel.fromJson(f as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<FamilyModel> createFamily(String nom, {String visibilite = 'PRIVE'}) async {
    try {
      final response = await _api.post('/families', data: {
        'nom': nom,
        'visibilite': visibilite,
      });
      return FamilyModel.fromJson(response.data['data']['family'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<FamilyModel> updateFamily(int familyId, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/families/$familyId', data: data);
      return FamilyModel.fromJson(response.data['data']['family'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<FamilyTreeModel> getTree(int familyId) async {
    try {
      final response = await _api.get('/families/$familyId/tree');
      return FamilyTreeModel.fromJson(response.data['data']['tree'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<PersonDocumentModel>> getFamilyDocuments(int familyId) async {
    try {
      final response = await _api.get('/families/$familyId/documents');
      return (response.data['data']['documents'] as List)
          .map((d) => PersonDocumentModel.fromJson(d as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<PersonMemoryModel>> getFamilyMemories(int familyId) async {
    try {
      final response = await _api.get('/families/$familyId/memories');
      return (response.data['data']['memories'] as List)
          .map((m) => PersonMemoryModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  // ── PERSONNES ───────────────────────────────────────────────────────
  Future<PersonModel> createPerson(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/persons', data: data);
      return PersonModel.fromJson(response.data['data']['person'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<PersonModel> updatePerson(int personId, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/persons/$personId', data: data);
      return PersonModel.fromJson(response.data['data']['person'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> deletePerson(int personId) async {
    try {
      await _api.delete('/persons/$personId');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<PersonModel> addParent(int personId, Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/persons/$personId/parent', data: data);
      return PersonModel.fromJson(response.data['data']['person'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<PersonModel> addChild(int personId, Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/persons/$personId/child', data: data);
      return PersonModel.fromJson(response.data['data']['person'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<PersonModel> addSpouse(int personId, Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/persons/$personId/spouse', data: data);
      return PersonModel.fromJson(response.data['data']['person'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> linkPersons(int personId, int relatedPersonId, String type) async {
    try {
      await _api.post('/persons/$personId/link', data: {
        'related_person_id': relatedPersonId,
        'type': type,
      });
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<PersonModel> updatePersonPrivacy(int personId, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/persons/$personId/privacy', data: data);
      return PersonModel.fromJson(response.data['data']['person'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  // ── DOCUMENTS ───────────────────────────────────────────────────────
  Future<PersonDocumentModel> uploadPersonDocument({
    required int personId,
    required String typeDocument,
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'type_document': typeDocument,
        'fichier': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _api.post('/persons/$personId/documents', data: formData);
      return PersonDocumentModel.fromJson(response.data['data']['document'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<PersonDocumentModel>> getPersonDocuments(int personId) async {
    try {
      final response = await _api.get('/persons/$personId/documents');
      return (response.data['data']['documents'] as List)
          .map((d) => PersonDocumentModel.fromJson(d as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> deletePersonDocument(int personId, int docId) async {
    try {
      await _api.delete('/persons/$personId/documents/$docId');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  // ── SOUVENIRS ───────────────────────────────────────────────────────
  Future<PersonMemoryModel> uploadPersonMemory({
    required int personId,
    required String type,
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        'fichier': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _api.post('/persons/$personId/memories', data: formData);
      return PersonMemoryModel.fromJson(response.data['data']['memory'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<PersonMemoryModel>> getPersonMemories(int personId) async {
    try {
      final response = await _api.get('/persons/$personId/memories');
      return (response.data['data']['memories'] as List)
          .map((m) => PersonMemoryModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> deletePersonMemory(int personId, int memoryId) async {
    try {
      await _api.delete('/persons/$personId/memories/$memoryId');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
