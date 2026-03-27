/**
 * Social Reactions & Engagement
 * Emoji reactions, celebrations, and card interaction features
 */

(function() {
  'use strict';

  // Social Reactions Manager
  const SocialReactions = {
    // Available icon-based reactions (Solar icon names)
    reactionIcons: [
      { icon: 'solar:like-bold', label: 'Like' },
      { icon: 'solar:fire-bold', label: 'Fire' },
      { icon: 'solar:emoji-funny-circle-bold', label: 'Funny' },
      { icon: 'solar:flash-bold', label: 'Strong' },
      { icon: 'solar:cup-star-bold', label: 'Trophy' },
      { icon: 'solar:sad-circle-bold', label: 'Sad' },
      { icon: 'solar:eye-bold', label: 'Eyes' },
      { icon: 'solar:confetti-bold', label: 'Celebrate' }
    ],

    // In-memory storage with localStorage persistence
    reactions: {},

    init: function() {
      this.loadReactions();
      this.initReactionButtons();
      this.initCelebrations();
    },

    loadReactions: function() {
      try {
        const stored = localStorage.getItem('hockey_reactions');
        if (stored) {
          this.reactions = JSON.parse(stored);
        }
      } catch (e) {
        console.warn('Could not load reactions:', e);
      }
    },

    saveReactions: function() {
      // Save to localStorage with size limit check
      try {
        const data = JSON.stringify(this.reactions);
        // Check if data is too large (rough check for 5MB limit)
        if (data.length > 4 * 1024 * 1024) { // 4MB soft limit
          console.warn('Reactions data too large, pruning oldest entries');
          const keys = Object.keys(this.reactions);
          if (keys.length > 100) {
            keys.slice(0, Math.floor(keys.length / 2)).forEach(key => {
              delete this.reactions[key];
            });
          }
        }
        localStorage.setItem('hockey_reactions', JSON.stringify(this.reactions));
      } catch (e) {
        if (e.name === 'QuotaExceededError') {
          console.warn('localStorage quota exceeded, clearing old reactions');
          this.reactions = {};
          localStorage.removeItem('hockey_reactions');
        } else {
          console.warn('Could not save reactions:', e);
        }
      }
    },

    // Derive a stable card ID from content rather than DOM index
    deriveCardId: function(card) {
      const fanName = card.querySelector('.stat-fan-name');
      if (fanName && fanName.textContent.trim()) {
        return 'card-' + fanName.textContent.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-');
      }
      const teamName = card.querySelector('.team-name');
      if (teamName && teamName.textContent.trim()) {
        return 'card-' + teamName.textContent.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-');
      }
      // Fallback: use a hash of the card's text content for stability
      const text = card.textContent.trim().substring(0, 80);
      let hash = 0;
      for (let i = 0; i < text.length; i++) {
        hash = ((hash << 5) - hash) + text.charCodeAt(i);
        hash |= 0;
      }
      return 'card-' + Math.abs(hash).toString(36);
    },

    initReactionButtons: function() {
      // Add reaction buttons only to larger cards (not stat-card-square — too small at 125×125px)
      const cards = document.querySelectorAll('.matchup-card, .team-card');

      cards.forEach((card) => {
        if (card.querySelector('.reaction-bar')) return;

        const cardId = this.deriveCardId(card);
        card.dataset.cardId = cardId;

        const reactionBar = document.createElement('div');
        reactionBar.className = 'reaction-bar';
        reactionBar.innerHTML = `
          <button class="reaction-btn" aria-label="Add reaction" title="React">
            <iconify-icon icon="solar:emoji-funny-circle-bold" width="18" height="18"></iconify-icon>
          </button>
          <div class="reaction-counts"></div>
        `;

        const btn = reactionBar.querySelector('.reaction-btn');
        btn.addEventListener('click', (e) => {
          e.stopPropagation();
          this.showEmojiPicker(cardId, btn);
        });

        card.appendChild(reactionBar);
        this.updateReactionDisplay(cardId);
      });
    },

    showEmojiPicker: function(cardId, button) {
      // Remove existing picker
      const existing = document.querySelector('.emoji-picker');
      if (existing) existing.remove();

      const picker = document.createElement('div');
      picker.className = 'emoji-picker';

      // Position near button, with viewport boundary checks
      const rect = button.getBoundingClientRect();
      const viewportWidth = window.innerWidth;
      const viewportHeight = window.innerHeight;
      const pickerWidth = 300;
      const pickerHeight = 60;

      let top = rect.bottom + 5;
      let left = rect.left;

      if (top + pickerHeight > viewportHeight) {
        top = rect.top - pickerHeight - 5;
      }
      if (left + pickerWidth > viewportWidth) {
        left = viewportWidth - pickerWidth - 10;
      }
      if (left < 10) {
        left = 10;
      }

      picker.style.top = top + 'px';
      picker.style.left = left + 'px';

      // Add icon reaction buttons
      this.reactionIcons.forEach(reaction => {
        const emojiBtn = document.createElement('button');
        emojiBtn.innerHTML = `<iconify-icon icon="${reaction.icon}" width="24" height="24"></iconify-icon>`;
        emojiBtn.className = 'emoji-btn';
        emojiBtn.setAttribute('aria-label', reaction.label);

        emojiBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          this.addReaction(cardId, reaction.icon);
          picker.remove();
        });

        picker.appendChild(emojiBtn);
      });

      document.body.appendChild(picker);

      // Close picker when clicking outside (with slight delay to avoid immediate closure)
      const cleanup = () => {
        if (picker._cleanupTimeout) {
          clearTimeout(picker._cleanupTimeout);
          picker._cleanupTimeout = null;
        }
        if (picker._closeHandler) {
          document.removeEventListener('click', picker._closeHandler);
          picker._closeHandler = null;
        }
      };

      const timeoutId = setTimeout(() => {
        const closeHandler = (e) => {
          if (!picker.contains(e.target) && e.target !== button) {
            cleanup();
            picker.remove();
          }
        };
        picker._closeHandler = closeHandler;
        document.addEventListener('click', closeHandler);
      }, 100);

      picker._cleanupTimeout = timeoutId;

      // Ensure any external call to picker.remove() also performs cleanup
      const originalRemove = picker.remove.bind(picker);
      picker.remove = function(...args) {
        cleanup();
        return originalRemove(...args);
      };
    },

    addReaction: function(cardId, emoji) {
      if (!this.reactions[cardId]) {
        this.reactions[cardId] = {};
      }

      if (this.reactions[cardId][emoji]) {
        this.reactions[cardId][emoji]++;
      } else {
        this.reactions[cardId][emoji] = 1;
      }

      this.saveReactions();
      this.updateReactionDisplay(cardId);
      this.triggerReactionAnimation(emoji);

      // Show toast notification
      const reactionLabel = this.reactionIcons.find(r => r.icon === emoji)?.label || 'reaction';
      this.showReactionToast(reactionLabel);

      // Announce to screen reader
      if (window.a11y && window.a11y.announce) {
        window.a11y.announce(`Reacted with ${reactionLabel}`);
      }
    },

    showReactionToast: function(label) {
      const existing = document.querySelector('.reaction-toast');
      if (existing) existing.remove();

      const toast = document.createElement('div');
      toast.className = 'reaction-toast';
      toast.textContent = `Reacted with ${label}`;
      document.body.appendChild(toast);

      setTimeout(() => toast.remove(), 2000);
    },

    updateReactionDisplay: function(cardId) {
      const card = document.querySelector(`[data-card-id="${cardId}"]`);
      if (!card) return;

      const countsDiv = card.querySelector('.reaction-counts');
      if (!countsDiv) return;

      const reactions = this.reactions[cardId] || {};
      countsDiv.innerHTML = '';

      Object.entries(reactions).forEach(([iconName, count]) => {
        if (count > 0) {
          const reactionCount = document.createElement('span');
          reactionCount.className = 'reaction-count';
          reactionCount.innerHTML = `<iconify-icon icon="${iconName}" width="14" height="14"></iconify-icon> ${count}`;
          countsDiv.appendChild(reactionCount);
        }
      });
    },

    triggerReactionAnimation: function(iconName) {
      // Respect reduced motion preference
      if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        return;
      }

      const floater = document.createElement('div');
      floater.className = 'reaction-float';
      floater.innerHTML = `<iconify-icon icon="${iconName}" width="48" height="48"></iconify-icon>`;
      document.body.appendChild(floater);

      setTimeout(() => floater.remove(), 1500);
    },

    initCelebrations: function() {
      this.checkForCelebrations();
    },

    checkForCelebrations: function() {
      const heroSection = document.querySelector('.hero-section');
      if (heroSection && !sessionStorage.getItem('celebration_shown')) {
        setTimeout(() => {
          this.triggerConfetti();
          sessionStorage.setItem('celebration_shown', 'true');
        }, 500);
      }
    },

    triggerConfetti: function() {
      if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        return;
      }

      const colors = ['#21d19f', '#2980b9', '#f39c12', '#e74c3c', '#9b59b6'];
      const count = 30;

      for (let i = 0; i < count; i++) {
        setTimeout(() => {
          const confetti = document.createElement('div');
          confetti.className = 'confetti-piece';
          confetti.style.cssText = `
            left: ${Math.random() * 100}%;
            background: ${colors[Math.floor(Math.random() * colors.length)]};
            border-radius: ${Math.random() > 0.5 ? '50%' : '0'};
            transform: rotate(${Math.random() * 360}deg);
            animation: confettiFall ${2 + Math.random() * 2}s linear forwards;
          `;

          document.body.appendChild(confetti);
          setTimeout(() => confetti.remove(), 4000);
        }, i * 30);
      }
    }
  };

  // Add styles for social features
  const styles = document.createElement('style');
  styles.textContent = `
    @keyframes pickerSlideIn {
      from { opacity: 0; transform: translateY(-10px); }
      to   { opacity: 1; transform: translateY(0); }
    }

    @keyframes reactionFloat {
      0%   { opacity: 1; transform: translate(-50%, -50%) scale(1); }
      50%  { transform: translate(-50%, -70%) scale(1.5); }
      100% { opacity: 0; transform: translate(-50%, -100%) scale(2); }
    }

    @keyframes confettiFall {
      to { transform: translateY(100vh) rotate(720deg); opacity: 0; }
    }

    @keyframes reactionToastFade {
      0%   { opacity: 0; transform: translateX(-50%) translateY(10px); }
      15%  { opacity: 1; transform: translateX(-50%) translateY(0); }
      85%  { opacity: 1; transform: translateX(-50%) translateY(0); }
      100% { opacity: 0; transform: translateX(-50%) translateY(-10px); }
    }

    .reaction-bar {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      margin-top: 0.5rem;
      padding-top: 0.5rem;
      border-top: 1px solid var(--border-color, rgba(255,255,255,0.05));
    }

    .reaction-btn {
      background: none;
      border: 1px solid var(--border-color, rgba(255,255,255,0.2));
      border-radius: 20px;
      padding: 0.25rem 0.75rem;
      cursor: pointer;
      font-size: 1rem;
      color: inherit;
      transition: all 0.2s;
    }

    .reaction-btn:hover {
      background: rgba(255, 255, 255, 0.1);
      transform: scale(1.1);
    }

    .emoji-picker {
      position: absolute;
      background: var(--bg-card, #1a253a);
      border: 1px solid var(--border-color, #2a3a52);
      border-radius: 12px;
      padding: 0.75rem;
      display: flex;
      gap: 0.5rem;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
      z-index: 1000;
      animation: pickerSlideIn 0.2s ease-out;
    }

    .emoji-btn {
      background: none;
      border: none;
      color: var(--text-primary, white);
      cursor: pointer;
      padding: 0.25rem;
      border-radius: 4px;
      transition: all 0.2s;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .emoji-btn:hover {
      background: rgba(255, 255, 255, 0.1);
      transform: scale(1.3);
    }

    .reaction-counts {
      display: flex;
      gap: 0.5rem;
      flex-wrap: wrap;
    }

    .reaction-count {
      background: var(--bg-primary, #0b162a);
      border-radius: 12px;
      padding: 0.25rem 0.5rem;
      font-size: 0.875rem;
      display: inline-flex;
      align-items: center;
      gap: 0.25rem;
    }

    .reaction-float {
      position: fixed;
      left: 50%;
      top: 50%;
      transform: translate(-50%, -50%);
      color: var(--accent-green, #21d19f);
      pointer-events: none;
      z-index: 9999;
      animation: reactionFloat 1.5s ease-out forwards;
    }

    .reaction-toast {
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
      pointer-events: none;
      animation: reactionToastFade 2s ease forwards;
    }

    .confetti-piece {
      position: fixed;
      top: -10px;
      width: 10px;
      height: 10px;
      pointer-events: none;
      z-index: 9998;
    }
  `;
  document.head.appendChild(styles);

  // Initialize when DOM is ready
  function initSocial() {
    try {
      SocialReactions.init();

      window.socialFeatures = {
        react: SocialReactions.addReaction.bind(SocialReactions),
        celebrate: SocialReactions.triggerConfetti.bind(SocialReactions)
      };
    } catch (e) {
      console.error('Failed to initialize social features:', e);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSocial);
  } else {
    initSocial();
  }

})();
