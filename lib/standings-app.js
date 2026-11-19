(function() {
  'use strict';

  function switchTab(tabName) {
    document.querySelectorAll('.tab-section').forEach((section) => {
      section.classList.remove('active');
    });

    const selectedTab = document.getElementById(tabName + '-tab');
    if (selectedTab) {
      selectedTab.classList.add('active');
      window.scrollTo({ top: 0, left: 0, behavior: 'instant' });
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

    if (tabName === 'playoff-odds' && document.querySelector('.cup-model-odds')?.open && !window.playoffOddsChartLoaded && typeof window.loadPlayoffOddsChart === 'function') {
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

  const cupTeam = document.getElementById('cup-team');
  if (cupTeam) {
    function traceCupTeam(abbrev) {
      cupTeam.value = abbrev;
      const field = document.querySelector('.cup-field');
      const route = document.querySelector(`.cup-team[data-cup-team="${abbrev}"]`);
      field.classList.toggle('has-selection', Boolean(route));
      document.querySelectorAll('[data-cup-team]').forEach(button => {
        button.setAttribute('aria-pressed', String(Boolean(abbrev) && button.dataset.cupTeam === abbrev));
      });
      document.querySelectorAll('[data-route-team]').forEach(path => {
        path.classList.toggle('is-route', path.dataset.routeTeam === abbrev);
      });
      document.querySelectorAll('[data-final-conference]').forEach(path => {
        path.classList.toggle('is-route', path.dataset.finalConference === route?.closest('[data-conference]').dataset.conference);
      });
      const standing = document.querySelector(`.cup-divisions [data-cup-team="${abbrev}"]`);
      document.getElementById('cup-route').textContent = route
        ? `${cupTeam.selectedOptions[0].textContent}. ${route.dataset.route}`
        : standing?.dataset.route || 'Choose a team or select its crest to light up its route. Later rounds show possible opponents, not predicted winners.';
    }
    cupTeam.addEventListener('change', () => traceCupTeam(cupTeam.value));
    document.querySelectorAll('[data-cup-team]').forEach(button => {
      button.addEventListener('click', () => traceCupTeam(button.dataset.cupTeam));
    });
    const storedTeam = window.TeamThemes?.getTeamTheme(window.TeamThemes.getStoredTeam()).abbrev;
    if ([...cupTeam.options].some(option => option.value === storedTeam)) traceCupTeam(storedTeam);
  }
  document.querySelector('.cup-model-odds')?.addEventListener('toggle', event => {
    if (event.target.open && !window.playoffOddsChartLoaded) window.loadPlayoffOddsChart();
  });

  const briefTeam = document.getElementById('brief-team');
  if (briefTeam) {
    briefTeam.addEventListener('change', () => {
      document.querySelectorAll('[data-brief-team]').forEach((brief) => {
        brief.hidden = Boolean(briefTeam.value) && brief.dataset.briefTeam !== briefTeam.value;
      });
    });
  }

  document.querySelectorAll('.nav-item, .desktop-tab, .view-link').forEach((item) => {
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
          return registration.update();
        })
        .catch((error) => console.warn('ServiceWorker registration or update failed:', error));

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
