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

# Map Managers to Teams using team name matching
def map_managers_to_teams(csv_file, teams)
  manager_team_map = {}
  team_abbrevs = teams.map { |team| team['teamAbbrev']['default'] }
  CSV.foreach(csv_file, headers: true) do |row|
    manager = row['fan']
    fuzzy_team_name = row['team'].strip.downcase

    matched_team = teams.find do |team|
      team_name = team['teamName']['default'].downcase
      team_abbrev = team['teamAbbrev']['default'].downcase
      (team_name.include?(fuzzy_team_name) || fuzzy_team_name.include?(team_name)) || (team_abbrev == fuzzy_team_name)
    end

    if matched_team
      abbreviation = matched_team['teamAbbrev']['default']
      manager_team_map[abbreviation] = manager
    else
      manager_team_map[manager] = "N/A"
    end
  end

  team_abbrevs.each do |abbrev|
    manager_team_map[abbrev] ||= "N/A"
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

# Check if Next Opponent is a Fan Team
def check_fan_team_opponent(next_games, manager_team_map)
  fan_team_ids = manager_team_map.keys.map(&:downcase).to_set

  next_games.each do |team_id, game|
    if game
      opponent_id = game['awayTeam']['abbrev'].downcase == team_id.downcase ? game['homeTeam']['abbrev'].downcase : game['awayTeam']['abbrev'].downcase
      game['isFanTeamOpponent'] = fan_team_ids.include?(opponent_id)
    else
      next_games[team_id] = { 'isFanTeamOpponent' => false }
    end
  end
end

# Time Conversion
def convert_utc_to_pacific(utc_time_str)
  utc_time = Time.parse(utc_time_str.to_s)
  tz = TZInfo::Timezone.get('America/Los_Angeles')
  pacific_time = tz.utc_to_local(utc_time)
  pacific_time
end

# Render ERB Template
def render_template(manager_team_map, teams, next_games, last_updated)
  template = File.read("standings.html.erb")
  
  teams.each do |team|
    team['teamName']['default'] ||= 'N/A'
    manager_team_map[team['teamAbbrev']['default']] ||= 'N/A'
    next_games[team['teamAbbrev']['default']] ||= { 'startTimeUTC' => 'TBD', 'awayTeam' => { 'abbrev' => 'TBD' }, 'homeTeam' => { 'placeName' => { 'default' => 'TBD' } }, 'isFanTeamOpponent' => false }
  end
  
  ERB.new(template).result(binding)
end

# Main Execution
teams = fetch_team_info
schedule = fetch_schedule_info
next_games = find_next_games(teams, schedule)
manager_team_map = map_managers_to_teams("fan_team.csv", teams)

# Check if next opponent is a fan team
check_fan_team_opponent(next_games, manager_team_map)

# Fetch the current time and store it in a variable
last_updated = convert_utc_to_pacific(Time.now.utc.strftime("%Y-%m-%d %H:%M:%S"))

# Ensure the output directory exists
Dir.mkdir('_site') unless Dir.exist?('_site')
html_content = render_template(manager_team_map, teams, next_games, last_updated)

# Output to file
File.write("_site/index.html", html_content)
