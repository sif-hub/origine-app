// lib/core/utils/media_url.dart
//
// Résout l'URL d'un média stocké côté backend. En production les fichiers
// sont hébergés sur Cloudinary (URL absolue stockée telle quelle en base) ;
// en dev local ils restent servis par le backend depuis /uploads/<subfolder>.

import 'constants.dart';

String resolveMediaUrl(String subfolder, String value) {
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  final base = AppConstants.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
  return '$base/uploads/$subfolder/$value';
}
