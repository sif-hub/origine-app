// lib/core/push/push_service_web.dart
//
// Pont vers window.originePush (défini dans web/push_bridge.js) via
// dart:js_interop, pour activer les notifications Web Push et enregistrer
// l'abonnement du navigateur auprès du backend.

import 'dart:convert';
import 'dart:js_interop';

import '../api/api_client.dart';

@JS('originePush.isSupported')
external JSBoolean _jsIsSupported();

@JS('originePush.getPermissionState')
external JSString _jsGetPermissionState();

@JS('originePush.subscribe')
external JSPromise<JSString?> _jsSubscribe(JSString vapidPublicKey);

class PushService {
  /// Demande la permission de notification si nécessaire, s'abonne au Web
  /// Push et enregistre l'abonnement côté backend. Retourne `true` si
  /// l'abonnement a réussi, `false` sinon (non supporté, refusé, erreur
  /// réseau) — dans tous les cas, échoue silencieusement : les notifications
  /// sont une amélioration, jamais un prérequis pour utiliser l'app.
  static Future<bool> initIfSupported() async {
    try {
      if (!_jsIsSupported().toDart) return false;

      final vapidResponse = await apiClient.get('/push/vapid-public-key');
      final publicKey = vapidResponse.data['data']['public_key'] as String?;
      if (publicKey == null || publicKey.isEmpty) return false;

      final resultJs = await _jsSubscribe(publicKey.toJS).toDart;
      final resultStr = resultJs?.toDart;
      if (resultStr == null) return false; // permission refusée

      final subscription = jsonDecode(resultStr) as Map<String, dynamic>;
      final keys = subscription['keys'] as Map<String, dynamic>;
      await apiClient.post('/push/subscribe', data: {
        'endpoint': subscription['endpoint'],
        'keys': {'p256dh': keys['p256dh'], 'auth': keys['auth']},
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static String permissionState() {
    try {
      return _jsGetPermissionState().toDart;
    } catch (_) {
      return 'unsupported';
    }
  }
}
