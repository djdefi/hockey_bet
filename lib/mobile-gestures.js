/**
 * Mobile Gestures - Enhanced touch interactions for Hockey Bet
 * Implements swipe navigation and pull-to-refresh
 */

class MobileGestures {
  constructor() {
    this.startX = 0;
    this.startY = 0;
    this.currentX = 0;
    this.currentY = 0;
    this.isDragging = false;
    this.pullToRefreshThreshold = 80;
    this.swipeThreshold = 75; // Increased from 50 to reduce sensitivity
    this.tabs = ['league', 'matchups', 'standings', 'playoff-odds', 'trends'];
    this.currentTabIndex = 0;
    
    this.init();
  }
  
  init() {
    // Only enable on mobile devices
    if (window.innerWidth <= 768) {
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
    indicator.style.cssText = `
      position: fixed;
      top: -60px;
      left: 50%;
      transform: translateX(-50%);
      width: 40px;
      height: 40px;
      background: var(--color-accent-emphasis, #0969da);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      transition: all 0.3s ease;
      z-index: 9999;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
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
        // Update indicator position
        const progress = Math.min(pullDistance / this.pullToRefreshThreshold, 1);
        const translateY = Math.min(pullDistance * 0.5, 80);
        
        if (this.pullIndicator) {
          this.pullIndicator.style.transform = `translateX(-50%) translateY(${translateY}px) rotate(${progress * 180}deg)`;
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
      
      // Reset
      pulling = false;
      pullDistance = 0;
      pullStartTime = 0;
      pullVelocity = 0;
      document.body.style.transform = '';
      
      if (this.pullIndicator) {
        this.pullIndicator.style.transform = 'translateX(-50%) translateY(0)';
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
        // Determine swipe direction based on which movement is greater
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
      appContainer.style.transition = 'transform 0.3s ease';
      
      // Only navigate if this was a horizontal swipe
      if (isHorizontalSwipe && Math.abs(diff) > this.swipeThreshold) {
        if (diff > 0) {
          // Swipe right - go to previous tab
          this.navigatePrevTab();
        } else {
          // Swipe left - go to next tab
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
    const nextIndex = (currentIndex + 1) % this.tabs.length;
    const nextTab = this.tabs[nextIndex];
    
    // Use existing switchTab function if available
    if (typeof switchTab === 'function') {
      switchTab(nextTab);
      this.showTabChangeToast(nextTab, 'left');
    } else {
      console.warn('switchTab function not available');
    }
  }
  
  navigatePrevTab() {
    const currentIndex = this.getCurrentTabIndex();
    const prevIndex = currentIndex === 0 ? this.tabs.length - 1 : currentIndex - 1;
    const prevTab = this.tabs[prevIndex];
    
    // Use existing switchTab function if available
    if (typeof switchTab === 'function') {
      switchTab(prevTab);
      this.showTabChangeToast(prevTab, 'right');
    } else {
      console.warn('switchTab function not available');
    }
  }
  
  showTabChangeToast(tabName, direction) {
    const existingToast = document.querySelector('.swipe-toast');
    if (existingToast) {
      existingToast.remove();
    }
    
    const toast = document.createElement('div');
    toast.className = 'swipe-toast';
    const arrow = direction === 'left' ? '→' : '←';
    const tabLabel = tabName.charAt(0).toUpperCase() + tabName.slice(1);
    toast.textContent = `${arrow} ${tabLabel}`;
    toast.style.cssText = `
      position: fixed;
      bottom: 80px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(0, 0, 0, 0.8);
      color: white;
      padding: 8px 16px;
      border-radius: 20px;
      font-size: 14px;
      z-index: 9998;
      animation: swipeToastFade 2s ease forwards;
    `;
    
    document.body.appendChild(toast);
    
    setTimeout(() => {
      toast.remove();
    }, 2000);
  }
  
  triggerRefresh() {
    // Show refreshing state
    if (this.pullIndicator) {
      this.pullIndicator.innerHTML = `
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="animation: spin 1s linear infinite">
          <polyline points="23 4 23 10 17 10"></polyline>
          <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path>
        </svg>
      `;
      this.pullIndicator.style.transform = 'translateX(-50%) translateY(60px)';
      this.pullIndicator.style.opacity = '1';
    }
    
    // Reload the page
    setTimeout(() => {
      window.location.reload();
    }, 500);
  }
}

// Add necessary CSS animations
const style = document.createElement('style');
style.textContent = `
  @keyframes swipeToastFade {
    0% {
      opacity: 0;
      transform: translateX(-50%) translateY(20px);
    }
    10% {
      opacity: 1;
      transform: translateX(-50%) translateY(0);
    }
    90% {
      opacity: 1;
      transform: translateX(-50%) translateY(0);
    }
    100% {
      opacity: 0;
      transform: translateX(-50%) translateY(-20px);
    }
  }
  
  @keyframes spin {
    from {
      transform: rotate(0deg);
    }
    to {
      transform: rotate(360deg);
    }
  }
  
  .app-container {
    transition: transform 0.3s ease;
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
