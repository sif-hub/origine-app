// lib/core/push/push_service_stub.dart
// Implémentation vide utilisée sur toute plateforme non-web.

class PushService {
  static Future<bool> initIfSupported() async => false;

  static String permissionState() => 'unsupported';
}
