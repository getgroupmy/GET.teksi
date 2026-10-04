// The service worker that receives Web Push.
//
// Scoped to push/ rather than the site root, because registering a different
// script at the root would replace Flutter's generated service worker and
// take offline loading with it. A push subscription belongs to a
// registration, not to a scope, so claiming a narrow one costs nothing.

self.addEventListener('push', (event) => {
  // A push with no data is still a push. Chrome requires that every delivery
  // shows the person something, so there is a fallback rather than a return:
  // a silent delivery costs the subscription its permission.
  let payload = { title: 'GET.teksi', body: 'You have a new update.' };
  if (event.data) {
    try {
      payload = { ...payload, ...event.data.json() };
    } catch (_) {
      payload.body = event.data.text() || payload.body;
    }
  }

  event.waitUntil(
    self.registration.showNotification(payload.title, {
      body: payload.body,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: payload.tag,
      // Replace rather than stack: three updates about one ride are one
      // notification, not a column of them.
      renotify: Boolean(payload.tag),
      data: { path: payload.path || '/' },
    }),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const path = (event.notification.data && event.notification.data.path) || '/';
  const target = new URL(path, self.location.origin).href;

  // Focus an open tab if there is one. Opening a second copy of a live ride
  // in a new tab is its own small disaster.
  event.waitUntil(
    self.clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((windows) => {
        for (const client of windows) {
          if ('focus' in client) {
            client.navigate(target);
            return client.focus();
          }
        }
        return self.clients.openWindow(target);
      }),
  );
});
