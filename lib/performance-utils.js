/**
 * Performance Utilities - client-side performance monitoring
 * Tracks Core Web Vitals and provides lazy loading helpers
 */

(function() {
  'use strict';

  const devHostPattern = /^(localhost|127\.0\.0\.1)(:\d+)?$/;

  // Core Web Vitals Monitoring
  const perfObserver = {
    lcp: null,
    inp: null,
    cls: 0,
    fallbackInputDelay: null,
    supportsINP: false,

    init: function() {
      if (!window.PerformanceObserver) return;

      this.observeLCP();
      this.observeINP();
      this.observeCLS();
      this.observeLifecycle();
    },

    observeLCP: function() {
      try {
        const lcpObserver = new PerformanceObserver((list) => {
          const entries = list.getEntries();
          const lastEntry = entries[entries.length - 1];
          this.lcp = lastEntry.renderTime || lastEntry.loadTime;
        });
        lcpObserver.observe({ type: 'largest-contentful-paint', buffered: true });
      } catch (error) {
        // LCP not supported
      }
    },

    observeINP: function() {
      const supportedEntryTypes = window.PerformanceObserver.supportedEntryTypes || [];
      if (!supportedEntryTypes.includes('event')) {
        this.observeFirstInputFallback();
        return;
      }

      try {
        const inpObserver = new PerformanceObserver((list) => {
          list.getEntries().forEach((entry) => {
            if (!entry.interactionId || typeof entry.duration !== 'number') {
              return;
            }

            if (this.inp === null || entry.duration > this.inp) {
              this.inp = entry.duration;
            }
          });
        });

        inpObserver.observe({ type: 'event', buffered: true, durationThreshold: 40 });
        this.supportsINP = true;
      } catch (error) {
        this.observeFirstInputFallback();
      }
    },

    observeFirstInputFallback: function() {
      try {
        const fidObserver = new PerformanceObserver((list) => {
          const firstInput = list.getEntries()[0];
          this.fallbackInputDelay = firstInput.processingStart - firstInput.startTime;
        });
        fidObserver.observe({ type: 'first-input', buffered: true });
      } catch (error) {
        // Fallback metric not supported
      }
    },

    observeCLS: function() {
      try {
        const clsObserver = new PerformanceObserver((list) => {
          for (const entry of list.getEntries()) {
            if (!entry.hadRecentInput) {
              this.cls += entry.value;
            }
          }
        });
        clsObserver.observe({ type: 'layout-shift', buffered: true });
      } catch (error) {
        // CLS not supported
      }
    },

    observeLifecycle: function() {
      const logMetrics = () => this.logMetrics();

      document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'hidden') {
          logMetrics();
        }
      });

      window.addEventListener('pagehide', logMetrics);
    },

    getMetrics: function() {
      return {
        lcp: this.lcp ? Math.round(this.lcp) : null,
        inp: this.inp ? Math.round(this.inp) : null,
        cls: Math.round(this.cls * 1000) / 1000,
        fallbackInputDelay: this.fallbackInputDelay ? Math.round(this.fallbackInputDelay) : null,
        supportsINP: this.supportsINP
      };
    },

    logMetrics: function() {
      if (devHostPattern.test(window.location.host)) {
        console.debug('Core Web Vitals:', this.getMetrics());
      }
    }
  };

  perfObserver.init();

  // Lazy Loading Helper (for future image optimization)
  const lazyLoader = {
    init: function() {
      if ('IntersectionObserver' in window) {
        const imageObserver = new IntersectionObserver((entries, observer) => {
          entries.forEach(entry => {
            if (entry.isIntersecting) {
              const img = entry.target;
              if (img.dataset.src) {
                img.src = img.dataset.src;
                img.removeAttribute('data-src');
                observer.unobserve(img);
              }
            }
          });
        }, {
          rootMargin: '50px 0px',
          threshold: 0.01
        });

        document.querySelectorAll('img[data-src]').forEach(img => {
          imageObserver.observe(img);
        });
      } else {
        document.querySelectorAll('img[data-src]').forEach(img => {
          img.src = img.dataset.src;
          img.removeAttribute('data-src');
        });
      }
    }
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      lazyLoader.init();
    });
  } else {
    lazyLoader.init();
  }

  window.perfUtils = {
    getMetrics: perfObserver.getMetrics.bind(perfObserver),
    logMetrics: perfObserver.logMetrics.bind(perfObserver),
    lazyLoad: lazyLoader.init.bind(lazyLoader)
  };

  window.cacheHelper = {
    cache: new Map(),
    maxSize: 50,

    get: function(key, fetchFn, ttl) {
      const effectiveTTL = typeof ttl === 'number' ? ttl : 5 * 60 * 1000;
      const cached = this.cache.get(key);
      const now = Date.now();

      if (cached && (now - cached.timestamp) < effectiveTTL) {
        return Promise.resolve(cached.data);
      }

      return fetchFn().then(data => {
        if (this.cache.size >= this.maxSize) {
          const oldestKey = this.cache.keys().next().value;
          this.cache.delete(oldestKey);
        }

        this.cache.set(key, { data: data, timestamp: now });
        return data;
      });
    },

    clear: function(key) {
      if (key) {
        this.cache.delete(key);
      } else {
        this.cache.clear();
      }
    },

    cleanupExpired: function(ttl) {
      const effectiveTTL = typeof ttl === 'number' ? ttl : 5 * 60 * 1000;
      const now = Date.now();
      for (const [key, value] of this.cache.entries()) {
        if (now - value.timestamp >= effectiveTTL) {
          this.cache.delete(key);
        }
      }
    }
  };

  setInterval(() => {
    window.cacheHelper.cleanupExpired();
  }, 5 * 60 * 1000);

  if ('connection' in navigator) {
    const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
    const effectiveType = connection.effectiveType;

    if (effectiveType) {
      document.documentElement.classList.add('connection-' + effectiveType);
    }

    window.networkInfo = {
      type: effectiveType,
      downlink: connection.downlink,
      rtt: connection.rtt,
      saveData: connection.saveData,

      isSlow: function() {
        return effectiveType === 'slow-2g' || effectiveType === '2g';
      },

      isFast: function() {
        return effectiveType === '4g';
      }
    };
  }
})();
