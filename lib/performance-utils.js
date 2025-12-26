/**
 * Performance Utilities - Simple client-side performance monitoring
 * Tracks Core Web Vitals and provides lazy loading helpers
 */

(function() {
  'use strict';
  
  // Core Web Vitals Monitoring
  const perfObserver = {
    lcp: null,
    fid: null,
    cls: 0,
    
    init: function() {
      if (!window.PerformanceObserver) return;
      
      // Largest Contentful Paint (LCP)
      try {
        const lcpObserver = new PerformanceObserver((list) => {
          const entries = list.getEntries();
          const lastEntry = entries[entries.length - 1];
          this.lcp = lastEntry.renderTime || lastEntry.loadTime;
        });
        lcpObserver.observe({ type: 'largest-contentful-paint', buffered: true });
      } catch (e) {
        // LCP not supported
      }
      
      // First Input Delay (FID)
      try {
        const fidObserver = new PerformanceObserver((list) => {
          const firstInput = list.getEntries()[0];
          this.fid = firstInput.processingStart - firstInput.startTime;
        });
        fidObserver.observe({ type: 'first-input', buffered: true });
      } catch (e) {
        // FID not supported
      }
      
      // Cumulative Layout Shift (CLS)
      try {
        const clsObserver = new PerformanceObserver((list) => {
          for (const entry of list.getEntries()) {
            if (!entry.hadRecentInput) {
              this.cls += entry.value;
            }
          }
        });
        clsObserver.observe({ type: 'layout-shift', buffered: true });
      } catch (e) {
        // CLS not supported
      }
    },
    
    getMetrics: function() {
      return {
        lcp: this.lcp ? Math.round(this.lcp) : null,
        fid: this.fid ? Math.round(this.fid) : null,
        cls: Math.round(this.cls * 1000) / 1000
      };
    },
    
    logMetrics: function() {
      // Only log in development
      if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
        console.log('Core Web Vitals:', this.getMetrics());
      }
    }
  };
  
  // Initialize monitoring
  perfObserver.init();
  
  // Log metrics when page is about to unload
  window.addEventListener('beforeunload', function() {
    perfObserver.logMetrics();
  });
  
  // Lazy Loading Helper (for future image optimization)
  const lazyLoader = {
    init: function() {
      // Use Intersection Observer for lazy loading
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
          rootMargin: '50px 0px', // Start loading 50px before entering viewport
          threshold: 0.01
        });
        
        // Observe all images with data-src attribute
        document.querySelectorAll('img[data-src]').forEach(img => {
          imageObserver.observe(img);
        });
      } else {
        // Fallback: load all images immediately
        document.querySelectorAll('img[data-src]').forEach(img => {
          img.src = img.dataset.src;
          img.removeAttribute('data-src');
        });
      }
    }
  };
  
  // Initialize lazy loading when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      lazyLoader.init();
    });
  } else {
    lazyLoader.init();
  }
  
  // Expose utilities globally
  window.perfUtils = {
    getMetrics: perfObserver.getMetrics.bind(perfObserver),
    logMetrics: perfObserver.logMetrics.bind(perfObserver),
    lazyLoad: lazyLoader.init.bind(lazyLoader)
  };
  
  // Simple caching helper for data fetches
  window.cacheHelper = {
    cache: new Map(),
    
    get: function(key, fetchFn, ttl = 5 * 60 * 1000) { // 5 minutes default
      const cached = this.cache.get(key);
      const now = Date.now();
      
      if (cached && (now - cached.timestamp) < ttl) {
        return Promise.resolve(cached.data);
      }
      
      return fetchFn().then(data => {
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
    }
  };
  
  // Network-aware loading (detect connection speed)
  if ('connection' in navigator) {
    const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
    const effectiveType = connection.effectiveType;
    
    // Add class to body for CSS conditionals
    if (effectiveType) {
      document.documentElement.classList.add('connection-' + effectiveType);
    }
    
    // Expose connection info
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
