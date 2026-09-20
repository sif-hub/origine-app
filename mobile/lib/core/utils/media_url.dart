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

const _cloudinaryVideoMarker = '/video/upload/';

bool _isCloudinaryVideo(String url) =>
    url.contains('res.cloudinary.com') && url.contains(_cloudinaryVideoMarker);

({String head, String base, String ext}) _splitCloudinaryVideo(String url) {
  final i = url.indexOf(_cloudinaryVideoMarker) + _cloudinaryVideoMarker.length;
  final tail = url.substring(i);
  final dot = tail.lastIndexOf('.');
  return (
    head: url.substring(0, i),
    base: dot == -1 ? tail : tail.substring(0, dot),
    ext: dot == -1 ? '' : tail.substring(dot + 1).toLowerCase(),
  );
}

/// URL de lecture d'une vidéo. Les formats non lisibles partout (.mov d'un
/// iPhone, .3gp...) sont convertis en MP4/H.264 à la volée par Cloudinary.
String videoPlaybackUrl(String url) {
  if (!_isCloudinaryVideo(url)) return url;
  final p = _splitCloudinaryVideo(url);
  if (p.ext == 'mp4') return url;
  return '${p.head}f_mp4,vc_h264,ac_aac/${p.base}.mp4';
}

/// Image d'aperçu (première image) d'une vidéo hébergée sur Cloudinary.
String? videoPosterUrl(String url) {
  if (!_isCloudinaryVideo(url)) return null;
  final p = _splitCloudinaryVideo(url);
  return '${p.head}so_0,w_480,h_320,c_fill/${p.base}.jpg';
}
