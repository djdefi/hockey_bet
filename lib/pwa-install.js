/**
 * PWA Install Promotion - Smart banner for "Add to Home Screen"
 * 
 * Implements intelligent install prompts that appear at optimal moments:
 * - After 2+ visits (not annoying on first visit)
 * - After 30+ seconds of engagement (proves user interest)
 * - Only if user hasn't dismissed it before
 * 
 * @module PWAInstall
 */

/**
 * PWA Install Manager
 * Handles the beforeinstallprompt event and shows smart install banner
 */
class PWAInstall {
  constructor() {
    /** @type {Event|null} The deferred install prompt event */
    this.deferredPrompt = null;
    
    /** @type {number} Number of visits to the site */
    this.visitCount = 0;
    
    /** @type {number} Session start time in milliseconds */
    this.sessionStart = Date.now();
    
    /** @type {boolean} Whether user has dismissed the banner */
    this.dismissed = false;
    
    this.init();
  }
  
  /**
   * Initialize PWA install promotion
   * Sets up event listeners and checks if banner should be shown
   */
  init() {
    try {
      // Track visits
      this.trackVisit();
      
      // Listen for install prompt
      window.addEventListener('beforeinstallprompt', (e) => {
        e.preventDefault();
        this.deferredPrompt = e;
        this.considerShowingBanner();
      });
      
      // Track successful installation
      window.addEventListener('appinstalled', () => {
        console.log('PWA installed successfully');
        this.trackInstallation();
      });
      
      // Check engagement after 30 seconds
      setTimeout(() => {
        this.considerShowingBanner();
      }, 30000);
    } catch (error) {
      console.error('PWA Install initialization error:', error);
    }
  }
  
  /**
   * Track site visits in localStorage
   * Increments visit counter for smart banner triggering
   */
  trackVisit() {
    try {
      this.visitCount = parseInt(localStorage.getItem('hockeybet_visits') || '0') + 1;
      localStorage.setItem('hockeybet_visits', this.visitCount.toString());
      
      this.dismissed = localStorage.getItem('hockeybet_install_dismissed') === 'true';
    } catch (error) {
      console.error('Visit tracking error:', error);
    }
  }
  
  /**
   * Determine if install banner should be shown
   * Checks visit count, engagement time, and dismissal status
   * @returns {boolean} Whether banner should be displayed
   */
  considerShowingBanner() {
    const engagementTime = Date.now() - this.sessionStart;
    const hasEngaged = engagementTime > 30000; // 30 seconds
    const hasVisitedBefore = this.visitCount >= 2;
    const canPrompt = this.deferredPrompt !== null;
    
    if (hasEngaged && hasVisitedBefore && !this.dismissed && canPrompt) {
      this.showInstallBanner();
      return true;
    }
    
    // iOS fallback - show informational message
    if (hasEngaged && hasVisitedBefore && !this.dismissed && this.isIOS()) {
      this.showIOSInstructions();
      return true;
    }
    
    return false;
  }
  
  /**
   * Check if user is on iOS device
   * @returns {boolean} True if iOS Safari
   */
  isIOS() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
  }
  
  /**
   * Show the install promotion banner
   * Creates and displays a dismissable banner with install button
   */
  showInstallBanner() {
    const banner = document.createElement('div');
    banner.className = 'pwa-install-banner';
    banner.innerHTML = `
      <div class="pwa-banner-content">
        <div class="pwa-banner-icon">🏒</div>
        <div class="pwa-banner-text">
          <div class="pwa-banner-title">Add Hockey Bet to Home Screen</div>
          <div class="pwa-banner-subtitle">Get instant access and stay updated with live NHL standings</div>
        </div>
        <div class="pwa-banner-actions">
          <button class="pwa-install-button">Add to Home Screen</button>
          <button class="pwa-dismiss-button">Maybe Later</button>
        </div>
      </div>
    `;
    
    banner.style.cssText = `
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      background: var(--bg-card, #1a253a);
      border-top: 1px solid var(--border-color, #2a3a52);
      padding: 1rem;
      z-index: 9999;
      animation: slideUp 0.3s ease-out;
    `;
    
    // Add styles
    this.injectStyles();
    
    // Add event listeners
    banner.querySelector('.pwa-install-button').addEventListener('click', () => {
      this.promptInstall();
      banner.remove();
    });
    
    banner.querySelector('.pwa-dismiss-button').addEventListener('click', () => {
      this.dismissBanner();
      banner.remove();
    });
    
    document.body.appendChild(banner);
  }
  
  /**
   * Show iOS-specific installation instructions
   * Displays banner with instructions for Safari "Add to Home Screen"
   */
  showIOSInstructions() {
    const banner = document.createElement('div');
    banner.className = 'pwa-install-banner';
    banner.innerHTML = `
      <div class="pwa-banner-content">
        <div class="pwa-banner-icon">🏒</div>
        <div class="pwa-banner-text">
          <div class="pwa-banner-title">Add Hockey Bet to Home Screen</div>
          <div class="pwa-banner-subtitle">Tap <strong>Share</strong> → <strong>Add to Home Screen</strong></div>
        </div>
        <button class="pwa-dismiss-button">Got it</button>
      </div>
    `;
    
    banner.style.cssText = `
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      background: var(--bg-card, #1a253a);
      border-top: 1px solid var(--border-color, #2a3a52);
      padding: 1rem;
      z-index: 9999;
      animation: slideUp 0.3s ease-out;
    `;
    
    banner.querySelector('.pwa-dismiss-button').addEventListener('click', () => {
      this.dismissBanner();
      banner.remove();
    });
    
    document.body.appendChild(banner);
  }
  
  /**
   * Trigger the native install prompt
   * Shows browser's "Add to Home Screen" dialog
   */
  async promptInstall() {
    if (!this.deferredPrompt) {
      return;
    }
    
    try {
      this.deferredPrompt.prompt();
      const { outcome } = await this.deferredPrompt.userChoice;
      
      if (outcome === 'accepted') {
        console.log('User accepted install prompt');
        this.trackInstallation();
      } else {
        console.log('User dismissed install prompt');
      }
      
      this.deferredPrompt = null;
    } catch (error) {
      console.error('Install prompt error:', error);
    }
  }
  
  /**
   * Mark banner as dismissed by user
   * Stores dismissal in localStorage to prevent showing again
   */
  dismissBanner() {
    try {
      localStorage.setItem('hockeybet_install_dismissed', 'true');
      this.dismissed = true;
    } catch (error) {
      console.error('Dismiss tracking error:', error);
    }
  }
  
  /**
   * Track successful PWA installation
   * Records installation event for analytics
   */
  trackInstallation() {
    try {
      localStorage.setItem('hockeybet_installed', 'true');
      localStorage.setItem('hockeybet_install_date', new Date().toISOString());
      
      // Analytics tracking (if available)
      if (typeof gtag !== 'undefined') {
        gtag('event', 'pwa_install', {
          event_category: 'engagement',
          event_label: 'PWA Installed'
        });
      }
    } catch (error) {
      console.error('Installation tracking error:', error);
    }
  }
  
  /**
   * Inject CSS styles for install banner
   * Adds animation and responsive styles
   */
  injectStyles() {
    if (document.getElementById('pwa-install-styles')) {
      return;
    }
    
    const style = document.createElement('style');
    style.id = 'pwa-install-styles';
    style.textContent = `
      @keyframes slideUp {
        from {
          transform: translateY(100%);
          opacity: 0;
        }
        to {
          transform: translateY(0);
          opacity: 1;
        }
      }
      
      .pwa-banner-content {
        display: flex;
        align-items: center;
        gap: 1rem;
        flex-wrap: wrap;
      }
      
      .pwa-banner-icon {
        font-size: 2rem;
        flex-shrink: 0;
      }
      
      .pwa-banner-text {
        flex: 1;
        min-width: 200px;
      }
      
      .pwa-banner-title {
        font-weight: 600;
        font-size: 1rem;
        color: var(--text-primary, #fff);
        margin-bottom: 0.25rem;
      }
      
      .pwa-banner-subtitle {
        font-size: 0.875rem;
        color: var(--text-secondary, #8da1b9);
      }
      
      .pwa-banner-actions {
        display: flex;
        gap: 0.5rem;
        flex-wrap: wrap;
      }
      
      .pwa-install-button {
        background: var(--accent-green, #21d19f);
        color: var(--bg-primary, #0b162a);
        border: none;
        padding: 0.5rem 1rem;
        border-radius: 0.375rem;
        font-weight: 600;
        cursor: pointer;
        font-size: 0.875rem;
      }
      
      .pwa-install-button:hover {
        opacity: 0.9;
      }
      
      .pwa-dismiss-button {
        background: transparent;
        color: var(--text-secondary, #8da1b9);
        border: 1px solid var(--border-color, #2a3a52);
        padding: 0.5rem 1rem;
        border-radius: 0.375rem;
        cursor: pointer;
        font-size: 0.875rem;
      }
      
      .pwa-dismiss-button:hover {
        border-color: var(--text-secondary, #8da1b9);
      }
      
      @media (max-width: 768px) {
        .pwa-banner-content {
          flex-direction: column;
          align-items: flex-start;
          gap: 0.75rem;
        }
        
        .pwa-banner-actions {
          width: 100%;
        }
        
        .pwa-install-button,
        .pwa-dismiss-button {
          flex: 1;
        }
      }
    `;
    
    document.head.appendChild(style);
  }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    new PWAInstall();
  });
} else {
  new PWAInstall();
}
