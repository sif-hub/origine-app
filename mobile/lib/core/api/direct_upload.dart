// lib/core/api/direct_upload.dart
//
// Envoi direct d'un fichier vers Cloudinary (signature fournie par le
// backend). Évite la limite de taille des requêtes du backend serverless
// (~4,5 Mo), qui bloquait vidéos et grosses photos.

import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_client.dart';

/// Retourne l'URL du fichier hébergé, ou null si Cloudinary n'est pas
/// configuré côté backend (dev local) : l'appelant utilise alors l'envoi
/// classique via le backend.
Future<String?> uploadDirect(Uint8List bytes, String filename, String folder) async {
  try {
    final sig = (await apiClient.get('/uploads/signature', queryParameters: {'folder': folder}))
        .data['data'] as Map<String, dynamic>;
    if (sig['enabled'] != true) return null;

    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
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
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
}
