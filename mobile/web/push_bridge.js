// web/push_bridge.js
// Pont entre l'app Flutter (via dart:js_interop) et les API navigateur
// (Notification, Service Worker, Push) nécessaires aux notifications
// Web Push. Chargé depuis index.html.

(function () {
  function urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    const rawData = atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    for (let i = 0; i < rawData.length; i++) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  }

  window.originePush = {
    isSupported: function () {
      return 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
    },

    getPermissionState: function () {
      return 'Notification' in window ? Notification.permission : 'unsupported';
    },

    // Retourne une Promise<string> : le JSON de la subscription, ou null si
    // la permission est refusée / non supportée.
    subscribe: async function (vapidPublicKey) {
      if (!window.originePush.isSupported()) return null;

      const permission = await Notification.requestPermission();
      if (permission !== 'granted') return null;

      const registration = await navigator.serviceWorker.register('push_sw.js');
      await navigator.serviceWorker.ready;

      let subscription = await registration.pushManager.getSubscription();
      if (!subscription) {
        subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: urlBase64ToUint8Array(vapidPublicKey),
        });
      }

      return JSON.stringify(subscription.toJSON());
    },

    unsubscribe: async function () {
      if (!('serviceWorker' in navigator)) return;
      const registration = await navigator.serviceWorker.getRegistration('push_sw.js');
      if (!registration) return;
      const subscription = await registration.pushManager.getSubscription();
      if (subscription) await subscription.unsubscribe();
    },
  };
})();
