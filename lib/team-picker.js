(function() {
  'use strict';

  // ── Style Injection ──────────────────────────────────────────────────
  var style = document.createElement('style');
  style.textContent = `
    /* Trigger button */
    .team-picker-trigger {
      position: absolute;
      top: 50%;
      right: 0;
      transform: translateY(-50%);
      background: var(--color-bg-tertiary);
      border: 1px solid var(--color-border-default);
      border-radius: var(--radius-md, 8px);
      color: var(--color-text-secondary);
      cursor: pointer;
      padding: 6px;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: color 0.2s, background 0.2s, border-color 0.2s;
      z-index: 10;
    }
    .team-picker-trigger:hover,
    .team-picker-trigger:focus-visible {
      color: var(--color-accent-primary);
      background: var(--color-bg-hover);
      border-color: var(--color-accent-primary);
      outline: none;
    }
    .team-picker-trigger .team-dot {
      position: absolute;
      top: -3px;
      right: -3px;
      width: 10px;
      height: 10px;
      border-radius: 50%;
      border: 2px solid var(--color-bg-primary);
    }

    /* Backdrop */
    .team-picker-backdrop {
      position: fixed;
      inset: 0;
      z-index: 900;
      background: rgba(0, 0, 0, 0.7);
      backdrop-filter: blur(4px);
      -webkit-backdrop-filter: blur(4px);
      opacity: 0;
      transition: opacity 0.25s ease;
      display: none;
    }
    .team-picker-backdrop.open {
      display: block;
      opacity: 1;
    }
    .team-picker-backdrop.closing {
      opacity: 0;
    }

    /* Modal */
    .team-picker-modal {
      position: fixed;
      inset: 0;
      z-index: 901;
      display: none;
      align-items: center;
      justify-content: center;
      padding: 16px;
      pointer-events: none;
    }
    .team-picker-modal.open {
      display: flex;
      pointer-events: auto;
    }

    .team-picker-content {
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border-default);
      border-radius: var(--radius-lg, 12px);
      max-width: 680px;
      width: 100%;
      max-height: 85vh;
      overflow-y: auto;
      padding: 24px;
      position: relative;
      transform: scale(0.92) translateY(12px);
      opacity: 0;
      transition: transform 0.25s ease, opacity 0.25s ease;
      box-shadow: 0 24px 48px rgba(0,0,0,0.4);
      overscroll-behavior: contain;
    }
    .team-picker-modal.open .team-picker-content {
      transform: scale(1) translateY(0);
      opacity: 1;
    }
    .team-picker-modal.closing .team-picker-content {
      transform: scale(0.92) translateY(12px);
      opacity: 0;
    }

    /* Header */
    .team-picker-header {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      margin-bottom: 20px;
    }
    .team-picker-header h2 {
      font-size: 1.25rem;
      font-weight: 700;
      color: var(--color-text-primary);
      margin: 0 0 4px;
    }
    .team-picker-header p {
      font-size: 0.85rem;
      color: var(--color-text-secondary);
      margin: 0;
    }
    .team-picker-close {
      background: transparent;
      border: none;
      color: var(--color-text-secondary);
      cursor: pointer;
      padding: 4px;
      margin: -4px -4px 0 8px;
      border-radius: var(--radius-sm, 4px);
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      transition: color 0.15s, background 0.15s;
    }
    .team-picker-close:hover,
    .team-picker-close:focus-visible {
      color: var(--color-text-primary);
      background: var(--color-bg-hover);
      outline: none;
    }

    /* Reset button */
    .team-picker-reset {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: var(--color-bg-tertiary);
      border: 1px solid var(--color-border-default);
      border-radius: var(--radius-md, 8px);
      color: var(--color-text-secondary);
      font-size: 0.8rem;
      padding: 6px 12px;
      cursor: pointer;
      margin-bottom: 20px;
      transition: color 0.15s, border-color 0.15s, background 0.15s;
    }
    .team-picker-reset:hover,
    .team-picker-reset:focus-visible {
      color: var(--color-accent-primary);
      border-color: var(--color-accent-primary);
      background: var(--color-bg-hover);
      outline: none;
    }

    /* Division sections */
    .team-picker-division {
      margin-bottom: 20px;
    }
    .team-picker-division:last-child {
      margin-bottom: 0;
    }
    .team-picker-division h3 {
      font-size: 0.75rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      color: var(--color-text-muted);
      margin: 0 0 10px;
      padding-bottom: 6px;
      border-bottom: 1px solid var(--color-border-subtle);
    }

    /* Team grid */
    .team-picker-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 8px;
    }
    @media (min-width: 520px) {
      .team-picker-grid {
        grid-template-columns: repeat(4, 1fr);
      }
    }

    /* Team card */
    .team-picker-card {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 6px;
      padding: 12px 6px;
      background: var(--color-bg-primary);
      border: 2px solid var(--color-border-subtle);
      border-radius: var(--radius-md, 8px);
      cursor: pointer;
      transition: border-color 0.15s, background 0.15s, transform 0.1s;
      position: relative;
      text-align: center;
      min-width: 0;
    }
    .team-picker-card:hover,
    .team-picker-card:focus-visible {
      border-color: var(--color-border-strong);
      background: var(--color-bg-hover);
      outline: none;
    }
    .team-picker-card:active {
      transform: scale(0.97);
    }
    .team-picker-card.selected {
      border-color: var(--color-accent-primary);
      background: var(--color-bg-hover);
    }
    .team-picker-card.selected::after {
      content: '';
      position: absolute;
      top: 4px;
      right: 4px;
      width: 18px;
      height: 18px;
      background: var(--color-accent-primary);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    /* Color swatch */
    .team-picker-swatch {
      display: flex;
      gap: 0;
      border-radius: 999px;
      overflow: hidden;
      width: 32px;
      height: 32px;
      flex-shrink: 0;
      border: 2px solid var(--color-border-default);
    }
    .team-picker-swatch span {
      flex: 1;
    }

    /* Team name */
    .team-picker-name {
      font-size: 0.75rem;
      font-weight: 600;
      color: var(--color-text-primary);
      line-height: 1.2;
      word-break: break-word;
    }

    /* Selected checkmark icon */
    .team-picker-check {
      position: absolute;
      top: 4px;
      right: 4px;
      width: 18px;
      height: 18px;
      background: var(--color-accent-primary);
      border-radius: 50%;
      display: none;
      align-items: center;
      justify-content: center;
    }
    .team-picker-card.selected .team-picker-check {
      display: flex;
    }
    .team-picker-check svg {
      width: 11px;
      height: 11px;
      stroke: var(--color-bg-primary);
      stroke-width: 3;
      fill: none;
    }

    /* Live region (sr-only) */
    .team-picker-live {
      position: absolute;
      width: 1px;
      height: 1px;
      overflow: hidden;
      clip: rect(0, 0, 0, 0);
      white-space: nowrap;
      border: 0;
    }

    /* Scrollbar styling */
    .team-picker-content::-webkit-scrollbar {
      width: 6px;
    }
    .team-picker-content::-webkit-scrollbar-track {
      background: transparent;
    }
    .team-picker-content::-webkit-scrollbar-thumb {
      background: var(--color-border-default);
      border-radius: 3px;
    }
  `;
  document.head.appendChild(style);

  // ── State ─────────────────────────────────────────────────────────────
  var isOpen = false;
  var previousFocus = null;
  var backdrop, modal, content, liveRegion;

  // ── Helpers ───────────────────────────────────────────────────────────

  function createEl(tag, attrs, children) {
    var el = document.createElement(tag);
    if (attrs) {
      Object.keys(attrs).forEach(function(k) {
        if (k === 'className') el.className = attrs[k];
        else if (k === 'textContent') el.textContent = attrs[k];
        else if (k === 'innerHTML') el.innerHTML = attrs[k];
        else if (k.startsWith('on')) el.addEventListener(k.slice(2).toLowerCase(), attrs[k]);
        else el.setAttribute(k, attrs[k]);
      });
    }
    if (children) {
      children.forEach(function(c) {
        if (c) el.appendChild(typeof c === 'string' ? document.createTextNode(c) : c);
      });
    }
    return el;
  }

  function announce(text) {
    if (liveRegion) {
      liveRegion.textContent = '';
      setTimeout(function() { liveRegion.textContent = text; }, 50);
    }
  }

  function checkSVG() {
    var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('viewBox', '0 0 14 14');
    var path = document.createElementNS('http://www.w3.org/2000/svg', 'polyline');
    path.setAttribute('points', '2.5 7 5.5 10.5 11.5 3.5');
    svg.appendChild(path);
    return svg;
  }

  // ── Build Modal ───────────────────────────────────────────────────────

  function buildModal() {
    var teams = window.TeamThemes ? window.TeamThemes.getAllTeams() : {};
    var stored = window.TeamThemes ? window.TeamThemes.getStoredTeam() : null;

    // Backdrop
    backdrop = createEl('div', { className: 'team-picker-backdrop', 'aria-hidden': 'true' });
    backdrop.addEventListener('click', closeModal);

    // Modal wrapper — clicking the wrapper area outside content also closes
    modal = createEl('div', {
      className: 'team-picker-modal',
      role: 'dialog',
      'aria-modal': 'true',
      'aria-label': 'Choose Your Team'
    });
    modal.addEventListener('click', function(e) {
      // Close if clicking the wrapper itself (not content inside it)
      if (e.target === modal) closeModal();
    });

    // Content
    content = createEl('div', { className: 'team-picker-content' });

    // Header
    var headerLeft = createEl('div', {}, [
      createEl('h2', { textContent: 'Choose Your Team' }),
      createEl('p', { textContent: "Pick your allegiance to theme the app in your team\u2019s colors" })
    ]);
    var closeBtn = createEl('button', {
      className: 'team-picker-close',
      'aria-label': 'Close team picker',
      innerHTML: '<iconify-icon icon="solar:close-circle-bold" width="24" height="24"></iconify-icon>'
    });
    closeBtn.addEventListener('click', closeModal);
    var header = createEl('div', { className: 'team-picker-header' }, [headerLeft, closeBtn]);
    content.appendChild(header);

    // Reset button
    var resetBtn = createEl('button', {
      className: 'team-picker-reset',
      innerHTML: '<iconify-icon icon="solar:refresh-bold" width="14" height="14"></iconify-icon> Reset to Default'
    });
    resetBtn.addEventListener('click', function() {
      selectTeam(null);
    });
    content.appendChild(resetBtn);

    // Division groups
    var divisions = ['Atlantic', 'Metropolitan', 'Central', 'Pacific'];
    divisions.forEach(function(div) {
      var divTeams = teams[div];
      if (!divTeams || !divTeams.length) return;

      var section = createEl('div', { className: 'team-picker-division' });
      section.appendChild(createEl('h3', { textContent: div }));

      var grid = createEl('div', { className: 'team-picker-grid' });
      divTeams.forEach(function(team) {
        var card = createEl('button', {
          className: 'team-picker-card' + (stored === team.key ? ' selected' : ''),
          'aria-label': team.name + (stored === team.key ? ' (selected)' : ''),
          'data-team': team.key
        });

        // Color swatch
        var swatch = createEl('div', { className: 'team-picker-swatch' });
        var s1 = document.createElement('span');
        s1.style.background = team.colors.primary;
        var s2 = document.createElement('span');
        s2.style.background = team.colors.secondary;
        swatch.appendChild(s1);
        swatch.appendChild(s2);
        card.appendChild(swatch);

        // Team name
        card.appendChild(createEl('span', { className: 'team-picker-name', textContent: team.name }));

        // Checkmark
        var check = createEl('span', { className: 'team-picker-check' });
        check.appendChild(checkSVG());
        card.appendChild(check);

        card.addEventListener('click', function() {
          selectTeam(team.key);
        });

        grid.appendChild(card);
      });
      section.appendChild(grid);
      content.appendChild(section);
    });

    // Live region
    liveRegion = createEl('div', {
      className: 'team-picker-live',
      'aria-live': 'polite',
      'aria-atomic': 'true',
      role: 'status'
    });
    content.appendChild(liveRegion);

    modal.appendChild(content);
    document.body.appendChild(backdrop);
    document.body.appendChild(modal);
  }

  // ── Select Team ───────────────────────────────────────────────────────

  function selectTeam(teamKey) {
    if (!window.TeamThemes) return;

    if (teamKey) {
      window.TeamThemes.setStoredTeam(teamKey);
      window.TeamThemes.applyTheme(teamKey);
      var team = window.TeamThemes.getTeamTheme(teamKey);
      announce(team && team.name ? team.name + ' theme applied' : 'Theme applied');
    } else {
      // Reset — use setStoredTeam to clear both key and cached CSS
      window.TeamThemes.setStoredTeam(null);
      window.TeamThemes.applyTheme('default');
      announce('Theme reset to default');
    }

    updateTriggerDot();
    closeModal();
  }

  // ── Open / Close ─────────────────────────────────────────────────────

  function openModal() {
    if (isOpen) return;
    isOpen = true;

    // Rebuild cards to reflect current selection
    if (modal) {
      modal.remove();
      backdrop.remove();
    }
    buildModal();

    previousFocus = document.activeElement;

    // Force reflow then add class for animation
    void backdrop.offsetHeight;
    backdrop.classList.add('open');
    modal.classList.add('open');

    document.body.style.overflow = 'hidden';

    // Focus first card or close button
    requestAnimationFrame(function() {
      var first = content.querySelector('.team-picker-card, .team-picker-close');
      if (first) first.focus();
    });

    document.addEventListener('keydown', handleKeyDown);
  }

  function closeModal() {
    if (!isOpen) return;
    isOpen = false;

    backdrop.classList.add('closing');
    modal.classList.add('closing');
    backdrop.classList.remove('open');

    document.body.style.overflow = '';
    document.removeEventListener('keydown', handleKeyDown);

    setTimeout(function() {
      modal.classList.remove('open', 'closing');
      backdrop.classList.remove('open', 'closing');
      backdrop.style.display = 'none';
      modal.style.display = 'none';
      if (previousFocus && previousFocus.focus) {
        previousFocus.focus();
      }
    }, 250);
  }

  // ── Focus Trap ────────────────────────────────────────────────────────

  function handleKeyDown(e) {
    if (e.key === 'Escape') {
      e.preventDefault();
      closeModal();
      return;
    }

    if (e.key === 'Tab' && content) {
      var focusable = content.querySelectorAll(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      );
      if (!focusable.length) return;
      var first = focusable[0];
      var last = focusable[focusable.length - 1];

      if (e.shiftKey) {
        if (document.activeElement === first) {
          e.preventDefault();
          last.focus();
        }
      } else {
        if (document.activeElement === last) {
          e.preventDefault();
          first.focus();
        }
      }
    }
  }

  // ── Trigger Button ────────────────────────────────────────────────────

  var triggerBtn = null;

  function updateTriggerDot() {
    if (!triggerBtn) return;
    var existing = triggerBtn.querySelector('.team-dot');
    if (existing) existing.remove();

    var stored = window.TeamThemes ? window.TeamThemes.getStoredTeam() : null;
    if (stored) {
      var theme = window.TeamThemes.getTeamTheme(stored);
      if (theme && theme.colors) {
        var dot = document.createElement('span');
        dot.className = 'team-dot';
        dot.style.background = theme.colors.primary;
        triggerBtn.appendChild(dot);
      }
    }
  }

  function createTrigger() {
    var header = document.querySelector('header');
    if (!header) return;

    // Ensure header is positioned for absolute children
    var pos = getComputedStyle(header).position;
    if (pos === 'static') header.style.position = 'relative';

    triggerBtn = createEl('button', {
      className: 'team-picker-trigger',
      'aria-label': 'Choose your team'
    });
    triggerBtn.innerHTML = '<iconify-icon icon="solar:palette-bold" width="22" height="22"></iconify-icon>';
    triggerBtn.addEventListener('click', openModal);

    header.appendChild(triggerBtn);
    updateTriggerDot();
  }

  // ── Init ──────────────────────────────────────────────────────────────

  function init() {
    try {
      createTrigger();
    } catch (e) {
      console.error('Failed to initialize team picker:', e);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
