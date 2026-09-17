// lib/core/push/push_service.dart
//
// Point d'entrée unique pour les notifications Web Push. L'implémentation
// réelle n'existe que sur le web (elle dépend de `dart:js_interop` et de
// `push_bridge.js`) ; sur les autres plateformes, `PushService` est un
// simple no-op pour que le reste du code n'ait pas à tester la plateforme.

export 'push_service_stub.dart'
    if (dart.library.js_interop) 'push_service_web.dart';
