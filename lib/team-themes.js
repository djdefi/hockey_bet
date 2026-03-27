/**
 * NHL Team Themes - Complete 32-team color palette system
 *
 * Powers team-based theming by mapping each NHL team to a set of
 * CSS custom property overrides. Users pick their team and the
 * app's palette updates to match.
 *
 * Usage:
 *   TeamThemes.applyTheme('avalanche');
 *   const team = TeamThemes.getTeamTheme('kraken');
 *   const grouped = TeamThemes.getAllTeams();
 */
(function () {
  'use strict';

  // ---------------------------------------------------------------------------
  // Helpers – derive dark-mode background shades from a hex color
  // ---------------------------------------------------------------------------

  function hexToHSL(hex) {
    hex = hex.replace('#', '');
    var r = parseInt(hex.substring(0, 2), 16) / 255;
    var g = parseInt(hex.substring(2, 4), 16) / 255;
    var b = parseInt(hex.substring(4, 6), 16) / 255;

    var max = Math.max(r, g, b);
    var min = Math.min(r, g, b);
    var h, s, l = (max + min) / 2;

    if (max === min) {
      h = s = 0;
    } else {
      var d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      switch (max) {
        case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break;
        case g: h = ((b - r) / d + 2) / 6; break;
        case b: h = ((r - g) / d + 2) / 6; break;
      }
    }
    return { h: Math.round(h * 360), s: Math.round(s * 100), l: Math.round(l * 100) };
  }

  function hslToHex(h, s, l) {
    s /= 100;
    l /= 100;
    var a = s * Math.min(l, 1 - l);
    function f(n) {
      var k = (n + h / 30) % 12;
      var color = l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1);
      return Math.round(255 * color).toString(16).padStart(2, '0');
    }
    return '#' + f(0) + f(8) + f(4);
  }

  function darken(hex, lightness) {
    var hsl = hexToHSL(hex);
    return hslToHex(hsl.h, Math.min(hsl.s, 45), lightness);
  }

  function buildTheme(primary, secondary) {
    var hsl = hexToHSL(primary);
    var bgPrimary   = darken(primary, 5);
    var bgSecondary = darken(primary, 9);
    var bgTertiary  = darken(primary, 14);
    var bgHover     = darken(primary, 18);
    var borderDef   = darken(primary, 20);

    return {
      '--color-bg-primary':     bgPrimary,
      '--color-bg-secondary':   bgSecondary,
      '--color-bg-tertiary':    bgTertiary,
      '--color-bg-hover':       bgHover,
      '--color-accent-primary': primary,
      '--color-accent-info':    secondary,
      '--color-border-default': borderDef,
      '--color-border-subtle':  'rgba(' + parseInt(primary.slice(1, 3), 16) + ', ' +
                                          parseInt(primary.slice(3, 5), 16) + ', ' +
                                          parseInt(primary.slice(5, 7), 16) + ', 0.15)',
      '--gradient-green':       'linear-gradient(135deg, rgba(' +
                                  parseInt(primary.slice(1, 3), 16) + ', ' +
                                  parseInt(primary.slice(3, 5), 16) + ', ' +
                                  parseInt(primary.slice(5, 7), 16) + ', 0.15) 0%, rgba(' +
                                  parseInt(secondary.slice(1, 3), 16) + ', ' +
                                  parseInt(secondary.slice(3, 5), 16) + ', ' +
                                  parseInt(secondary.slice(5, 7), 16) + ', 0.15) 100%)'
    };
  }

  // ---------------------------------------------------------------------------
  // Team definitions – all 32 NHL teams
  // ---------------------------------------------------------------------------

  var TEAM_THEMES = {

    // ── Default (neutral dark, matches design-tokens.css) ──────────────────
    'default': {
      name: 'Default Theme',
      abbrev: 'NHL',
      conference: null,
      division: null,
      colors: {
        primary:   '#21d19f',
        secondary: '#2980b9',
        accent:    '#9b59b6',
        dark:      '#0b162a',
        light:     '#ffffff'
      },
      theme: {
        '--color-bg-primary':     '#0b162a',
        '--color-bg-secondary':   '#1a253a',
        '--color-bg-tertiary':    '#2a3a52',
        '--color-bg-hover':       '#212d47',
        '--color-accent-primary': '#21d19f',
        '--color-accent-info':    '#2980b9',
        '--color-border-default': '#2a3a52',
        '--color-border-subtle':  'rgba(255, 255, 255, 0.05)',
        '--gradient-green':       'linear-gradient(135deg, rgba(33, 209, 159, 0.15) 0%, rgba(41, 128, 185, 0.15) 100%)'
      }
    },

    // ── Atlantic Division ──────────────────────────────────────────────────

    'bruins': {
      name: 'Boston Bruins',
      abbrev: 'BOS',
      conference: 'Eastern',
      division: 'Atlantic',
      colors: {
        primary:   '#FFB81C',
        secondary: '#000000',
        accent:    '#FFFFFF',
        dark:      '#1a1200',
        light:     '#fff8e6'
      },
      theme: buildTheme('#FFB81C', '#000000')
    },

    'sabres': {
      name: 'Buffalo Sabres',
      abbrev: 'BUF',
      conference: 'Eastern',
      division: 'Atlantic',
      colors: {
        primary:   '#003087',
        secondary: '#FFB81C',
        accent:    '#FFFFFF',
        dark:      '#000a1c',
        light:     '#e6ecf5'
      },
      theme: buildTheme('#003087', '#FFB81C')
    },

    'red_wings': {
      name: 'Detroit Red Wings',
      abbrev: 'DET',
      conference: 'Eastern',
      division: 'Atlantic',
      colors: {
        primary:   '#CE1126',
        secondary: '#FFFFFF',
        accent:    '#000000',
        dark:      '#1a0306',
        light:     '#fce8eb'
      },
      theme: buildTheme('#CE1126', '#FFFFFF')
    },

    'panthers': {
      name: 'Florida Panthers',
      abbrev: 'FLA',
      conference: 'Eastern',
      division: 'Atlantic',
      colors: {
        primary:   '#041E42',
        secondary: '#C8102E',
        accent:    '#B9975B',
        dark:      '#010812',
        light:     '#e6eaf0'
      },
      theme: buildTheme('#041E42', '#C8102E')
    },

    'canadiens': {
      name: 'Montreal Canadiens',
      abbrev: 'MTL',
      conference: 'Eastern',
      division: 'Atlantic',
      colors: {
        primary:   '#AF1E2D',
        secondary: '#192168',
        accent:    '#FFFFFF',
        dark:      '#160409',
        light:     '#f7e8ea'
      },
      theme: buildTheme('#AF1E2D', '#192168')
    },

    'senators': {
      name: 'Ottawa Senators',
      abbrev: 'OTT',
      conference: 'Eastern',
      division: 'Atlantic',
      colors: {
        primary:   '#C52032',
        secondary: '#000000',
        accent:    '#C2912C',
        dark:      '#18050a',
        light:     '#fae8ea'
      },
      theme: buildTheme('#C52032', '#C2912C')
    },

    'lightning': {
      name: 'Tampa Bay Lightning',
      abbrev: 'TBL',
      conference: 'Eastern',
      division: 'Atlantic',
      colors: {
        primary:   '#002868',
        secondary: '#FFFFFF',
        accent:    '#000000',
        dark:      '#000816',
        light:     '#e6ecf4'
      },
      theme: buildTheme('#002868', '#FFFFFF')
    },

    'maple_leafs': {
      name: 'Toronto Maple Leafs',
      abbrev: 'TOR',
      conference: 'Eastern',
      division: 'Atlantic',
      colors: {
        primary:   '#00205B',
        secondary: '#FFFFFF',
        accent:    '#000000',
        dark:      '#000714',
        light:     '#e6eaf3'
      },
      theme: buildTheme('#00205B', '#FFFFFF')
    },

    // ── Metropolitan Division ──────────────────────────────────────────────

    'hurricanes': {
      name: 'Carolina Hurricanes',
      abbrev: 'CAR',
      conference: 'Eastern',
      division: 'Metropolitan',
      colors: {
        primary:   '#CC0000',
        secondary: '#000000',
        accent:    '#A2AAAD',
        dark:      '#1a0000',
        light:     '#fae6e6'
      },
      theme: buildTheme('#CC0000', '#A2AAAD')
    },

    'blue_jackets': {
      name: 'Columbus Blue Jackets',
      abbrev: 'CBJ',
      conference: 'Eastern',
      division: 'Metropolitan',
      colors: {
        primary:   '#002654',
        secondary: '#CE1126',
        accent:    '#FFFFFF',
        dark:      '#000912',
        light:     '#e6ebf2'
      },
      theme: buildTheme('#002654', '#CE1126')
    },

    'devils': {
      name: 'New Jersey Devils',
      abbrev: 'NJD',
      conference: 'Eastern',
      division: 'Metropolitan',
      colors: {
        primary:   '#CE1126',
        secondary: '#000000',
        accent:    '#FFFFFF',
        dark:      '#1a0306',
        light:     '#fce8eb'
      },
      theme: buildTheme('#CE1126', '#000000')
    },

    'islanders': {
      name: 'New York Islanders',
      abbrev: 'NYI',
      conference: 'Eastern',
      division: 'Metropolitan',
      colors: {
        primary:   '#00539B',
        secondary: '#F47D30',
        accent:    '#FFFFFF',
        dark:      '#001020',
        light:     '#e6eff7'
      },
      theme: buildTheme('#00539B', '#F47D30')
    },

    'rangers': {
      name: 'New York Rangers',
      abbrev: 'NYR',
      conference: 'Eastern',
      division: 'Metropolitan',
      colors: {
        primary:   '#0038A8',
        secondary: '#CE1126',
        accent:    '#FFFFFF',
        dark:      '#000b1e',
        light:     '#e6ecf8'
      },
      theme: buildTheme('#0038A8', '#CE1126')
    },

    'flyers': {
      name: 'Philadelphia Flyers',
      abbrev: 'PHI',
      conference: 'Eastern',
      division: 'Metropolitan',
      colors: {
        primary:   '#F74902',
        secondary: '#000000',
        accent:    '#FFFFFF',
        dark:      '#1e0c00',
        light:     '#feede6'
      },
      theme: buildTheme('#F74902', '#000000')
    },

    'penguins': {
      name: 'Pittsburgh Penguins',
      abbrev: 'PIT',
      conference: 'Eastern',
      division: 'Metropolitan',
      colors: {
        primary:   '#FFB81C',
        secondary: '#000000',
        accent:    '#CFC493',
        dark:      '#1a1200',
        light:     '#fff8e6'
      },
      theme: buildTheme('#FFB81C', '#000000')
    },

    'capitals': {
      name: 'Washington Capitals',
      abbrev: 'WSH',
      conference: 'Eastern',
      division: 'Metropolitan',
      colors: {
        primary:   '#041E42',
        secondary: '#C8102E',
        accent:    '#FFFFFF',
        dark:      '#010812',
        light:     '#e6eaf0'
      },
      theme: buildTheme('#041E42', '#C8102E')
    },

    // ── Central Division ───────────────────────────────────────────────────

    'utah': {
      name: 'Utah Hockey Club',
      abbrev: 'UTA',
      conference: 'Western',
      division: 'Central',
      colors: {
        primary:   '#69B3E7',
        secondary: '#000000',
        accent:    '#E2D6B5',
        dark:      '#0d1a22',
        light:     '#eef6fc'
      },
      theme: buildTheme('#69B3E7', '#000000')
    },

    'blackhawks': {
      name: 'Chicago Blackhawks',
      abbrev: 'CHI',
      conference: 'Western',
      division: 'Central',
      colors: {
        primary:   '#CF0A2C',
        secondary: '#000000',
        accent:    '#FF671B',
        dark:      '#1a0208',
        light:     '#fce7eb'
      },
      theme: buildTheme('#CF0A2C', '#000000')
    },

    'avalanche': {
      name: 'Colorado Avalanche',
      abbrev: 'COL',
      conference: 'Western',
      division: 'Central',
      colors: {
        primary:   '#6F263D',
        secondary: '#236192',
        accent:    '#A2AAAD',
        dark:      '#1a0a12',
        light:     '#f5eef1'
      },
      theme: buildTheme('#6F263D', '#236192')
    },

    'stars': {
      name: 'Dallas Stars',
      abbrev: 'DAL',
      conference: 'Western',
      division: 'Central',
      colors: {
        primary:   '#006847',
        secondary: '#000000',
        accent:    '#8F8F8C',
        dark:      '#001410',
        light:     '#e6f2ee'
      },
      theme: buildTheme('#006847', '#8F8F8C')
    },

    'wild': {
      name: 'Minnesota Wild',
      abbrev: 'MIN',
      conference: 'Western',
      division: 'Central',
      colors: {
        primary:   '#154734',
        secondary: '#A6192E',
        accent:    '#DDCBA4',
        dark:      '#040e0a',
        light:     '#e8eeeb'
      },
      theme: buildTheme('#154734', '#A6192E')
    },

    'predators': {
      name: 'Nashville Predators',
      abbrev: 'NSH',
      conference: 'Western',
      division: 'Central',
      colors: {
        primary:   '#FFB81C',
        secondary: '#041E42',
        accent:    '#FFFFFF',
        dark:      '#1a1200',
        light:     '#fff8e6'
      },
      theme: buildTheme('#FFB81C', '#041E42')
    },

    'blues': {
      name: 'St. Louis Blues',
      abbrev: 'STL',
      conference: 'Western',
      division: 'Central',
      colors: {
        primary:   '#002F87',
        secondary: '#FCB514',
        accent:    '#FFFFFF',
        dark:      '#000a1c',
        light:     '#e6ebf5'
      },
      theme: buildTheme('#002F87', '#FCB514')
    },

    'jets': {
      name: 'Winnipeg Jets',
      abbrev: 'WPG',
      conference: 'Western',
      division: 'Central',
      colors: {
        primary:   '#041E42',
        secondary: '#004C97',
        accent:    '#AC162C',
        dark:      '#010812',
        light:     '#e6eaf0'
      },
      theme: buildTheme('#041E42', '#004C97')
    },

    // ── Pacific Division ───────────────────────────────────────────────────

    'ducks': {
      name: 'Anaheim Ducks',
      abbrev: 'ANA',
      conference: 'Western',
      division: 'Pacific',
      colors: {
        primary:   '#F47A38',
        secondary: '#B5985A',
        accent:    '#000000',
        dark:      '#1e0f06',
        light:     '#fef2ea'
      },
      theme: buildTheme('#F47A38', '#B5985A')
    },

    'flames': {
      name: 'Calgary Flames',
      abbrev: 'CGY',
      conference: 'Western',
      division: 'Pacific',
      colors: {
        primary:   '#D2001C',
        secondary: '#FAAF19',
        accent:    '#000000',
        dark:      '#1a0004',
        light:     '#fce6e9'
      },
      theme: buildTheme('#D2001C', '#FAAF19')
    },

    'oilers': {
      name: 'Edmonton Oilers',
      abbrev: 'EDM',
      conference: 'Western',
      division: 'Pacific',
      colors: {
        primary:   '#041E42',
        secondary: '#FF4C00',
        accent:    '#FFFFFF',
        dark:      '#010812',
        light:     '#e6eaf0'
      },
      theme: buildTheme('#041E42', '#FF4C00')
    },

    'kings': {
      name: 'Los Angeles Kings',
      abbrev: 'LAK',
      conference: 'Western',
      division: 'Pacific',
      colors: {
        primary:   '#A2AAAD',
        secondary: '#111111',
        accent:    '#FFFFFF',
        dark:      '#141617',
        light:     '#f4f5f5'
      },
      theme: buildTheme('#A2AAAD', '#111111')
    },

    'sharks': {
      name: 'San Jose Sharks',
      abbrev: 'SJS',
      conference: 'Western',
      division: 'Pacific',
      colors: {
        primary:   '#006D75',
        secondary: '#EA7200',
        accent:    '#000000',
        dark:      '#001416',
        light:     '#e6f2f3'
      },
      theme: buildTheme('#006D75', '#EA7200')
    },

    'kraken': {
      name: 'Seattle Kraken',
      abbrev: 'SEA',
      conference: 'Western',
      division: 'Pacific',
      colors: {
        primary:   '#001628',
        secondary: '#99D9D9',
        accent:    '#355464',
        dark:      '#000810',
        light:     '#e6e9ec'
      },
      theme: buildTheme('#001628', '#99D9D9')
    },

    'canucks': {
      name: 'Vancouver Canucks',
      abbrev: 'VAN',
      conference: 'Western',
      division: 'Pacific',
      colors: {
        primary:   '#00205B',
        secondary: '#00843D',
        accent:    '#FFFFFF',
        dark:      '#000714',
        light:     '#e6eaf3'
      },
      theme: buildTheme('#00205B', '#00843D')
    },

    'golden_knights': {
      name: 'Vegas Golden Knights',
      abbrev: 'VGK',
      conference: 'Western',
      division: 'Pacific',
      colors: {
        primary:   '#B4975A',
        secondary: '#333F48',
        accent:    '#C8102E',
        dark:      '#171208',
        light:     '#f7f4ee'
      },
      theme: buildTheme('#B4975A', '#333F48')
    }
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /**
   * Return the theme object for a given team key (e.g. 'avalanche').
   * Falls back to 'default' when the key is unknown.
   */
  function getTeamTheme(teamKey) {
    return TEAM_THEMES[teamKey] || TEAM_THEMES['default'];
  }

  /**
   * Return every team grouped by division.
   * The 'default' pseudo-team is excluded.
   */
  function getAllTeams() {
    var grouped = {};
    var keys = Object.keys(TEAM_THEMES);
    for (var i = 0; i < keys.length; i++) {
      var key = keys[i];
      if (key === 'default') continue;
      var team = TEAM_THEMES[key];
      var div = team.division;
      if (!grouped[div]) grouped[div] = [];
      grouped[div].push({ key: key, name: team.name, abbrev: team.abbrev, colors: team.colors });
    }
    return grouped;
  }

  /**
   * Apply a team's theme by setting CSS custom properties on <html>.
   * Pass 'default' (or any falsy value) to reset to the neutral palette.
   */
  function applyTheme(teamKey) {
    var team = getTeamTheme(teamKey || 'default');
    var root = document.documentElement;
    var vars = team.theme;
    var keys = Object.keys(vars);

    if (teamKey && teamKey !== 'default') {
      // Apply team theme — set CSS custom properties inline
      for (var i = 0; i < keys.length; i++) {
        root.style.setProperty(keys[i], vars[keys[i]]);
      }
      try { localStorage.setItem('nhl_fan_team_css', JSON.stringify(vars)); } catch(e) {}
    } else {
      // Reset to default — remove all inline overrides so design-tokens.css takes over
      for (var i = 0; i < keys.length; i++) {
        root.style.removeProperty(keys[i]);
      }
      try { localStorage.removeItem('nhl_fan_team_css'); } catch(e) {}
    }

    root.dataset.team = teamKey || '';

    // Update browser chrome color
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) {
      meta.setAttribute('content',
        (teamKey && teamKey !== 'default' ? vars['--color-bg-primary'] : null) || '#0b162a');
    }
  }

  /** Read the stored team key from localStorage (may be null). */
  function getStoredTeam() {
    try { return localStorage.getItem('nhl_fan_team'); } catch (e) { return null; }
  }

  /** Persist the chosen team key in localStorage. */
  function setStoredTeam(teamKey) {
    try {
      if (teamKey && teamKey !== 'default') {
        localStorage.setItem('nhl_fan_team', teamKey);
      } else {
        localStorage.removeItem('nhl_fan_team');
        localStorage.removeItem('nhl_fan_team_css');
      }
    } catch (e) { /* noop */ }
  }

  // ---------------------------------------------------------------------------
  // Expose globally
  // ---------------------------------------------------------------------------

  window.TeamThemes = {
    themes:        TEAM_THEMES,
    getTeamTheme:  getTeamTheme,
    getAllTeams:    getAllTeams,
    applyTheme:    applyTheme,
    getStoredTeam: getStoredTeam,
    setStoredTeam: setStoredTeam
  };
})();
