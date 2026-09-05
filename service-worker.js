// Service Worker for NHL Fan League - installable shell + refresh-friendly caching
const CACHE_NAME = 'hockey-bet-static-v12';
const DATA_CACHE_NAME = 'hockey-bet-data-v12';
const APP_ASSET_MANIFEST_URL = './app-assets.json';
const LOCAL_ORIGIN = self.location.origin;

const OFFLINE_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#101214">
  <title>NHL Fan League - Offline</title>
  <style>
    :root { color-scheme: dark; --color-bg-primary: #101214; --color-bg-depth: #090b0c; --color-text-primary: #f4f5f6; --color-text-secondary: #b2b8bf; --color-focus: #ffbc52; --color-border-default: #363c42; }
    * { box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: var(--color-bg-primary); color: var(--color-text-primary); display: grid; place-items: center; min-height: 100vh; min-height: 100svh; margin: 0; padding: 20px; line-height: 1.5; }
    .offline { position: relative; width: 100%; max-width: 480px; padding: 40px 32px; border: 1px solid var(--color-border-default); background: var(--color-bg-depth); }
    .offline::before, .offline::after { content: ''; position: absolute; width: 22px; height: 22px; border-style: solid; border-color: var(--color-text-secondary); pointer-events: none; }
    .offline::before { top: 9px; left: 9px; border-width: 2px 0 0 2px; }
    .offline::after { right: 9px; bottom: 9px; border-width: 0 2px 2px 0; }
    h1 { font-size: 1.75rem; font-weight: 650; line-height: 1.25; letter-spacing: -0.025em; margin: 0 0 12px; }
    p { color: var(--color-text-secondary); margin: 0; font-size: 0.9375rem; }
    button { background: var(--color-focus); color: var(--color-bg-primary); border: 0; padding: 10px 16px; min-height: 44px; border-radius: 2px; font: inherit; font-weight: 600; cursor: pointer; margin-top: 24px; }
    button:hover { filter: brightness(1.08); }
    button:focus-visible { outline: 2px solid var(--color-focus); outline-offset: 4px; }
    footer { margin-top: 32px; color: var(--color-text-secondary); font-size: 0.75rem; }
  </style>
</head>
<body>
  <main class="offline" aria-labelledby="offline-title">
    <h1 id="offline-title">You're offline</h1>
    <p>This page isn't available offline. Reconnect and try again.</p>
    <button onclick="window.location.reload()">Try again</button>
    <footer>NHL Fan League</footer>
  </main>
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
