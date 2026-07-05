
# Official NHL team colors for Chart.js visualization
TEAM_COLORS = {
  'Avalanche' => '#6F263D',      # Colorado Avalanche - Burgundy
  'Devils' => '#CE1126',          # New Jersey Devils - Red
  'Ducks' => '#F47A38',           # Anaheim Ducks - Orange
  'Jets' => '#041E42',            # Winnipeg Jets - Navy Blue
  'Knights' => '#B4975A',         # Vegas Golden Knights - Gold
  'Kings' => '#111111',           # Los Angeles Kings - Black
  'Wild' => '#154734',            # Minnesota Wild - Forest Green
  'Kraken' => '#001628',          # Seattle Kraken - Deep Sea Blue
  'Utah' => '#69B3E7',            # Utah Hockey Club - Ice Blue
  'Capitals' => '#041E42',        # Washington Capitals - Navy Blue
  'Sharks' => '#006D75',          # San Jose Sharks - Teal
  'Sabres' => '#003087',          # Buffalo Sabres - Royal Blue
  'Predators' => '#FFB81C'        # Nashville Predators - Gold
}.freeze

# Map fan names to team colors based on fan_team.csv
FAN_TEAM_COLORS = {
  'Brian D.' => TEAM_COLORS['Sharks'],
  'David K.' => TEAM_COLORS['Predators'],
  'Jeff C.' => TEAM_COLORS['Avalanche'],
  'Keith R.' => TEAM_COLORS['Ducks'],
  'Travis R.' => TEAM_COLORS['Devils'],
  'Zak S.' => TEAM_COLORS['Knights'],
  'Ryan B.' => TEAM_COLORS['Sabres'],
  'Ryan T.' => TEAM_COLORS['Wild'],
  'Sean R.' => TEAM_COLORS['Kings'],
  'Tyler F.' => TEAM_COLORS['Utah'],
  'Trevor R.' => TEAM_COLORS['Kraken'],
  'Mike M.' => TEAM_COLORS['Capitals'],
  'Dan R.' => TEAM_COLORS['Jets']
}.freeze

# Relative luminance (0..1) of a #RRGGBB hex color.
def color_luminance(hex)
  h = hex.delete('#')
  r = h[0, 2].to_i(16)
  g = h[2, 2].to_i(16)
  b = h[4, 2].to_i(16)
  (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
end

# Blend a hex color toward white by `amount` (0..1), preserving hue reasonably.
def lighten_color(hex, amount)
  h = hex.delete('#')
  r = h[0, 2].to_i(16)
  g = h[2, 2].to_i(16)
  b = h[4, 2].to_i(16)
  nr = (r + (255 - r) * amount).round
  ng = (g + (255 - g) * amount).round
  nb = (b + (255 - b) * amount).round
  format('#%<r>02X%<g>02X%<b>02X', r: nr, g: ng, b: nb)
end

# Accent color for a fan, safe to use on the dark UI. Falls back to the
# azure brand accent for unmapped fans and lifts very dark team colors
# (near-black / deep navy) so they remain visible as accent bars/dots.
def fan_accent(fan)
  hex = FAN_TEAM_COLORS[fan] || '#1f9dff'
  color_luminance(hex) < 0.15 ? lighten_color(hex, 0.5) : hex
end
