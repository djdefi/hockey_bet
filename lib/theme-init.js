// Theme Init — runs inline (not deferred) to prevent flash of wrong theme
(function() {
  var STORAGE_KEY = 'nhl_fan_team_css';
  var root = document.documentElement;
  var devHostPattern = /^(localhost|127\.0\.0\.1)(:\d+)?$/;

  root.dataset.themeSource = 'default';

  try {
    var css = localStorage.getItem(STORAGE_KEY);
    if (!css) {
      return;
    }

    var vars = JSON.parse(css);
    if (!vars || typeof vars !== 'object' || Array.isArray(vars)) {
      root.dataset.themeInitError = 'invalid-theme-payload';
      return;
    }

    var keys = Object.keys(vars);
    for (var i = 0; i < keys.length; i++) {
      if (keys[i].indexOf('--') === 0) {
        root.style.setProperty(keys[i], String(vars[keys[i]]));
      }
    }

    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta && vars['--color-bg-primary']) {
      meta.setAttribute('content', String(vars['--color-bg-primary']));
    }

    root.dataset.themeSource = 'storage';
  } catch (error) {
    root.dataset.themeInitError = 'storage-parse';

    if (devHostPattern.test(window.location.host)) {
      console.warn('Theme init failed, falling back to default theme.', error);
    }
  }
})();
