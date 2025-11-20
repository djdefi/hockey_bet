# filepath: /home/runner/work/hockey_bet/hockey_bet/lib/team_colors.rb

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
