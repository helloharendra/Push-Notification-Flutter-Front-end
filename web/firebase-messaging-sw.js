importScripts('https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js');

// Initialize Firebase
firebase.initializeApp({
  apiKey: 'AIzaSyCKV3U6NgPSuTCagYbOqqDK1NFkWoDMpjw',
  appId: '1:597094987517:web:f522e91c8720cabbd0f094',
  messagingSenderId: '597094987517',
  projectId: 'push-notification-1ecd2',
  authDomain: 'push-notification-1ecd2.firebaseapp.com',
  storageBucket: 'push-notification-1ecd2.appspot.com',
  measurementId: 'G-0D1ZQJGF7P'
});

const messaging = firebase.messaging();

// Customize background message handler
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message', payload);

  // Customize notification here
  const notificationTitle = payload.notification?.title || 'New Notification';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new message',
    icon: '/icons/Icon-192.png',
    data: {
      url: '/', // URL to open when notification is clicked
      ...payload.data // Pass all original data
    }
  };

  // Show notification
  return self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('Notification clicked:', event.notification);
  
  // Close the notification
  event.notification.close();
  
  // Get the URL from notification data
  const urlToOpen = new URL(event.notification.data.url || '/', self.location.origin).href;

  // Focus or open the app
  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    }).then((windowClients) => {
      // Check if app is already open
      for (const client of windowClients) {
        if (client.url === urlToOpen && 'focus' in client) {
          return client.focus();
        }
      }
      
      // Open new window if app isn't open
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});