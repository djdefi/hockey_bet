# filepath: /workspaces/hockey_bet/lib/standings_processor.rb
require 'httparty'
require 'json'
require 'csv'
require 'erb'
require 'tzinfo'
require 'time'
require_relative 'api_validator'
require_relative 'team_mapping'
require_relative 'playoff_processor'

# Playoff Status Helper Structure
PLAYOFF_STATUS = {
  clinched: { class: 'color-bg-success-emphasis', icon: '✔️', label: 'Clinched', aria_label: 'Team has secured a playoff berth' },
  contending: { class: 'color-bg-attention-emphasis', icon: '⚠️', label: 'Contending', aria_label: 'Team is still eligible via wild card standings' },
  eliminated: { class: 'color-bg-danger-emphasis', icon: '❌', label: 'Eliminated', aria_label: 'Team cannot qualify for playoffs' }
}

class StandingsProcessor
  attr_reader :teams, :schedule, :next_games, :manager_team_map, :last_updated, :playoff_processor, :season_info

  def initialize(fallback_path = 'spec/fixtures')
    @validator = ApiValidator.new
    @fallback_path = fallback_path
    @playoff_processor = PlayoffProcessor.new(fallback_path)
    @teams = []
    @schedule = []
    @next_games = {}
    @manager_team_map = {}
    @last_updated = nil
    @season_info = {}
  end

  # Main process method
  def process(input_csv = 'fan_team.csv', output_path = '_site/index.html')
    fetch_data
    process_data(input_csv)
    render_output(output_path)
  end

  # Fetch data from APIs with validation
  def fetch_data
    # Fetch team information
    @teams = fetch_team_info

    # Fetch schedule information
    @schedule = fetch_schedule_info

    # Fetch playoff data
    @playoff_processor.fetch_playoff_data

    # Update last updated timestamp
    @last_updated = convert_utc_to_pacific(Time.now.utc.strftime("%Y-%m-%d %H:%M:%S"))
  end

  # Process the fetched data
  def process_data(input_csv)
    # Determine season information
    @season_info = determine_season_info(@schedule)

    # Find next games
    @next_games = find_next_games(@teams, @schedule)

    # Map managers to teams
    @manager_team_map = map_managers_to_teams(input_csv, @teams)

    # Check fan team opponents
    check_fan_team_opponent(@next_games, @manager_team_map)
  end

  # Render the output HTML
  def render_output(output_path)
    # Ensure the output directory exists
    output_dir = File.dirname(output_path)
    Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

    # Render the template and write to file
    html_content = render_template
    File.write(output_path, html_content)
  end

  # Determine season information and current status
  def determine_season_info(schedule)
    season_info = {
      season: 'Unknown',
      display_season: 'Unknown Season',
      status: 'Unknown',
      status_description: 'Season status unclear'
    }

    # Extract season from schedule data
    if schedule && !schedule.empty?
      first_game = schedule.flat_map { |day| day['games'] }.first
      if first_game && first_game['season']
        season_number = first_game['season'].to_s
        if season_number.length == 8
          # Format: 20242025 -> "2024-25"
          start_year = season_number[0..3]
          end_year = season_number[4..7][2..3]
          season_info[:season] = season_number
          season_info[:display_season] = "#{start_year}-#{end_year} NHL Season"
        end
      end
    end

    # Determine current season status based on date and playoff processor
    current_date = Date.today
    current_month = current_date.month

    # Check if playoffs are active
    playoff_active = @playoff_processor.is_near_playoff_time?

    if playoff_active && (current_month >= 4 && current_month <= 6)
      season_info[:status] = 'Playoffs'
      season_info[:status_description] = 'NHL Playoffs in progress'
    elsif current_month >= 10 || current_month <= 4
      season_info[:status] = 'Regular Season'
      season_info[:status_description] = 'NHL Regular Season in progress'
    elsif current_month >= 7 && current_month <= 9
      season_info[:status] = 'Offseason'
      season_info[:status_description] = 'NHL Offseason - showing previous season stats'
    else
      season_info[:status] = 'Transition'
      season_info[:status_description] = 'Season transition period'
    end

    # Add warning if we might be showing mixed season data
    if season_info[:status] == 'Offseason'
      season_info[:warning] = 'Displaying previous season standings. Next games may be from upcoming season.'
    elsif season_info[:status] == 'Transition'
      season_info[:warning] = 'Season in transition. Data may include information from multiple seasons.'
    end

    season_info
  end
  def playoff_status_for(team)
    if team['divisionSequence'].to_i <= 3
      :clinched
    elsif team['wildcardSequence'].to_i <= 2
      :contending
    else
      :eliminated
    end
  end

  # Fetch Team Information with validation and fallback
  def fetch_team_info
    url = "https://api-web.nhle.com/v1/standings/now"
    response = HTTParty.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      if @validator.validate_teams_response(data)
        return data["standings"]
      else
        fallback = @validator.handle_api_failure('teams', "#{@fallback_path}/teams.json")
        return fallback["standings"] || []
      end
    else
      fallback = @validator.handle_api_failure('teams', "#{@fallback_path}/teams.json")
      return fallback["standings"] || []
    end
  end

  # Fetch Schedule Information with validation and fallback
  def fetch_schedule_info
    url = "https://api-web.nhle.com/v1/schedule/now"
    response = HTTParty.get(url)

    if response.code == 200
      data = JSON.parse(response.body)
      if @validator.validate_schedule_response(data)
        return data["gameWeek"]
      else
        fallback = @validator.handle_api_failure('schedule', "#{@fallback_path}/schedule.json")
        return fallback["gameWeek"] || []
      end
    else
      fallback = @validator.handle_api_failure('schedule', "#{@fallback_path}/schedule.json")
      return fallback["gameWeek"] || []
    end
  end

  # Map Managers to Teams using team name mapping
  def map_managers_to_teams(csv_file, teams)
    manager_team_map = {}
    team_abbrevs = teams.map { |team| team['teamAbbrev']['default'] }

    # Initialize all teams to "N/A"
    team_abbrevs.each do |abbrev|
      manager_team_map[abbrev] = "N/A"
    end

    begin
      CSV.foreach(csv_file, headers: true) do |row|
        manager = row['fan']
        team_name = row['team'].strip

        # Use our new mapping helper to find the abbreviation
        abbrev = map_team_name_to_abbrev(team_name, teams)

        if abbrev && team_abbrevs.include?(abbrev)
          manager_team_map[abbrev] = manager
        end
      end
    rescue => e
      puts "Error reading CSV: #{e.message}"
    end

    manager_team_map
  end

  # Find Next Game for Each Team
  def find_next_games(teams, schedule)
    next_games = {}
    teams.each do |team|
      team_id = team['teamAbbrev']['default']
      next_game = schedule.flat_map { |day| day['games'] }.find { |game| game['awayTeam']['abbrev'] == team_id || game['homeTeam']['abbrev'] == team_id }
      if next_game
        next_games[team_id] = next_game
      else
        # Create a complete placeholder for teams without next games
        next_games[team_id] = {
          'startTimeUTC' => 'None',
          'awayTeam' => { 'abbrev' => 'None', 'placeName' => { 'default' => 'None' } },
          'homeTeam' => { 'abbrev' => 'None', 'placeName' => { 'default' => 'None' } },
          'isFanTeamOpponent' => false
        }
      end
    end
    next_games
  end

  # Check if Next Opponent is a Fan Team
  def check_fan_team_opponent(next_games, manager_team_map)
    # Get only team IDs where there's a fan (value is not "N/A")
    fan_team_ids = manager_team_map.select { |_, value| value != "N/A" }.keys.map(&:downcase).to_set

    next_games.each do |team_id, game|
      if game && game['awayTeam']['abbrev'] != 'None' && game['homeTeam']['abbrev'] != 'None'
        opponent_id = game['awayTeam']['abbrev'].downcase == team_id.downcase ? game['homeTeam']['abbrev'].downcase : game['awayTeam']['abbrev'].downcase
        # Only mark as fan team opponent if both teams have fans
        game['isFanTeamOpponent'] = fan_team_ids.include?(opponent_id) && fan_team_ids.include?(team_id.downcase)
      else
        # Make sure isFanTeamOpponent is set to false for placeholder games
        game['isFanTeamOpponent'] = false if game
      end
    end
  end

  # Time Conversion - Enhanced to handle DST automatically and None value
  def convert_utc_to_pacific(utc_time_str)
    return 'None' if utc_time_str == 'None'
    return 'TBD' if utc_time_str == 'TBD'
    utc_time = Time.parse(utc_time_str.to_s)
    tz = TZInfo::Timezone.get('America/Los_Angeles')
    pacific_time = tz.utc_to_local(utc_time)
    pacific_time
  end

  # Format next game time in a readable format
  def format_game_time(time)
    return 'None' if time == 'None'
    return 'TBD' if time == 'TBD'
    time.strftime('%-m/%-d %H:%M')
  end

  # Get the opponent name for a team
  def get_opponent_name(game, team_id)
    return 'None' unless game
    return 'None' if game['awayTeam']['abbrev'] == 'None' || game['homeTeam']['abbrev'] == 'None'
    is_away = game['awayTeam']['abbrev'] == team_id
    is_away ? game['homeTeam']['placeName']['default'] : game['awayTeam']['placeName']['default']
  end

  # Render ERB Template
  def render_template
    template = File.read("lib/standings.html.erb")

    # Process teams with defaults for nil values
    @teams.each do |team|
      team['teamName']['default'] ||= 'N/A'
      @manager_team_map[team['teamAbbrev']['default']] ||= 'N/A'
      @next_games[team['teamAbbrev']['default']] ||= { 'startTimeUTC' => 'TBD', 'awayTeam' => { 'abbrev' => 'TBD' }, 'homeTeam' => { 'placeName' => { 'default' => 'TBD' } }, 'isFanTeamOpponent' => false }
    end

    # Create a binding to access instance variables in ERB
    erb_binding = binding

    ERB.new(template).result(erb_binding)
  end
end

# Helper method to convert playoff_status_for from instance method to global method for template compatibility
def playoff_status_for(team)
  if team['divisionSequence'].to_i <= 3
    :clinched
  elsif team['wildcardSequence'].to_i <= 2
    :contending
  else
    :eliminated
  end
end

# Helper methods for formatters
def convert_utc_to_pacific(utc_time_str)
  return 'None' if utc_time_str == 'None'
  return 'TBD' if utc_time_str == 'TBD'
  utc_time = Time.parse(utc_time_str.to_s)
  tz = TZInfo::Timezone.get('America/Los_Angeles')
  pacific_time = tz.utc_to_local(utc_time)
  pacific_time
end

def format_game_time(time)
  return 'None' if time == 'None'
  return 'TBD' if time == 'TBD'
  time.strftime('%-m/%-d %H:%M')
end

def get_opponent_name(game, team_id)
  return 'None' unless game
  return 'None' if game['awayTeam']['abbrev'] == 'None' || game['homeTeam']['abbrev'] == 'None'
  is_away = game['awayTeam']['abbrev'] == team_id
  is_away ? game['homeTeam']['placeName']['default'] : game['awayTeam']['placeName']['default']
end
