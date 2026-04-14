// Service Worker for Hockey Bet - installable shell + refresh-friendly caching
const CACHE_NAME = 'hockey-bet-static-v6';
const DATA_CACHE_NAME = 'hockey-bet-data-v6';
const APP_ASSET_MANIFEST_URL = './app-assets.json';
const LOCAL_ORIGIN = self.location.origin;

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

const OFFLINE_HTML_HEADERS = {
  'Content-Type': 'text/html; charset=UTF-8'
};

function isSameOriginGetRequest(request) {
  return request.method === 'GET' && new URL(request.url).origin === LOCAL_ORIGIN;
}

function isDataRequest(url) {
  return url.pathname.endsWith('.json');
}

function isStaticAssetRequest(request, url) {
  return ['script', 'style', 'image', 'font', 'manifest'].includes(request.destination) ||
    /\.(?:css|js|ico|svg|png|webmanifest)$/i.test(url.pathname);
}

async function loadPrecachePaths() {
  try {
    const response = await fetch(APP_ASSET_MANIFEST_URL, { cache: 'no-store' });
    if (!response.ok) {
      throw new Error(`Unable to load ${APP_ASSET_MANIFEST_URL}: ${response.status}`);
    }

    const manifest = await response.json();
    const paths = Array.isArray(manifest.precache_paths) ? manifest.precache_paths : [];
    return [...new Set(paths)];
  } catch (error) {
    console.warn('ServiceWorker precache manifest unavailable:', error);
    return ['./', './index.html', './site.webmanifest'];
  }
}

async function precacheStaticAssets(cache) {
  const paths = await loadPrecachePaths();

  await Promise.allSettled(
    paths.map(async (assetPath) => {
      const request = new Request(assetPath, { cache: 'reload' });
      const response = await fetch(request);
      if (!response.ok) {
        throw new Error(`Precache failed for ${assetPath}: ${response.status}`);
      }

      await cache.put(request, response.clone());
    })
  );
}

async function handleDataRequest(event) {
  const cache = await caches.open(DATA_CACHE_NAME);
  const cachedResponse = await cache.match(event.request);
  const networkFetch = fetch(event.request).then((networkResponse) => {
    if (networkResponse && networkResponse.ok) {
      cache.put(event.request, networkResponse.clone());
    }
    return networkResponse;
  });

  if (cachedResponse) {
    event.waitUntil(networkFetch.catch(() => undefined));
    return cachedResponse;
  }

  try {
    return await networkFetch;
  } catch (error) {
    return new Response(JSON.stringify({ error: 'offline' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

async function handleNavigationRequest(event) {
  const cache = await caches.open(CACHE_NAME);

  try {
    const networkResponse = await fetch(event.request);
    if (networkResponse && networkResponse.ok) {
      await cache.put(event.request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    const cachedResponse = await cache.match(event.request);
    return cachedResponse || new Response(OFFLINE_HTML, { headers: OFFLINE_HTML_HEADERS });
  }
}

async function handleStaticAssetRequest(event) {
  const cache = await caches.open(CACHE_NAME);
  const cachedResponse = await cache.match(event.request);
  const networkFetch = fetch(event.request).then((networkResponse) => {
    if (networkResponse && networkResponse.ok) {
      cache.put(event.request, networkResponse.clone());
    }
    return networkResponse;
  });

  if (cachedResponse) {
    event.waitUntil(networkFetch.catch(() => undefined));
    return cachedResponse;
  }

  try {
    return await networkFetch;
  } catch (error) {
    return cachedResponse || Response.error();
  }
}

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => precacheStaticAssets(cache))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME && name !== DATA_CACHE_NAME)
          .map((name) => caches.delete(name))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('fetch', (event) => {
  if (!isSameOriginGetRequest(event.request)) {
    return;
  }

  const url = new URL(event.request.url);

  if (isDataRequest(url)) {
    event.respondWith(handleDataRequest(event));
    return;
  }

  if (event.request.mode === 'navigate') {
    event.respondWith(handleNavigationRequest(event));
    return;
  }

  if (isStaticAssetRequest(event.request, url)) {
    event.respondWith(handleStaticAssetRequest(event));
  }
});
