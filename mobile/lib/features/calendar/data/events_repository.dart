// lib/features/calendar/data/events_repository.dart

import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/event_model.dart';

class EventsRepository {
  final ApiClient _api = apiClient;

  Future<List<FamilyEventModel>> getEvents({DateTime? start, DateTime? end}) async {
    try {
      final response = await _api.get('/events', queryParameters: {
        if (start != null) 'start': start.toIso8601String().split('T').first,
        if (end != null) 'end': end.toIso8601String().split('T').first,
      });
      return (response.data['data']['events'] as List)
          .map((e) => FamilyEventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<FamilyEventModel> createEvent(FamilyEventModel draft) async {
    try {
      final response = await _api.post('/events', data: draft.toJson());
      return FamilyEventModel.fromJson(response.data['data']['event'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<FamilyEventModel> updateEvent(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/events/$id', data: data);
      return FamilyEventModel.fromJson(response.data['data']['event'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> deleteEvent(int id) async {
    try {
      await _api.delete('/events/$id');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
