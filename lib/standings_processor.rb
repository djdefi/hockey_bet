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
# Enhanced with specific seed and position information
PLAYOFF_STATUS = {
  div_leader_1: { class: 'color-bg-success-emphasis', icon: '🥇', label_prefix: 'Division Leader', aria_label: 'First place in division, secured playoff berth' },
  div_leader_2: { class: 'color-bg-success-emphasis', icon: '🥈', label_prefix: 'Division 2nd', aria_label: 'Second place in division, secured playoff berth' },
  div_leader_3: { class: 'color-bg-success-emphasis', icon: '🥉', label_prefix: 'Division 3rd', aria_label: 'Third place in division, secured playoff berth' },
  wildcard_1: { class: 'color-bg-success-emphasis', icon: '🎟️', label_prefix: 'Wildcard #1', aria_label: 'First wildcard position, secured playoff berth' },
  wildcard_2: { class: 'color-bg-success-emphasis', icon: '🎟️', label_prefix: 'Wildcard #2', aria_label: 'Second wildcard position, secured playoff berth' },
  in_hunt: { class: 'color-bg-attention-emphasis', icon: '⚠️', label_prefix: 'In The Hunt', aria_label: 'Team is in contention for wildcard position' },
  fading_fast: { class: 'color-bg-attention-emphasis', icon: '🫠', label_prefix: 'Fading Fast', aria_label: 'Team is fading from playoff contention' },
  eliminated: { class: 'color-bg-danger-emphasis', icon: '❌', label_prefix: 'Eliminated', aria_label: 'Team is mathematically eliminated from playoffs' }
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
    
    # Backfill season information for existing entries
    history_tracker.backfill_seasons
    
    # Record current standings
    history_tracker.record_current_standings(@manager_team_map, @teams)
    
    # Export available seasons to JSON
    seasons_data = {
      'seasons' => history_tracker.get_available_seasons,
      'current_season' => history_tracker.current_season
    }
    seasons_data_path = "#{DATA_DIR}/available_seasons.json"
    File.write(seasons_data_path, JSON.pretty_generate(seasons_data))
    
    # Export fan team colors to JSON - store in data/ directory for persistence
    colors_data_path = "#{DATA_DIR}/fan_team_colors.json"
    File.write(colors_data_path, JSON.pretty_generate(FAN_TEAM_COLORS))
    
    # Copy persistent data files to output directory for deployment
    FileUtils.cp(history_data_path, "#{output_dir}/standings_history.json")
    FileUtils.cp(colors_data_path, "#{output_dir}/fan_team_colors.json")
    FileUtils.cp(seasons_data_path, "#{output_dir}/available_seasons.json")
    
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
    
    # Copy mobile-gestures.js from lib to output directory
    gestures_src = File.join(File.dirname(__FILE__), 'mobile-gestures.js')
    gestures_dest = "#{output_dir}/mobile-gestures.js"
    FileUtils.cp(gestures_src, gestures_dest) if File.exist?(gestures_src)
    
    # Copy performance-utils.js from lib to output directory
    perf_src = File.join(File.dirname(__FILE__), 'performance-utils.js')
    perf_dest = "#{output_dir}/performance-utils.js"
    FileUtils.cp(perf_src, perf_dest) if File.exist?(perf_src)
    
    # Copy service worker for PWA and caching
    sw_src = 'service-worker.js'
    sw_dest = "#{output_dir}/service-worker.js"
    FileUtils.cp(sw_src, sw_dest) if File.exist?(sw_src)
  end

  # Determine playoff status for a team with enhanced specificity
  # Returns a symbol representing the team's playoff position
  def playoff_status_for(team)
    StandingsProcessor.calculate_playoff_status(team)
  end

  # Class method to calculate playoff status (shared between instance and global methods)
  # Returns a symbol representing the team's playoff position
  def self.calculate_playoff_status(team)
    div_seq = team['divisionSequence'].to_i
    wc_seq = team['wildcardSequence'].to_i
    
    # Division leaders (top 3 in each division)
    if div_seq == 1
      :div_leader_1
    elsif div_seq == 2
      :div_leader_2
    elsif div_seq == 3
      :div_leader_3
    # Wildcard positions (4th and 5th playoff spots in conference)
    elsif wc_seq == 1
      :wildcard_1
    elsif wc_seq == 2
      :wildcard_2
    # In the hunt (positions 3-5 behind wildcard cutoff, still realistically viable)
    elsif wc_seq > 2 && wc_seq <= 5
      :in_hunt
    # Fading fast (6-8 spots out, highly unlikely but not mathematically eliminated)
    elsif wc_seq > 5 && wc_seq <= 8
      :fading_fast
    # Mathematically eliminated (9+ spots behind wildcard cutoff)
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
# This is needed because ERB templates can't access instance methods directly
def playoff_status_for(team)
  StandingsProcessor.calculate_playoff_status(team)
end

# Helper function to get the full label for a playoff status
# Includes position information like seed number or wildcard position
def get_playoff_status_label(team, status)
  status_info = PLAYOFF_STATUS[status]
  return 'Unknown Status' unless status_info
  
  div_seq = team['divisionSequence'].to_i
  conf_seq = team['conferenceSequence'].to_i
  wc_seq = team['wildcardSequence'].to_i
  
  case status
  when :div_leader_1, :div_leader_2, :div_leader_3
    # Show conference seed for division leaders
    "#{status_info[:label_prefix]} (#{conf_seq} seed)"
  when :wildcard_1, :wildcard_2
    # Show wildcard position
    "#{status_info[:label_prefix]} (#{conf_seq} seed)"
  when :in_hunt, :fading_fast
    # Show how many spots back from wildcard
    spots_back = wc_seq - 2
    "#{status_info[:label_prefix]} (#{spots_back} out)"
  else
    status_info[:label_prefix]
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

# Calculate win probability for a matchup with momentum adjustment
# @param home_points [Float] Home team points in standings
# @param away_points [Float] Away team points in standings
# @param home_streak [String] Home team streak (e.g., "W3", "L2")
# @param away_streak [String] Away team streak
# @return [Hash] { winner: 'home'|'away'|nil, confidence: Integer, home_prob: Integer, away_prob: Integer }
def calculate_matchup_prediction(home_points, away_points, home_streak, away_streak)
  total_points = home_points.to_f + away_points.to_f
  return { winner: nil, confidence: 0, home_prob: 50, away_prob: 50 } if total_points == 0
  
  # Base probability from standings
  base_home_prob = (home_points.to_f / total_points * 100).round
  
  # Momentum adjustment from streaks (±2% per game, max ±10%)
  streak_adjustment = 0
  
  # Helper to extract streak count safely
  extract_streak_count = lambda do |streak|
    streak.to_s.match(/(\d+)/)&.captures&.first&.to_i || 0
  end
  
  # Home team streak adjustment
  if home_streak.to_s.start_with?('W')
    streak_adjustment += [extract_streak_count.call(home_streak) * 2, 10].min
  elsif home_streak.to_s.start_with?('L')
    streak_adjustment -= [extract_streak_count.call(home_streak) * 2, 10].min
  end
  
  # Away team streak adjustment (inverse effect)
  if away_streak.to_s.start_with?('W')
    streak_adjustment -= [extract_streak_count.call(away_streak) * 2, 10].min
  elsif away_streak.to_s.start_with?('L')
    streak_adjustment += [extract_streak_count.call(away_streak) * 2, 10].min
  end
  
  # Apply adjustment and clamp between 10-90%
  home_prob = [[base_home_prob + streak_adjustment, 10].max, 90].min
  away_prob = 100 - home_prob
  
  # Determine winner if confidence > 60%
  winner = nil
  confidence = 0
  if home_prob > 60
    winner = 'home'
    confidence = home_prob
  elsif away_prob > 60
    winner = 'away'
    confidence = away_prob
  end
  
  { winner: winner, confidence: confidence, home_prob: home_prob, away_prob: away_prob }
end

# Helper methods for enhanced matchup display
def get_date_group_label(game_time_str)
  return 'Upcoming' if game_time_str.nil? || game_time_str == 'None' || game_time_str == 'TBD'
  
  game_time = convert_utc_to_pacific(game_time_str)
  return 'Upcoming' if game_time.is_a?(String) # 'None' or 'TBD'
  
  now = Time.now
  game_date = game_time.to_date
  today = now.to_date
  
  days_diff = (game_date - today).to_i
  
  case days_diff
  when 0
    'Today'
  when 1
    'Tomorrow'
  when 2..6
    'This Week'
  else
    'Later'
  end
end

def get_interest_flames(interest_score)
  # Return 1-3 flames based on interest score
  return '🔥🔥🔥' if interest_score >= 95  # Very close matchup (0-5 point diff)
  return '🔥🔥' if interest_score >= 85     # Close matchup (5-15 point diff)
  return '🔥' if interest_score >= 70       # Moderate matchup (15-30 point diff)
  ''  # Large point differential
end

def format_streak(streak_code)
  return '' if streak_code.nil? || streak_code.empty?
  # Streak codes are formatted as: type (W/L/O) + count (e.g., 'W5' = 5-game winning streak)
  return '' if streak_code.length < 2  # Need at least type and count
  
  type = streak_code[0]
  count = streak_code[1..-1]
  
  case type
  when 'W'
    "#{count}W streak 🔥"
  when 'L'
    "#{count}L streak 📉"
  when 'O'
    "#{count}OT streak"
  else
    streak_code
  end
end

def get_rivalry_badge(same_division, same_conference)
  return '🔴 DIVISION RIVAL' if same_division
  return '🟡 CONFERENCE RIVAL' if same_conference
  ''
end
