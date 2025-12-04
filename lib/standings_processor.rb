# filepath: /workspaces/hockey_bet/lib/standings_processor.rb
require 'httparty'
require 'json'
require 'csv'
require 'erb'
require 'tzinfo'
require 'time'
require 'fileutils'
require_relative 'api_validator'
require_relative 'team_mapping'
require_relative 'playoff_processor'
require_relative 'bet_stats_calculator'
require_relative 'standings_history_tracker'
require_relative 'team_colors'

# Playoff Status Helper Structure
PLAYOFF_STATUS = {
  clinched: { class: 'color-bg-success-emphasis', icon: '✔️', label: 'Clinched', aria_label: 'Team has secured a playoff berth' },
  contending: { class: 'color-bg-attention-emphasis', icon: '⚠️', label: 'Contending', aria_label: 'Team is still eligible via wild card standings' },
  eliminated: { class: 'color-bg-danger-emphasis', icon: '❌', label: 'Eliminated', aria_label: 'Team cannot qualify for playoffs' }
}

# Directory for persistent data files that need to be committed
DATA_DIR = 'data'

# StandingsProcessor orchestrates the main data flow for generating NHL standings
# It fetches data from NHL APIs, processes fan team mappings, calculates statistics,
# and renders the final HTML output with current standings and bet statistics
class StandingsProcessor
  attr_reader :teams, :schedule, :next_games, :manager_team_map, :last_updated, :playoff_processor, :bet_stats

  # Initializes the processor with optional fallback data path for testing
  # @param fallback_path [String] Path to fallback data directory (default: 'spec/fixtures')
  def initialize(fallback_path = 'spec/fixtures')
    @validator = ApiValidator.new
    @fallback_path = fallback_path
    @playoff_processor = PlayoffProcessor.new(fallback_path)
    @teams = []
    @schedule = []
    @next_games = {}
    @manager_team_map = {}
    @last_updated = nil
    @bet_stats = nil
  end

  # Main process method - orchestrates the complete data pipeline
  # @param input_csv [String] Path to fan-to-team mapping CSV file
  # @param output_path [String] Path where HTML output should be written
  def process(input_csv = 'fan_team.csv', output_path = '_site/index.html')
    fetch_data
    process_data(input_csv)
    render_output(output_path)
  end

  # Fetch data from APIs with validation
  # Retrieves team standings, schedules, and playoff information from NHL APIs
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
    # Find next games
    @next_games = find_next_games(@teams, @schedule)

    # Map managers to teams
    @manager_team_map = map_managers_to_teams(input_csv, @teams)

    # Check fan team opponents
    check_fan_team_opponent(@next_games, @manager_team_map)

    # Calculate bet stats
    calculator = BetStatsCalculator.new(@teams, @manager_team_map, @next_games)
    calculator.calculate_all_stats
    @bet_stats = calculator.stats
  end

  # Render the output HTML
  def render_output(output_path)
    # Ensure the output directory exists
    output_dir = File.dirname(output_path)
    Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

    # Render the template and write to file
    html_content = render_template
    File.write(output_path, html_content)
    
    # Update standings history - store in data/ directory for persistence
    FileUtils.mkdir_p(DATA_DIR)
    history_data_path = "#{DATA_DIR}/standings_history.json"
    history_tracker = StandingsHistoryTracker.new(history_data_path)
    history_tracker.record_current_standings(@manager_team_map, @teams)
    
    # Export fan team colors to JSON - store in data/ directory for persistence
    colors_data_path = "#{DATA_DIR}/fan_team_colors.json"
    File.write(colors_data_path, JSON.pretty_generate(FAN_TEAM_COLORS))
    
    # Copy persistent data files to output directory for deployment
    FileUtils.cp(history_data_path, "#{output_dir}/standings_history.json")
    FileUtils.cp(colors_data_path, "#{output_dir}/fan_team_colors.json")
    
    # Copy vendored assets to output directory
    vendor_src_dir = File.join(File.dirname(__FILE__), '..', 'vendor')
    vendor_dest_dir = "#{output_dir}/vendor"
    FileUtils.mkdir_p(vendor_dest_dir)
    
    # Copy Chart.js and Primer CSS if they exist
    ['chart.umd.js', 'primer.css'].each do |file|
      src = File.join(vendor_src_dir, file)
      dest = File.join(vendor_dest_dir, file)
      FileUtils.cp(src, dest) if File.exist?(src)
    end
    
    # Copy styles.css from lib to output directory
    styles_src = File.join(File.dirname(__FILE__), 'styles.css')
    styles_dest = "#{output_dir}/styles.css"
    FileUtils.cp(styles_src, styles_dest) if File.exist?(styles_src)
  end

  # Determine playoff status for a team
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
  # Maps fantasy league managers to NHL teams based on CSV input
  # @param csv_file [String] Path to CSV file with 'fan' and 'team' columns
  # @param teams [Array<Hash>] NHL team data
  # @return [Hash] Mapping of team abbreviations to manager names
  def map_managers_to_teams(csv_file, teams)
    manager_team_map = {}
    team_abbrevs = teams.map { |team| team['teamAbbrev']['default'] }

    # Initialize all teams to "N/A"
    team_abbrevs.each do |abbrev|
      manager_team_map[abbrev] = "N/A"
    end

    begin
      unless File.exist?(csv_file)
        puts "Warning: CSV file '#{csv_file}' not found. All teams will be marked as N/A."
        return manager_team_map
      end

      CSV.foreach(csv_file, headers: true) do |row|
        unless row['fan'] && row['team']
          puts "Warning: Skipping CSV row with missing 'fan' or 'team' column"
          next
        end

        manager = row['fan']
        team_name = row['team'].strip

        # Use our new mapping helper to find the abbreviation
        abbrev = map_team_name_to_abbrev(team_name, teams)

        if abbrev && team_abbrevs.include?(abbrev)
          manager_team_map[abbrev] = manager
        else
          puts "Warning: Could not map team '#{team_name}' to a valid NHL team"
        end
      end
    rescue CSV::MalformedCSVError => e
      puts "Error: CSV file is malformed: #{e.message}"
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

def format_game_time_full(time)
  return 'TBD' if time == 'None' || time == 'TBD' || time.is_a?(String)
  time.strftime('%A, %B %-d at %-I:%M %p Pacific')
end

def get_opponent_name(game, team_id)
  return 'None' unless game
  return 'None' if game['awayTeam']['abbrev'] == 'None' || game['homeTeam']['abbrev'] == 'None'
  is_away = game['awayTeam']['abbrev'] == team_id
  is_away ? game['homeTeam']['placeName']['default'] : game['awayTeam']['placeName']['default']
end

def get_team_logo_url(team_abbrev)
  # NHL provides team logos via their CDN
  # Using the official NHL team logo URL pattern
  return '' if team_abbrev.nil? || team_abbrev == 'N/A'
  "https://assets.nhle.com/logos/nhl/svg/#{team_abbrev}_light.svg"
end

def get_fan_achievement(fan, bet_stats)
  # Priority order of achievements (most impressive first)
  checks = [
    { key: :best_cup_odds, emoji: '🏆', label: 'Cup Contender' },
    { key: :fan_crusher, emoji: '💪', label: 'Fan Crusher' },
    { key: :most_dominant, emoji: '👑', label: 'Most Dominant' },
    { key: :on_fire, emoji: '🔥', label: 'On Fire' },
    { key: :brick_wall, emoji: '🧱', label: 'Brick Wall' },
    { key: :top_winners, emoji: '🥇', label: 'Top Winner' },
    { key: :shutout_king, emoji: '🚫', label: 'Shutout King' },
    { key: :glass_cannon, emoji: '💥', label: 'Glass Cannon' },
    { key: :comeback_kid, emoji: '🎯', label: 'Comeback Kid' },
    { key: :overtimer, emoji: '⏱️', label: 'Overtimer' }
  ]
  
  checks.each do |check|
    stat = bet_stats[check[:key]]
    if stat && stat.any? && stat.first[:fan] == fan
      return { emoji: check[:emoji], label: check[:label], value: stat.first[:display] }
    end
  end
  nil
end
