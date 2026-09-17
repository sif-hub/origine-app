// web/push_sw.js
// Service worker dédié aux notifications Web Push d'ORIGINE.
// Séparé du service worker généré par Flutter (flutter_service_worker.js,
// qui gère uniquement le cache des assets) pour ne pas interférer avec lui.

self.addEventListener('push', (event) => {
  let payload = { title: 'ORIGINE', body: 'Nouveau message', group_id: null };
  try {
    if (event.data) payload = event.data.json();
  } catch (e) {
    // Corps non-JSON : on garde les valeurs par défaut.
  }

  const options = {
    body: payload.body || '',
    icon: 'icons/Icon-192.png',
    badge: 'icons/Icon-192.png',
    data: { group_id: payload.group_id || null },
  };

  event.waitUntil(self.registration.showNotification(payload.title || 'ORIGINE', options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = self.registration.scope;

  // Ramène l'app au premier plan (ou l'ouvre si fermée). Le clic amène sur
  // l'onglet Famille où l'utilisateur peut ouvrir la discussion concernée ;
  // la navigation directe vers le groupe précis n'est pas câblée ici.
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) return client.focus();
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(targetUrl);
      }
    })
  );
});
