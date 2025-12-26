/**
 * Social Reactions & Engagement
 * Emoji reactions, celebrations, and friendly competition features
 */

(function() {
  'use strict';
  
  // Social Reactions Manager
  const SocialReactions = {
    // Available emoji reactions
    emojis: ['👍', '🔥', '😂', '💪', '🏆', '😢', '👀', '🎉'],
    
    // In-memory storage with localStorage persistence
    reactions: {},
    
    init: function() {
      this.loadReactions();
      this.initReactionButtons();
      this.initCelebrations();
    },
    
    loadReactions: function() {
      // Load from localStorage
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
      // Save to localStorage
      try {
        localStorage.setItem('hockey_reactions', JSON.stringify(this.reactions));
      } catch (e) {
        console.warn('Could not save reactions:', e);
      }
    },
    
    initReactionButtons: function() {
      // Add reaction buttons to stat cards and matchup cards
      const cards = document.querySelectorAll('.stat-card-square, .matchup-card, .team-card');
      
      cards.forEach((card, index) => {
        // Skip if already has reactions
        if (card.querySelector('.reaction-bar')) return;
        
        const cardId = `card-${index}`;
        card.dataset.cardId = cardId;
        
        // Create reaction bar
        const reactionBar = document.createElement('div');
        reactionBar.className = 'reaction-bar';
        reactionBar.innerHTML = `
          <button class="reaction-btn" aria-label="Add reaction" title="React">
            <span>😊</span>
          </button>
          <div class="reaction-counts"></div>
        `;
        
        // Style the reaction bar
        reactionBar.style.cssText = `
          display: flex;
          align-items: center;
          gap: 0.5rem;
          margin-top: 0.5rem;
          padding-top: 0.5rem;
          border-top: 1px solid var(--border-color, rgba(255,255,255,0.1));
        `;
        
        const btn = reactionBar.querySelector('.reaction-btn');
        btn.style.cssText = `
          background: none;
          border: 1px solid var(--border-color, rgba(255,255,255,0.2));
          border-radius: 20px;
          padding: 0.25rem 0.75rem;
          cursor: pointer;
          font-size: 1rem;
          transition: all 0.2s;
        `;
        
        btn.addEventListener('click', (e) => {
          e.stopPropagation();
          this.showEmojiPicker(cardId, btn);
        });
        
        btn.addEventListener('mouseenter', () => {
          btn.style.transform = 'scale(1.1)';
        });
        
        btn.addEventListener('mouseleave', () => {
          btn.style.transform = 'scale(1)';
        });
        
        card.appendChild(reactionBar);
        
        // Update reaction counts
        this.updateReactionDisplay(cardId);
      });
    },
    
    showEmojiPicker: function(cardId, button) {
      // Remove existing picker
      const existing = document.querySelector('.emoji-picker');
      if (existing) existing.remove();
      
      const picker = document.createElement('div');
      picker.className = 'emoji-picker';
      picker.style.cssText = `
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
      `;
      
      // Position near button, with viewport boundary checks
      const rect = button.getBoundingClientRect();
      const viewportWidth = window.innerWidth;
      const viewportHeight = window.innerHeight;
      const pickerWidth = 300; // Approximate width
      const pickerHeight = 60; // Approximate height
      
      let top = rect.bottom + 5;
      let left = rect.left;
      
      // Check bottom boundary
      if (top + pickerHeight > viewportHeight) {
        top = rect.top - pickerHeight - 5;
      }
      
      // Check right boundary
      if (left + pickerWidth > viewportWidth) {
        left = viewportWidth - pickerWidth - 10;
      }
      
      // Check left boundary
      if (left < 10) {
        left = 10;
      }
      
      picker.style.top = top + 'px';
      picker.style.left = left + 'px';
      
      // Add emoji buttons
      this.emojis.forEach(emoji => {
        const emojiBtn = document.createElement('button');
        emojiBtn.textContent = emoji;
        emojiBtn.className = 'emoji-btn';
        emojiBtn.style.cssText = `
          background: none;
          border: none;
          font-size: 1.5rem;
          cursor: pointer;
          padding: 0.25rem;
          border-radius: 4px;
          transition: all 0.2s;
        `;
        
        emojiBtn.addEventListener('mouseenter', () => {
          emojiBtn.style.transform = 'scale(1.3)';
        });
        
        emojiBtn.addEventListener('mouseleave', () => {
          emojiBtn.style.transform = 'scale(1)';
        });
        
        emojiBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          this.addReaction(cardId, emoji);
          picker.remove();
        });
        
        picker.appendChild(emojiBtn);
      });
      
      document.body.appendChild(picker);
      
      // Close picker when clicking outside (with slight delay to avoid immediate closure)
      let closeHandler = null;
      const timeoutId = setTimeout(() => {
        closeHandler = (e) => {
          if (!picker.contains(e.target) && e.target !== button) {
            picker.remove();
            document.removeEventListener('click', closeHandler);
          }
        };
        document.addEventListener('click', closeHandler);
      }, 100);
      
      // Store cleanup function in case picker is removed early
      picker._cleanupTimeout = timeoutId;
      picker._closeHandler = closeHandler;
    },
    
    addReaction: function(cardId, emoji) {
      // Initialize if needed
      if (!this.reactions[cardId]) {
        this.reactions[cardId] = {};
      }
      
      // Increment reaction count
      if (this.reactions[cardId][emoji]) {
        this.reactions[cardId][emoji]++;
      } else {
        this.reactions[cardId][emoji] = 1;
      }
      
      this.saveReactions();
      this.updateReactionDisplay(cardId);
      this.triggerReactionAnimation(emoji);
      
      // Announce to screen reader
      if (window.a11y && window.a11y.announce) {
        window.a11y.announce(`Reacted with ${emoji}`);
      }
    },
    
    updateReactionDisplay: function(cardId) {
      const card = document.querySelector(`[data-card-id="${cardId}"]`);
      if (!card) return;
      
      const countsDiv = card.querySelector('.reaction-counts');
      if (!countsDiv) return;
      
      const reactions = this.reactions[cardId] || {};
      
      // Clear and rebuild
      countsDiv.innerHTML = '';
      countsDiv.style.cssText = `
        display: flex;
        gap: 0.5rem;
        flex-wrap: wrap;
      `;
      
      Object.entries(reactions).forEach(([emoji, count]) => {
        if (count > 0) {
          const reactionCount = document.createElement('span');
          reactionCount.className = 'reaction-count';
          reactionCount.innerHTML = `${emoji} ${count}`;
          reactionCount.style.cssText = `
            background: var(--bg-primary, #0b162a);
            border-radius: 12px;
            padding: 0.25rem 0.5rem;
            font-size: 0.875rem;
            display: inline-flex;
            align-items: center;
            gap: 0.25rem;
          `;
          countsDiv.appendChild(reactionCount);
        }
      });
    },
    
    triggerReactionAnimation: function(emoji) {
      // Create floating emoji animation
      const floater = document.createElement('div');
      floater.className = 'reaction-float';
      floater.textContent = emoji;
      floater.style.cssText = `
        position: fixed;
        left: 50%;
        top: 50%;
        transform: translate(-50%, -50%);
        font-size: 3rem;
        pointer-events: none;
        z-index: 9999;
        animation: reactionFloat 1.5s ease-out forwards;
      `;
      
      document.body.appendChild(floater);
      
      setTimeout(() => floater.remove(), 1500);
    },
    
    initCelebrations: function() {
      // Trigger celebration animations on page load for recent achievements
      this.checkForCelebrations();
    },
    
    checkForCelebrations: function() {
      // Check if there are hero sections (league leader, etc.)
      const heroSection = document.querySelector('.hero-section');
      if (heroSection && !sessionStorage.getItem('celebration_shown')) {
        setTimeout(() => {
          this.triggerConfetti();
          sessionStorage.setItem('celebration_shown', 'true');
        }, 500);
      }
    },
    
    triggerConfetti: function() {
      // Respect reduced motion preference
      if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
        return; // Skip confetti animation
      }
      
      // Simple confetti effect
      const colors = ['#21d19f', '#2980b9', '#f39c12', '#e74c3c', '#9b59b6'];
      const count = 30;
      
      for (let i = 0; i < count; i++) {
        setTimeout(() => {
          const confetti = document.createElement('div');
          confetti.className = 'confetti-piece';
          confetti.style.cssText = `
            position: fixed;
            left: ${Math.random() * 100}%;
            top: -10px;
            width: 10px;
            height: 10px;
            background: ${colors[Math.floor(Math.random() * colors.length)]};
            border-radius: ${Math.random() > 0.5 ? '50%' : '0'};
            transform: rotate(${Math.random() * 360}deg);
            pointer-events: none;
            z-index: 9998;
            animation: confettiFall ${2 + Math.random() * 2}s linear forwards;
          `;
          
          document.body.appendChild(confetti);
          
          setTimeout(() => confetti.remove(), 4000);
        }, i * 30);
      }
    }
  };
  
  // Quick Stats Comparison Tool
  const QuickCompare = {
    init: function() {
      this.addCompareButtons();
    },
    
    addCompareButtons: function() {
      // Add compare buttons to team cards
      const teamCards = document.querySelectorAll('.team-card, .stat-card-square');
      
      teamCards.forEach(card => {
        // Skip if already has compare button
        if (card.querySelector('.compare-btn')) return;
        
        const compareBtn = document.createElement('button');
        compareBtn.className = 'compare-btn';
        compareBtn.innerHTML = '⚖️ Compare';
        compareBtn.style.cssText = `
          background: rgba(41, 128, 185, 0.2);
          border: 1px solid rgba(41, 128, 185, 0.5);
          color: var(--text-primary, white);
          padding: 0.25rem 0.5rem;
          border-radius: 6px;
          font-size: 0.75rem;
          cursor: pointer;
          margin-top: 0.5rem;
          transition: all 0.2s;
        `;
        
        compareBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          this.showCompareModal(card);
        });
        
        compareBtn.addEventListener('mouseenter', () => {
          compareBtn.style.background = 'rgba(41, 128, 185, 0.4)';
        });
        
        compareBtn.addEventListener('mouseleave', () => {
          compareBtn.style.background = 'rgba(41, 128, 185, 0.2)';
        });
        
        card.appendChild(compareBtn);
      });
    },
    
    showCompareModal: function(card) {
      // Get card info for comparison
      const fanName = card.querySelector('.stat-fan-name, .team-name');
      const cardTitle = card.querySelector('.stat-label, h3');
      
      const modal = document.createElement('div');
      modal.className = 'compare-modal';
      modal.innerHTML = `
        <div class="modal-backdrop"></div>
        <div class="modal-content">
          <h3>⚖️ Quick Stats</h3>
          <p><strong>${fanName ? fanName.textContent : 'Team'}</strong></p>
          <p class="text-secondary" style="margin-top: 0.5rem;">
            Head-to-head comparison and rivalry tracking features are being developed.
            Check back soon for detailed matchup analysis!
          </p>
          <button class="close-modal-btn">Got it</button>
        </div>
      `;
      
      modal.style.cssText = `
        position: fixed;
        inset: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 10000;
      `;
      
      document.body.appendChild(modal);
      
      modal.querySelector('.close-modal-btn').addEventListener('click', () => {
        modal.remove();
      });
      
      modal.querySelector('.modal-backdrop').addEventListener('click', () => {
        modal.remove();
      });
    }
  };
  
  // Add CSS animations
  const styles = document.createElement('style');
  styles.textContent = `
    @keyframes pickerSlideIn {
      from {
        opacity: 0;
        transform: translateY(-10px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }
    
    @keyframes reactionFloat {
      0% {
        opacity: 1;
        transform: translate(-50%, -50%) scale(1);
      }
      50% {
        transform: translate(-50%, -70%) scale(1.5);
      }
      100% {
        opacity: 0;
        transform: translate(-50%, -100%) scale(2);
      }
    }
    
    @keyframes confettiFall {
      to {
        transform: translateY(100vh) rotate(720deg);
        opacity: 0;
      }
    }
    
    .reaction-bar button:hover {
      background: rgba(255, 255, 255, 0.1);
    }
    
    .emoji-btn:hover {
      background: rgba(255, 255, 255, 0.1);
    }
    
    .modal-backdrop {
      position: absolute;
      inset: 0;
      background: rgba(0, 0, 0, 0.8);
    }
    
    .modal-content {
      position: relative;
      background: var(--bg-card, #1a253a);
      padding: 2rem;
      border-radius: 12px;
      max-width: 500px;
      width: 90%;
      text-align: center;
    }
    
    .modal-content h3 {
      margin-top: 0;
    }
    
    .close-modal-btn {
      background: var(--accent-green, #21d19f);
      color: white;
      border: none;
      padding: 0.5rem 1.5rem;
      border-radius: 6px;
      cursor: pointer;
      font-weight: 600;
      margin-top: 1rem;
    }
    
    .close-modal-btn:hover {
      opacity: 0.9;
    }
  `;
  document.head.appendChild(styles);
  
  // Initialize when DOM is ready
  function initSocial() {
    try {
      SocialReactions.init();
      QuickCompare.init();
      
      // Expose globally for integration
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
