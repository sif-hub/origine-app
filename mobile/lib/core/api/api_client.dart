// lib/core/api/api_client.dart
// Client HTTP centralisé :
// – injecte le JWT Bearer automatiquement sur chaque requête
// – rafraîchit l'access_token si 401 reçu (via refresh_token)
// – exporte une instance singleton `apiClient`

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../utils/constants.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    ));

    // Intercepteur : injection du token JWT
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));

    // Logger en mode debug uniquement
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: false,
      requestBody: true,
      responseBody: true,
    ));
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.kAccessToken);
    print(
        "🔐 ACCESS TOKEN: ${token != null ? "PRESENT (${token.length} caractères)" : "ABSENT"}");
    if (token != null) {
      print('🔐 JWT ENVOYÉ: $token');
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Tentative de rafraîchissement si 401 (token expiré)
    if (err.response?.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Re-tente la requête originale avec le nouveau token
        final newToken = await _storage.read(key: AppConstants.kAccessToken);
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      }
    }
    handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.read(key: AppConstants.kRefreshToken);
    if (refreshToken == null) return false;

    try {
      final response = await Dio().post(
        '${AppConstants.apiBaseUrl}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newAccessToken = response.data['data']['access_token'] as String?;
      if (newAccessToken == null) return false;
      await _storage.write(
          key: AppConstants.kAccessToken, value: newAccessToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Helpers pour les requêtes courantes
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  /// Extrait le message d'erreur depuis la réponse API
  static String extractError(DioException e) {
    return e.response?.data?['message'] as String? ??
        'Erreur de connexion. Vérifiez votre réseau.';
  }
}

// Instance globale singleton
final apiClient = ApiClient();
