/**
 * Accessibility Enhancements
 * Keyboard shortcuts, focus management, and screen reader improvements
 */

(function() {
  'use strict';
  
  // Keyboard Shortcuts Manager
  const KeyboardShortcuts = {
    shortcuts: {
      'l': { action: () => typeof switchTab === 'function' && switchTab('league'), description: 'View League tab' },
      'm': { action: () => typeof switchTab === 'function' && switchTab('matchups'), description: 'View Matchups tab' },
      's': { action: () => typeof switchTab === 'function' && switchTab('standings'), description: 'View Standings tab' },
      't': { action: () => typeof switchTab === 'function' && switchTab('trends'), description: 'View Trends tab' },
      '?': { action: () => KeyboardShortcuts.showHelp(), description: 'Show keyboard shortcuts' },
      'h': { action: () => KeyboardShortcuts.showHelp(), description: 'Show help' }
    },
    
    init: function() {
      document.addEventListener('keydown', (e) => {
        // Don't trigger shortcuts if user is typing in an input
        if (e.target.matches('input, textarea, select')) {
          return;
        }
        
        // Don't trigger if modifier keys are pressed (except shift for ?)
        if (e.ctrlKey || e.altKey || e.metaKey) {
          return;
        }
        
        const key = e.key.toLowerCase();
        const shortcut = this.shortcuts[key];
        
        if (shortcut) {
          e.preventDefault();
          shortcut.action();
          this.announceToScreenReader(`Activated shortcut: ${shortcut.description}`);
        }
      });
      
      // Add help button to page
      this.addHelpButton();
    },
    
    addHelpButton: function() {
      const button = document.createElement('button');
      button.className = 'keyboard-help-button';
      button.setAttribute('aria-label', 'Show keyboard shortcuts (Press ? or H)');
      button.innerHTML = '⌨️';
      button.style.cssText = `
        position: fixed;
        bottom: 20px;
        right: 20px;
        width: 48px;
        height: 48px;
        border-radius: 50%;
        background: rgba(41, 128, 185, 0.9);
        color: white;
        border: none;
        font-size: 20px;
        cursor: pointer;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
        z-index: 9997;
        transition: all 0.2s ease;
        display: none;
      `;
      
      button.addEventListener('click', () => this.showHelp());
      button.addEventListener('mouseenter', () => {
        button.style.transform = 'scale(1.1)';
      });
      button.addEventListener('mouseleave', () => {
        button.style.transform = 'scale(1)';
      });
      
      document.body.appendChild(button);
      
      // Show on desktop only
      if (window.innerWidth > 768) {
        button.style.display = 'flex';
        button.style.alignItems = 'center';
        button.style.justifyContent = 'center';
      }
    },
    
    showHelp: function() {
      const existingModal = document.querySelector('.keyboard-help-modal');
      if (existingModal) {
        existingModal.remove();
        return;
      }
      
      const modal = document.createElement('div');
      modal.className = 'keyboard-help-modal';
      modal.setAttribute('role', 'dialog');
      modal.setAttribute('aria-labelledby', 'keyboard-help-title');
      modal.setAttribute('aria-modal', 'true');
      
      const shortcuts = Object.entries(this.shortcuts)
        .map(([key, data]) => `
          <div class="shortcut-item">
            <kbd>${key.toUpperCase()}</kbd>
            <span>${data.description}</span>
          </div>
        `).join('');
      
      modal.innerHTML = `
        <div class="keyboard-help-backdrop" aria-hidden="true"></div>
        <div class="keyboard-help-content">
          <div class="keyboard-help-header">
            <h2 id="keyboard-help-title">⌨️ Keyboard Shortcuts</h2>
            <button class="close-button" aria-label="Close help dialog">×</button>
          </div>
          <div class="keyboard-help-body">
            ${shortcuts}
          </div>
          <div class="keyboard-help-footer">
            <p class="text-secondary">Press <kbd>ESC</kbd> to close</p>
          </div>
        </div>
      `;
      
      modal.style.cssText = `
        position: fixed;
        inset: 0;
        z-index: 10000;
        display: flex;
        align-items: center;
        justify-content: center;
      `;
      
      document.body.appendChild(modal);
      
      // Focus the close button
      setTimeout(() => {
        modal.querySelector('.close-button').focus();
      }, 100);
      
      // Close handlers
      let escHandler;
      const close = () => {
        modal.remove();
        if (escHandler) {
          document.removeEventListener('keydown', escHandler);
          escHandler = null;
        }
      };
      modal.querySelector('.close-button').addEventListener('click', close);
      modal.querySelector('.keyboard-help-backdrop').addEventListener('click', close);
      
      // ESC key to close
      escHandler = (e) => {
        if (e.key === 'Escape') {
          close();
        }
      };
      document.addEventListener('keydown', escHandler);
    },
    
    announceToScreenReader: function(message) {
      const announcement = document.getElementById('sr-announcements');
      if (announcement) {
        announcement.textContent = message;
        // Clear after announcement
        setTimeout(() => {
          announcement.textContent = '';
        }, 1000);
      }
    }
  };
  
  // Focus Management
  const FocusManager = {
    // Constants for focus styling
    FOCUS_OUTLINE_WIDTH: '3px',
    FOCUS_OUTLINE_COLOR: 'rgba(33, 209, 159, 0.8)',
    FOCUS_OUTLINE_OFFSET: '2px',
    
    init: function() {
      // Add visible focus indicators
      this.enhanceFocusIndicators();
      
      // Skip to main content link
      this.addSkipLink();
      
      // Focus trap for modals (if any)
      this.setupFocusTrap();
    },
    
    enhanceFocusIndicators: function() {
      const style = document.createElement('style');
      style.textContent = `
        *:focus {
          outline: ${this.FOCUS_OUTLINE_WIDTH} solid ${this.FOCUS_OUTLINE_COLOR};
          outline-offset: ${this.FOCUS_OUTLINE_OFFSET};
        }
        
        *:focus:not(:focus-visible) {
          outline: none;
        }
        
        *:focus-visible {
          outline: ${this.FOCUS_OUTLINE_WIDTH} solid ${this.FOCUS_OUTLINE_COLOR};
          outline-offset: ${this.FOCUS_OUTLINE_OFFSET};
        }
      `;
      document.head.appendChild(style);
    },
    
    addSkipLink: function() {
      const skipLink = document.createElement('a');
      skipLink.href = '#main-content';
      skipLink.textContent = 'Skip to main content';
      skipLink.className = 'skip-link';
      skipLink.style.cssText = `
        position: absolute;
        top: -40px;
        left: 0;
        background: var(--accent-green, #21d19f);
        color: white;
        padding: 8px 16px;
        text-decoration: none;
        z-index: 10001;
        font-weight: 600;
        border-radius: 0 0 4px 0;
      `;
      
      skipLink.addEventListener('focus', function() {
        this.style.top = '0';
      });
      
      skipLink.addEventListener('blur', function() {
        this.style.top = '-40px';
      });
      
      document.body.insertBefore(skipLink, document.body.firstChild);
      
      // Add ID to main content if not exists
      const appContainer = document.querySelector('.app-container');
      if (appContainer && !appContainer.id) {
        appContainer.id = 'main-content';
      }
    },
    
    setupFocusTrap: function() {
      // This will trap focus in modals when they appear
      document.addEventListener('keydown', (e) => {
        if (e.key !== 'Tab') return;
        
        const modal = document.querySelector('[role="dialog"][aria-modal="true"]');
        if (!modal) return;
        
        const focusableElements = modal.querySelectorAll(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        
        if (focusableElements.length === 0) return;
        
        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];
        
        if (e.shiftKey) {
          if (document.activeElement === firstElement) {
            e.preventDefault();
            lastElement.focus();
          }
        } else {
          if (document.activeElement === lastElement) {
            e.preventDefault();
            firstElement.focus();
          }
        }
      });
    }
  };
  
  // Screen Reader Announcements
  const ScreenReaderAnnouncements = {
    init: function() {
      // Create live region for dynamic announcements
      const liveRegion = document.createElement('div');
      liveRegion.id = 'sr-announcements';
      liveRegion.setAttribute('role', 'status');
      liveRegion.setAttribute('aria-live', 'polite');
      liveRegion.setAttribute('aria-atomic', 'true');
      liveRegion.style.cssText = `
        position: absolute;
        left: -10000px;
        width: 1px;
        height: 1px;
        overflow: hidden;
      `;
      document.body.appendChild(liveRegion);
    },
    
    announce: function(message) {
      const liveRegion = document.getElementById('sr-announcements');
      if (liveRegion) {
        liveRegion.textContent = message;
        setTimeout(() => {
          liveRegion.textContent = '';
        }, 1000);
      }
    }
  };
  
  // Reduced Motion Support
  const ReducedMotion = {
    styleElement: null,
    mediaQuery: null,

    init: function() {
      if (!('matchMedia' in window)) {
        return;
      }

      this.mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');

      const applyPreference = (event) => {
        // `event` may be a MediaQueryList or a change event with a `matches` property
        const matches = event && typeof event.matches === 'boolean'
          ? event.matches
          : this.mediaQuery && this.mediaQuery.matches;

        if (matches) {
          document.documentElement.classList.add('reduce-motion');

          if (!this.styleElement) {
            const style = document.createElement('style');
            style.textContent = `
              .reduce-motion *,
              .reduce-motion *::before,
              .reduce-motion *::after {
                animation-duration: 0.01ms !important;
                animation-iteration-count: 1 !important;
                transition-duration: 0.01ms !important;
                scroll-behavior: auto !important;
              }
            `;
            document.head.appendChild(style);
            this.styleElement = style;
          }
        } else {
          document.documentElement.classList.remove('reduce-motion');
          if (this.styleElement && this.styleElement.parentNode) {
            this.styleElement.parentNode.removeChild(this.styleElement);
          }
          this.styleElement = null;
        }
      };

      // Apply the current preference immediately
      applyPreference(this.mediaQuery);

      // Listen for future preference changes
      if (typeof this.mediaQuery.addEventListener === 'function') {
        this.mediaQuery.addEventListener('change', applyPreference);
      } else if (typeof this.mediaQuery.addListener === 'function') {
        // Fallback for older browsers
        this.mediaQuery.addListener(applyPreference);
      }
    }
  };
  
  // Initialize all accessibility features when DOM is ready
  function initAccessibility() {
    try {
      KeyboardShortcuts.init();
      FocusManager.init();
      ScreenReaderAnnouncements.init();
      ReducedMotion.init();
      
      // Expose to global scope for integration
      window.a11y = {
        announce: ScreenReaderAnnouncements.announce.bind(ScreenReaderAnnouncements),
        showHelp: KeyboardShortcuts.showHelp.bind(KeyboardShortcuts)
      };
    } catch (e) {
      console.error('Failed to initialize accessibility features:', e);
    }
  }
  
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initAccessibility);
  } else {
    initAccessibility();
  }
  
  // Add keyboard help modal styles
  const modalStyles = document.createElement('style');
  modalStyles.textContent = `
    .keyboard-help-backdrop {
      position: absolute;
      inset: 0;
      background: rgba(0, 0, 0, 0.8);
      backdrop-filter: blur(4px);
    }
    
    .keyboard-help-content {
      position: relative;
      background: var(--bg-card, #1a253a);
      border-radius: 12px;
      max-width: 500px;
      width: 90%;
      max-height: 80vh;
      overflow-y: auto;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
    }
    
    .keyboard-help-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 1.5rem;
      border-bottom: 1px solid var(--border-color, #2a3a52);
    }
    
    .keyboard-help-header h2 {
      margin: 0;
      font-size: 1.5rem;
    }
    
    .keyboard-help-header .close-button {
      background: none;
      border: none;
      color: var(--text-primary, white);
      font-size: 2rem;
      cursor: pointer;
      padding: 0;
      width: 32px;
      height: 32px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 4px;
      transition: background 0.2s;
    }
    
    .keyboard-help-header .close-button:hover {
      background: rgba(255, 255, 255, 0.1);
    }
    
    .keyboard-help-body {
      padding: 1.5rem;
      display: flex;
      flex-direction: column;
      gap: 0.75rem;
    }
    
    .shortcut-item {
      display: flex;
      align-items: center;
      gap: 1rem;
    }
    
    .shortcut-item kbd {
      background: var(--bg-primary, #0b162a);
      border: 2px solid var(--border-color, #2a3a52);
      border-radius: 4px;
      padding: 0.25rem 0.75rem;
      font-family: monospace;
      font-size: 0.875rem;
      font-weight: 600;
      min-width: 40px;
      text-align: center;
    }
    
    .keyboard-help-footer {
      padding: 1rem 1.5rem;
      border-top: 1px solid var(--border-color, #2a3a52);
      text-align: center;
    }
    
    .keyboard-help-footer kbd {
      background: var(--bg-primary, #0b162a);
      border: 2px solid var(--border-color, #2a3a52);
      border-radius: 4px;
      padding: 0.25rem 0.5rem;
      font-family: monospace;
      font-size: 0.875rem;
    }
  `;
  document.head.appendChild(modalStyles);
  
})();
