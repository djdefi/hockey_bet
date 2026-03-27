// Theme Init — runs inline (not deferred) to prevent flash of wrong theme
(function() {
  try {
    var css = localStorage.getItem('nhl_fan_team_css');
    if (css) {
      var vars = JSON.parse(css);
      var root = document.documentElement;
      var keys = Object.keys(vars);
      for (var i = 0; i < keys.length; i++) {
        root.style.setProperty(keys[i], vars[keys[i]]);
      }
      var meta = document.querySelector('meta[name="theme-color"]');
      if (meta && vars['--color-bg-primary']) {
        meta.setAttribute('content', vars['--color-bg-primary']);
      }
    }
  } catch(e) { /* silent fail — default theme will show */ }
})();
