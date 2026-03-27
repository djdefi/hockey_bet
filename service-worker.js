// Service Worker for Hockey Bet - Mobile Performance Optimization
const CACHE_NAME = 'hockey-bet-v3';
const DATA_CACHE_NAME = 'hockey-bet-data-v3';

// Assets to cache on install (using relative paths for GitHub Pages compatibility)
const STATIC_ASSETS = [
  './',
  './index.html',
  './styles.css',
  './favicon.ico',
  './site.webmanifest',
  './performance-utils.js',
  './accessibility.js',
  './social-features.js',
  './mobile-gestures.js',
  './pwa-install.js',
  './vendor/chart.umd.js'
];

// Offline fallback page served when navigation fails without a cached response
const OFFLINE_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Hockey Bet - Offline</title>
  <style>
    body { font-family: -apple-system, sans-serif; background: #0b162a; color: #fff; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; text-align: center; }
    .offline { max-width: 400px; padding: 2rem; }
    h1 { font-size: 1.5rem; margin-bottom: 1rem; }
    p { color: #8da1b9; line-height: 1.6; }
    button { background: #21d19f; color: #0b162a; border: none; padding: 0.75rem 1.5rem; border-radius: 8px; font-weight: 600; cursor: pointer; margin-top: 1rem; font-size: 1rem; }
  </style>
</head>
<body>
  <div class="offline">
    <h1>You're Offline</h1>
    <p>It looks like you've lost your internet connection. The standings will be back when you reconnect.</p>
    <button onclick="window.location.reload()">Try Again</button>
  </div>
</body>
</html>`;

// Install event - cache static assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((name) => name !== CACHE_NAME && name !== DATA_CACHE_NAME)
            .map((name) => caches.delete(name))
        );
      })
      .then(() => self.clients.claim())
  );
});

// Fetch event - stale-while-revalidate for data, cache-first for assets
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Handle JSON data files with stale-while-revalidate
  if (url.pathname.endsWith('.json')) {
    event.respondWith(
      caches.open(DATA_CACHE_NAME).then((cache) => {
        return cache.match(request).then((cachedResponse) => {
          const fetchPromise = fetch(request).then((networkResponse) => {
            // Update cache with fresh data
            cache.put(request, networkResponse.clone());
            return networkResponse;
          }).catch(() => cachedResponse); // Fallback to cache if network fails

          // Return cached data immediately, update in background
          return cachedResponse || fetchPromise;
        });
      })
    );
    return;
  }

  // Handle navigation requests with offline fallback
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, responseToCache));
          return response;
        })
        .catch(() => {
          return caches.match(request).then((cached) => {
            return cached || new Response(OFFLINE_HTML, {
              headers: { 'Content-Type': 'text/html' }
            });
          });
        })
    );
    return;
  }

  // Handle static assets with cache-first
  event.respondWith(
    caches.match(request).then((response) => {
      if (response) {
        return response;
      }

      return fetch(request).then((response) => {
        // Cache successful responses
        if (response.status === 200) {
          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(request, responseToCache);
          });
        }
        return response;
      });
    })
  );
});
