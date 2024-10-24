require 'httparty'
require 'json'
require 'csv'
require 'erb'
require 'tzinfo'
require 'time'

# Fetch Team Information
def fetch_team_info
  url = "https://api-web.nhle.com/v1/standings/now"
  response = HTTParty.get(url)
  response.code == 200 ? JSON.parse(response.body)["standings"] : []
end

# Fetch Schedule Information
def fetch_schedule_info
  url = "https://api-web.nhle.com/v1/schedule/now"
  response = HTTParty.get(url)
  response.code == 200 ? JSON.parse(response.body)["gameWeek"] : []
end

# Map Managers to Teams
def map_managers_to_teams(csv_file, teams)
  manager_team_map = {}
  CSV.foreach(csv_file, headers: true) do |row|
    manager = row['fan']
    fuzzy_team_name = row['team'].strip.downcase
    matched_team = teams.find { |team| team['teamName']['default'].downcase.include?(fuzzy_team_name) }
    manager_team_map[matched_team ? matched_team['teamName']['default'] : "Team Not Found"] = manager
  end
  manager_team_map
end

# Find Next Game for Each Team
def find_next_games(teams, schedule)
  next_games = {}
  teams.each do |team|
    team_id = team['teamAbbrev']['default']
    next_game = schedule.flat_map { |day| day['games'] }.find { |game| game['awayTeam']['abbrev'] == team_id || game['homeTeam']['abbrev'] == team_id }
    next_games[team_id] = next_game ? next_game : nil
  end
  next_games
end

# Time Conversion
def convert_utc_to_pacific(utc_time_str)
  utc_time = Time.parse(utc_time_str)
  tz = TZInfo::Timezone.get('America/Los_Angeles')
  pacific_time = tz.utc_to_local(utc_time)
  pacific_time
end

# Render ERB Template
def render_template(manager_team_map, teams, next_games, last_updated)
  template = File.read("standings.html.erb")
  
  # Validate presence of variables
  missing_values = []
  teams.each do |team|
    missing_values << "team['teamName']['default']" unless team['teamName'] && team['teamName']['default']
    missing_values << "manager_team_map[team['teamName']['default']]" unless manager_team_map[team['teamName']['default']]
    missing_values << "next_games[team['teamAbbrev']['default']]" unless next_games[team['teamAbbrev']['default']]
  end
  
  # Log missing values
  unless missing_values.empty?
    puts "Missing values: #{missing_values.join(', ')}"
  end
  
  # Insert placeholder/null values
  teams.each do |team|
    team['teamName']['default'] ||= 'N/A'
    manager_team_map[team['teamName']['default']] ||= 'N/A'
    next_games[team['teamAbbrev']['default']] ||= { 'startTimeUTC' => 'TBD', 'awayTeam' => { 'abbrev' => 'TBD' }, 'homeTeam' => { 'placeName' => { 'default' => 'TBD' } } }
  end
  
  ERB.new(template).result(binding)
end

# Main Execution
teams = fetch_team_info
schedule = fetch_schedule_info
next_games = find_next_games(teams, schedule)
manager_team_map = map_managers_to_teams("fan_team.csv", teams)

# Fetch the current time and store it in a variable
last_updated = convert_utc_to_pacific(Time.now.utc.strftime("%Y-%m-%d %H:%M:%S"))

# Debugging output
puts "Teams: #{teams.inspect}"
puts "Schedule: #{schedule.inspect}"
puts "Next Games: #{next_games.inspect}"
puts "Manager Team Map: #{manager_team_map.inspect}"
puts "Last Updated: #{last_updated}"

# Ensure the output directory exists
Dir.mkdir('_site') unless Dir.exist?('_site')
html_content = render_template(manager_team_map, teams, next_games, last_updated)

# Output to file
File.write("_site/index.html", html_content)
