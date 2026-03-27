/**
 * Mobile Gestures - Enhanced touch interactions for Hockey Bet
 * Implements swipe navigation, pull-to-refresh, haptic feedback,
 * device-adaptive thresholds, and edge bounce effects.
 */

class MobileGestures {
  constructor() {
    this.startX = 0;
    this.startY = 0;
    this.currentX = 0;
    this.currentY = 0;
    this.isDragging = false;
    this.currentTabIndex = 0;

    // Device-adaptive thresholds
    const screenWidth = window.innerWidth;
    this.swipeThreshold = screenWidth < 375 ? 50 : screenWidth < 768 ? 65 : 75;
    this.pullToRefreshThreshold = 80;

    // Dynamic tab discovery with hardcoded fallback
    const domTabs = Array.from(document.querySelectorAll('.tab-section'))
      .map(el => el.id.replace('-tab', ''))
      .filter(id => id);
    this.tabs = domTabs.length > 0
      ? domTabs
      : ['league', 'matchups', 'standings', 'playoff-odds', 'trends'];

    // Mobile detection via media query (handles pointer: coarse for tablets)
    this.isMobile = window.matchMedia('(max-width: 768px), (pointer: coarse)').matches;

    this.init();
  }

  /** Trigger haptic feedback if supported */
  haptic(pattern = 10) {
    try {
      if (navigator.vibrate) {
        navigator.vibrate(pattern);
      }
    } catch (_) {
      // Vibration API can fail in restricted contexts
    }
  }

  init() {
    if (this.isMobile) {
      this.initPullToRefresh();
      this.initSwipeNavigation();
      this.createPullIndicator();
    }
  }

  createPullIndicator() {
    const indicator = document.createElement('div');
    indicator.id = 'pull-indicator';
    indicator.className = 'pull-indicator';
    indicator.innerHTML = `
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="6 9 12 15 18 9"></polyline>
      </svg>
    `;
    document.body.appendChild(indicator);
    this.pullIndicator = indicator;
  }

  initPullToRefresh() {
    let pulling = false;
    let pullDistance = 0;
    let pullStartTime = 0;
    let pullVelocity = 0;

    document.addEventListener('touchstart', (e) => {
      // Only trigger if at top of page
      if (window.scrollY === 0) {
        this.startY = e.touches[0].pageY;
        pulling = true;
        pullStartTime = Date.now();
      }
    }, { passive: true });

    document.addEventListener('touchmove', (e) => {
      if (!pulling) return;

      this.currentY = e.touches[0].pageY;
      pullDistance = this.currentY - this.startY;

      if (pullDistance > 0 && window.scrollY === 0) {
        const progress = Math.min(pullDistance / this.pullToRefreshThreshold, 1);
        const translateY = Math.min(pullDistance * 0.5, 80);

        if (this.pullIndicator) {
          this.pullIndicator.style.setProperty('--pull-progress', progress);
          this.pullIndicator.style.setProperty('--pull-translate', `${translateY}px`);
          this.pullIndicator.style.setProperty('--pull-rotate', `${progress * 180}deg`);
          this.pullIndicator.style.opacity = progress;
        }

        // Add some resistance
        if (pullDistance > this.pullToRefreshThreshold) {
          document.body.style.transform = `translateY(${translateY}px)`;
        }
      }
    }, { passive: true });

    document.addEventListener('touchend', () => {
      // Add velocity check - prevent accidental refreshes during fast scrolling
      const pullDuration = Date.now() - pullStartTime;
      pullVelocity = pullDistance / pullDuration; // pixels per ms

      // Only trigger if pulled far enough AND slowly enough (not a fast swipe)
      if (pulling && pullDistance > this.pullToRefreshThreshold && pullVelocity < 2) {
        this.triggerRefresh();
      }

      // Reset with spring easing via CSS transition
      pulling = false;
      pullDistance = 0;
      pullStartTime = 0;
      pullVelocity = 0;
      document.body.style.transform = '';

      if (this.pullIndicator) {
        this.pullIndicator.style.setProperty('--pull-translate', '0px');
        this.pullIndicator.style.setProperty('--pull-rotate', '0deg');
        this.pullIndicator.style.opacity = '0';
      }
    }, { passive: true });
  }

  initSwipeNavigation() {
    const appContainer = document.querySelector('.app-container');
    if (!appContainer) return;

    let startX = 0;
    let startY = 0;
    let isSwiping = false;
    let isHorizontalSwipe = false;

    appContainer.addEventListener('touchstart', (e) => {
      // Don't interfere with interactive controls (buttons, links, form inputs)
      const target = e.target;
      if (target.closest('button, a, input, textarea, select, [role="button"]')) {
        return;
      }

      startX = e.touches[0].pageX;
      startY = e.touches[0].pageY;
      isSwiping = true;
      isHorizontalSwipe = false;
    }, { passive: true });

    appContainer.addEventListener('touchmove', (e) => {
      if (!isSwiping) return;

      const currentX = e.touches[0].pageX;
      const currentY = e.touches[0].pageY;
      const diffX = currentX - startX;
      const diffY = currentY - startY;

      // Determine if this is a horizontal or vertical swipe
      if (!isHorizontalSwipe && Math.abs(diffX) > 10 && Math.abs(diffY) > 10) {
        isHorizontalSwipe = Math.abs(diffX) > Math.abs(diffY);
      }

      // Only show visual feedback for horizontal swipes
      if (isHorizontalSwipe && Math.abs(diffX) > 10) {
        appContainer.style.transform = `translateX(${diffX * 0.3}px)`;
        appContainer.style.transition = 'none';
      }
    }, { passive: true });

    appContainer.addEventListener('touchend', (e) => {
      if (!isSwiping) return;

      const endX = e.changedTouches[0].pageX;
      const diff = endX - startX;

      // Reset visual feedback
      appContainer.style.transform = '';
      appContainer.style.transition = 'transform 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94)';

      // Only navigate if this was a horizontal swipe
      if (isHorizontalSwipe && Math.abs(diff) > this.swipeThreshold) {
        if (diff > 0) {
          this.navigatePrevTab();
        } else {
          this.navigateNextTab();
        }
      }

      isSwiping = false;
      isHorizontalSwipe = false;
    }, { passive: true });
  }

  getCurrentTabIndex() {
    const activeTab = document.querySelector('.tab-section.active');
    if (activeTab) {
      const tabId = activeTab.id.replace('-tab', '');
      return this.tabs.indexOf(tabId);
    }
    return 0;
  }

  navigateNextTab() {
    const currentIndex = this.getCurrentTabIndex();
    if (currentIndex >= this.tabs.length - 1) {
      this.showBounceEffect('right');
      return;
    }
    const nextTab = this.tabs[currentIndex + 1];

    if (typeof switchTab === 'function') {
      this.haptic(10);
      switchTab(nextTab);
      this.showTabChangeToast(nextTab, 'left');
    } else {
      console.warn('switchTab function not available');
    }
  }

  navigatePrevTab() {
    const currentIndex = this.getCurrentTabIndex();
    if (currentIndex <= 0) {
      this.showBounceEffect('left');
      return;
    }
    const prevTab = this.tabs[currentIndex - 1];

    if (typeof switchTab === 'function') {
      this.haptic(10);
      switchTab(prevTab);
      this.showTabChangeToast(prevTab, 'right');
    } else {
      console.warn('switchTab function not available');
    }
  }

  /** Rubber-band bounce when swiping past the first/last tab */
  showBounceEffect(direction) {
    const appContainer = document.querySelector('.app-container');
    if (!appContainer) return;

    const offset = direction === 'left' ? '-20px' : '20px';
    appContainer.style.transition = 'none';
    appContainer.style.transform = `translateX(${offset})`;

    requestAnimationFrame(() => {
      appContainer.style.transition = 'transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)';
      appContainer.style.transform = '';

      const onEnd = () => {
        appContainer.style.transition = '';
        appContainer.removeEventListener('transitionend', onEnd);
      };
      appContainer.addEventListener('transitionend', onEnd, { once: true });
    });
  }

  showTabChangeToast(tabName, direction) {
    const existingToast = document.querySelector('.swipe-toast');
    if (existingToast) {
      existingToast.remove();
    }

    const toast = document.createElement('div');
    toast.className = 'swipe-toast';

    // Direction icon via Iconify (inline SVG for zero dependencies)
    const iconPath = direction === 'left'
      ? 'M15.835 11.63L9.205 5.2C8.79 4.799 8 5.042 8 5.57v12.86c0 .528.79.771 1.205.37l6.63-6.43a.498.498 0 0 0 0-.74z'
      : 'M8.165 11.63l6.63-6.43C15.21 4.799 16 5.042 16 5.57v12.86c0 .528-.79.771-1.205.37l-6.63-6.43a.498.498 0 0 1 0-.74z';

    const tabLabel = tabName.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
    toast.innerHTML = `
      <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" style="flex-shrink:0">
        <path d="${iconPath}"/>
      </svg>
      <span>${tabLabel}</span>
    `;

    document.body.appendChild(toast);

    setTimeout(() => {
      toast.remove();
    }, 2000);
  }

  triggerRefresh() {
    this.haptic(15);

    // Show refreshing state
    if (this.pullIndicator) {
      this.pullIndicator.innerHTML = `
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="pull-indicator-spin">
          <polyline points="23 4 23 10 17 10"></polyline>
          <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path>
        </svg>
      `;
      this.pullIndicator.style.setProperty('--pull-translate', '60px');
      this.pullIndicator.style.opacity = '1';
    }

    // Dispatch a custom event so the app can handle soft refresh
    const refreshEvent = new CustomEvent('pulltorefresh', { cancelable: true });
    const handled = !document.dispatchEvent(refreshEvent);

    // Fall back to full reload if nothing called preventDefault()
    if (!handled) {
      setTimeout(() => {
        window.location.reload();
      }, 500);
    }
  }
}

// Injected styles — CSS classes + custom properties for dynamic values
const style = document.createElement('style');
style.textContent = `
  .pull-indicator {
    position: fixed;
    top: -60px;
    left: 50%;
    width: 40px;
    height: 40px;
    background: var(--color-accent-emphasis, #0969da);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    z-index: 9999;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
    opacity: 0;
    /* Spring easing for return animation */
    transition: opacity 0.3s ease,
                transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
    transform: translateX(-50%)
               translateY(var(--pull-translate, 0px))
               rotate(var(--pull-rotate, 0deg));
  }

  .pull-indicator-spin {
    animation: spin 1s linear infinite;
  }

  .swipe-toast {
    position: fixed;
    bottom: 80px;
    left: 50%;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    background: var(--color-canvas-inset, rgba(0, 0, 0, 0.85));
    color: var(--color-fg-on-emphasis, #fff);
    padding: 8px 16px;
    border-radius: 20px;
    font-size: 14px;
    font-weight: 500;
    z-index: 9998;
    pointer-events: none;
    animation: swipeToastFade 2s ease forwards;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.25);
  }

  @keyframes swipeToastFade {
    0% {
      opacity: 0;
      transform: translateX(-50%) translateY(20px) scale(0.92);
    }
    10% {
      opacity: 1;
      transform: translateX(-50%) translateY(0) scale(1);
    }
    90% {
      opacity: 1;
      transform: translateX(-50%) translateY(0) scale(1);
    }
    100% {
      opacity: 0;
      transform: translateX(-50%) translateY(-20px) scale(0.92);
    }
  }

  @keyframes spin {
    from { transform: rotate(0deg); }
    to   { transform: rotate(360deg); }
  }

  .app-container {
    transition: transform 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
  }
`;
document.head.appendChild(style);

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    try {
      window.mobileGestures = new MobileGestures();
    } catch (e) {
      console.error('Failed to initialize mobile gestures:', e);
    }
  });
} else {
  try {
    window.mobileGestures = new MobileGestures();
  } catch (e) {
    console.error('Failed to initialize mobile gestures:', e);
  }
}
