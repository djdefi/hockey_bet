(function() {
  'use strict';

  function switchTab(tabName) {
    document.querySelectorAll('.tab-section').forEach((section) => {
      section.classList.remove('active');
    });

    const selectedTab = document.getElementById(tabName + '-tab');
    if (selectedTab) {
      selectedTab.classList.add('active');
    }

    document.querySelectorAll('.nav-item').forEach((item) => {
      item.classList.remove('active');
      item.removeAttribute('aria-current');
    });
    document.querySelectorAll(`.nav-item[data-tab="${tabName}"]`).forEach((item) => {
      item.classList.add('active');
      item.setAttribute('aria-current', 'page');
    });

    document.querySelectorAll('.desktop-tab').forEach((tab) => {
      tab.classList.remove('active');
      tab.removeAttribute('aria-current');
    });
    document.querySelectorAll(`.desktop-tab[data-tab="${tabName}"]`).forEach((tab) => {
      tab.classList.add('active');
      tab.setAttribute('aria-current', 'page');
    });

    if (tabName === 'trends' && !window.chartLoaded && typeof window.loadStandingsTrendChart === 'function') {
      window.loadStandingsTrendChart();
    }

    if (tabName === 'playoff-odds' && !window.playoffOddsChartLoaded && typeof window.loadPlayoffOddsChart === 'function') {
      window.loadPlayoffOddsChart();
    }
  }

  function toggleAchievementCard(card) {
    const entries = card.querySelectorAll('.achievement-entry');
    const isExpanded = card.classList.contains('expanded');
    const button = card.querySelector('.expand-toggle');

    if (isExpanded) {
      card.classList.remove('expanded');
      entries.forEach((entry, idx) => {
        if (idx > 0) {
          entry.classList.add('hidden');
        }
      });
      card.setAttribute('aria-expanded', 'false');
      if (button) {
        const expandIcon = button.querySelector('.expand-icon');
        if (expandIcon) {
          expandIcon.textContent = '▼';
        }
      }
      return;
    }

    card.classList.add('expanded');
    entries.forEach((entry) => entry.classList.remove('hidden'));
    card.setAttribute('aria-expanded', 'true');
    if (button) {
      const expandIcon = button.querySelector('.expand-icon');
      if (expandIcon) {
        expandIcon.textContent = '▲';
      }
    }
  }

  window.switchTab = switchTab;

  document.querySelectorAll('.nav-item, .desktop-tab').forEach((item) => {
    item.addEventListener('click', function() {
      const tabName = this.getAttribute('data-tab');
      switchTab(tabName);
    });

    item.addEventListener('keydown', function(event) {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        const tabName = this.getAttribute('data-tab');
        switchTab(tabName);
      }
    });
  });

  document.querySelectorAll('.team-card').forEach((card) => {
    card.addEventListener('click', function() {
      this.classList.toggle('expanded');
      this.setAttribute('aria-expanded', this.classList.contains('expanded'));
    });

    card.addEventListener('keydown', function(event) {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        this.classList.toggle('expanded');
        this.setAttribute('aria-expanded', this.classList.contains('expanded'));
      }
    });
  });

  document.querySelectorAll('.achievement-card.expandable').forEach((card) => {
    card.addEventListener('click', function() {
      toggleAchievementCard(this);
    });

    card.addEventListener('keydown', function(event) {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        toggleAchievementCard(this);
      }
    });
  });

  document.querySelectorAll('.date-group-toggle').forEach((button) => {
    button.addEventListener('click', function(event) {
      event.preventDefault();
      const groupName = this.getAttribute('data-group');
      const matchupsList = document.getElementById('matchups-' + groupName);
      const toggleIcon = this.querySelector('.toggle-icon');
      const isExpanded = this.getAttribute('aria-expanded') === 'true';

      if (!matchupsList) {
        return;
      }

      if (isExpanded) {
        matchupsList.classList.add('matchups-list-hidden');
        this.setAttribute('aria-expanded', 'false');
        if (toggleIcon) {
          toggleIcon.textContent = '▶';
        }
        return;
      }

      matchupsList.classList.remove('matchups-list-hidden');
      this.setAttribute('aria-expanded', 'true');
      if (toggleIcon) {
        toggleIcon.textContent = '▼';
      }
    });
  });

  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      const hadServiceWorkerController = Boolean(navigator.serviceWorker.controller);
      let hasReloadedForServiceWorker = false;

      navigator.serviceWorker.register('./service-worker.js')
        .then((registration) => {
          registration.update();

          if (registration.waiting) {
            registration.waiting.postMessage({ type: 'SKIP_WAITING' });
          }

          registration.addEventListener('updatefound', () => {
            const installingWorker = registration.installing;
            if (!installingWorker) {
              return;
            }

            installingWorker.addEventListener('statechange', () => {
              if (installingWorker.state === 'installed' && navigator.serviceWorker.controller && registration.waiting) {
                registration.waiting.postMessage({ type: 'SKIP_WAITING' });
              }
            });
          });
        })
        .catch((error) => console.warn('ServiceWorker registration failed:', error));

      navigator.serviceWorker.addEventListener('controllerchange', () => {
        if (!hadServiceWorkerController || hasReloadedForServiceWorker) {
          return;
        }

        hasReloadedForServiceWorker = true;
        window.location.reload();
      });
    });
  }
})();
